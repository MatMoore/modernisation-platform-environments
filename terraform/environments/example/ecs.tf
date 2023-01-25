module "ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs/"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.ecs_application_name
  container_instance_type = local.application_data.accounts[local.environment].container_os_type
  ami_image_id            = local.application_data.accounts[local.environment].container_ami_image_id
  instance_type           = local.application_data.accounts[local.environment].container_instance_type
  user_data               = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {}))
  key_name                = local.application_data.accounts[local.environment].ecs_key_name
  task_definition         = templatefile("${path.module}/templates/task_definition.json.tftpl", {})
  ec2_desired_capacity    = local.application_data.accounts[local.environment].ec2_desired_capacity
  ec2_max_size            = local.application_data.accounts[local.environment].ec2_max_size
  ec2_min_size            = local.application_data.accounts[local.environment].ec2_min_size
  container_cpu           = local.application_data.accounts[local.environment].container_cpu
  container_memory        = local.application_data.accounts[local.environment].container_memory
  task_definition_volume  = local.application_data.accounts[local.environment].task_definition_volume
  network_mode            = local.application_data.accounts[local.environment].network_mode
  server_port             = local.application_data.accounts[local.environment].server_port
  app_count               = local.application_data.accounts[local.environment].app_count
  ec2_ingress_rules       = local.ec2_ingress_rules
  ec2_egress_rules        = local.ec2_egress_rules
  lb_tg_name              = aws_lb_target_group.ecs_target_group.name
  tags_common             = local.tags

  depends_on = [aws_lb_listener.ecs-example]
}

locals {
  ecs_application_name = "example-app"
  # Build EC2 ingress and egress rules
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description = "Cluster EC2 ingress rule"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [
      data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
    "cluster_ec2_lb_ingress_2" = {
      description = "Cluster EC2 ingress rule 2"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = [
      data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description = "Cluster EC2 loadbalancer egress rule"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = [
      "0.0.0.0/0"]
      security_groups = []
    }
  }
  # Build loadbalancer ingress and egress rules
  ecs_loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 80
      to_port         = 80
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = []
    },
    "cluster_ec2_bastion_ingress" = {
      description     = "Cluster EC2 bastion ingress rule"
      from_port       = 3389
      to_port         = 3389
      protocol        = "tcp"
      cidr_blocks     = []
      security_groups = []
    }
  }

  ecs_loadbalancer_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

# Load balancer build using the module
module "ecs_lb_access_logs_enabled" { #tfsec:ignore:aws-ec2-no-public-egress-sgr
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer?ref=v2.1.1"
  providers = {
    # Here we use the default provider for the S3 bucket module, buck replication is disabled but we still
    # Need to pass the provider to the S3 bucket module
    aws.bucket-replication = aws
  }
  vpc_all = "${local.vpc_name}-${local.environment}"
  #existing_bucket_name               = "my-bucket-name"
  force_destroy_bucket       = true # enables destruction of logging bucket
  application_name           = local.ecs_application_name
  public_subnets             = [data.aws_subnet.data_subnets_a.id, data.aws_subnet.data_subnets_b.id, data.aws_subnet.data_subnets_c.id]
  loadbalancer_ingress_rules = local.ecs_loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.ecs_loadbalancer_egress_rules
  tags                       = local.tags
  account_number             = local.environment_management.account_ids[terraform.workspace]
  region                     = "eu-west-2"
  enable_deletion_protection = false
  idle_timeout               = 60
}

//# Create the target group
resource "aws_lb_target_group" "ecs_target_group" {
  name                 = "${local.ecs_application_name}-tg-mlb-${local.environment}"
  port                 = local.application_data.accounts[local.environment].server_port
  protocol             = "HTTP"
  vpc_id               = data.aws_vpc.shared.id
  target_type          = "instance"
  deregistration_delay = 30

  stickiness {
    type = "lb_cookie"

  }
  #checkov:skip=CKV_AWS_261: "health_check defined below, but not picked up"
  health_check {
    healthy_threshold   = "5"
    interval            = "120"
    port                = 80
    protocol            = "HTTP"
    unhealthy_threshold = "2"
    matcher             = "200-499"
    timeout             = "5"
  }
}

resource "aws_lb_listener" "ecs-example" {
  load_balancer_arn = module.ecs_lb_access_logs_enabled.load_balancer.arn

  default_action {
    target_group_arn = aws_lb_target_group.ecs_target_group.arn
    type             = "forward"
  }
  port = local.application_data.accounts[local.environment].server_port

  depends_on = [aws_lb_target_group.ecs_target_group]
}

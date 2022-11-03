#------------------------------------------------------------------------------
# ECS
#------------------------------------------------------------------------------

module "mlra-ecs" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs"

  subnet_set_name         = local.subnet_set_name
  vpc_all                 = local.vpc_all
  app_name                = local.application_name
  container_instance_type = local.application_data.accounts[local.environment].container_instance_type
  environment             = local.environment
  ami_image_id            = local.application_data.accounts[local.environment].ami_image_id
  instance_type           = local.application_data.accounts[local.environment].instance_type
  user_data               = local.user_data
  key_name                = local.application_data.accounts[local.environment].key_name
  task_definition         = local.task_definition
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
  tags_common             = local.tags

  depends_on = [module.alb, aws_cloudwatch_log_group.ecs_log_group] # TODO module.alb dependancy may have to be re-factored further into development
}

locals {
  ec2_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 ingress rule"
      from_port       = 22
      to_port         = 22
      protocol        = "tcp"
      cidr_blocks     = [data.aws_vpc.shared.cidr_block]
      security_groups = []
    }
  }
  ec2_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }

  user_data = base64encode(templatefile("user_data.sh", {
    app_name = local.application_name
  }))

  task_definition = templatefile("task_definition.json", {
    app_name            = local.application_name
    ecr_url             = local.application_data.accounts[local.environment].ecr_url
    docker_image_tag    = local.application_data.accounts[local.environment].docker_image_tag
    region              = local.application_data.accounts[local.environment].region
    maat_api_end_point  = local.application_data.accounts[local.environment].maat_api_end_point
    maat_db_url         = local.application_data.accounts[local.environment].maat_db_url
    maat_db_password    = local.application_data.accounts[local.environment].maat_db_password
    maat_libra_wsdl_url = local.application_data.accounts[local.environment].maat_libra_wsdl_url
    sentry_env          = local.environment
  })
}

#TODO This needs to be added in the cloudwatch module in the future
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name = "${local.application_name}-ecs-log-group"
}
module "lb-access-logs-enabled" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-loadbalancer"
  providers = {
    aws.bucket-replication = aws.bucket-replication
  }

  vpc_all                    = var.vpc_all
  application_name           = var.application_name
  # public_subnets             = [data.aws_subnet.public_subnets_a.id, data.aws_subnet.public_subnets_b.id, data.aws_subnet.public_subnets_c.id]
  public_subnets             = var.public_subnets
  region                     = var.region
  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout
  force_destroy_bucket       = var.force_destroy_bucket
  tags                       = var.tags
  account_number             = var.account_number
  loadbalancer_ingress_rules = local.loadbalancer_ingress_rules
  loadbalancer_egress_rules  = local.loadbalancer_egress_rules
}

locals {
  loadbalancer_ingress_rules = {
    "cluster_ec2_lb_ingress" = {
      description     = "Cluster EC2 loadbalancer ingress rule"
      from_port       = 443
      to_port         = 443
      protocol        = "tcp"
      cidr_blocks     = var.ingress_cidr_block
      security_groups = []
    }
  }
  loadbalancer_egress_rules = {
    "cluster_ec2_lb_egress" = {
      description     = "Cluster EC2 loadbalancer egress rule"
      from_port       = 0
      to_port         = 0
      protocol        = "-1"
      cidr_blocks     = ["0.0.0.0/0"]
      security_groups = []
    }
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = module.lb-access-logs-enabled.load_balancer.arn
  port              = "443"
  protocol          = "HTTP"
  #TODO CHANGE_TO_HTTPS_AND_CERTIFICATE_ARN_TOBE_ADDED

  default_action {
    type = "forward"
    #TODO default action type fixed-response has not been added
    #as this depends on cloudfront which is is not currently configured
    #therefore this will need to be added pending cutover strategy decisions
    #
    # - Type: fixed-response
    #   FixedResponseConfig:
    #     ContentType: text/plain
    #     MessageBody: Access Denied - must access via CloudFront
    #     StatusCode: '403'
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

#TODO currently the EcsAlbHTTPSListenerRule has not been provisioned
#as this depends on cloudfront which is is not currently configured
#therefore this will need to be added pending cutover strategy decisions

resource "aws_lb_target_group" "alb_target_group" {
  # name                 = "${local.application_name}-target-group"
  name                 = "${var.application_name}-target-group"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30
  health_check {
    interval            = var.healthcheck_interval
    path                = local.application_data.accounts[local.environment].alb_target_group_path
    protocol            = "HTTP"
    timeout             = var.healthcheck_timeout
    healthy_threshold   = var.healthcheck_healthy_threshold
    unhealthy_threshold = var.healthcheck_unhealthy_threshold
  }
  stickiness {
    enabled         = var.stickiness_enabled
    type            = var.stickiness_type
    cookie_duration = var.stickiness_cookie_duration
  }
}
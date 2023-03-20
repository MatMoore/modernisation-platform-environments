# checkov:skip=CKV_AWS_226
# checkov:skip=CKV2_AWS_28

#tfsec:ignore:aws-elb-alb-not-public
resource "aws_lb" "delius_core_frontend" {
  # checkov:skip=CKV_AWS_91
  # checkov:skip=CKV2_AWS_28

  name               = "${local.application_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.delius_frontend_alb_security_group.id]
  subnets            = data.aws_subnets.shared-public.ids

  enable_deletion_protection = true
  drop_invalid_header_fields = true
}

# Create security group and rules for load balancer
resource "aws_security_group" "delius_frontend_alb_security_group" {
  name_prefix = format("%s-alb-security-group", local.frontend_fully_qualified_name)
  description = "controls access to and from delius front-end load balancer"
  vpc_id      = data.aws_vpc.shared.id
  tags        = local.tags
}

resource "aws_vpc_security_group_ingress_rule" "delius_core_frontend_alb_ingress_allowlist" {
  security_group_id = aws_security_group.delius_frontend_alb_security_group.id
  description       = "access into delius core frontend alb"
  from_port         = "443"
  to_port           = "443"
  ip_protocol       = "tcp"
  cidr_ipv4         = "81.134.202.29/32" # MoJ Digital VPN
}

resource "aws_vpc_security_group_egress_rule" "delius_core_frontend_alb_egress_frontend_service" {
  security_group_id            = aws_security_group.delius_frontend_alb_security_group.id
  description                  = "access from delius core frontend alb to ecs"
  from_port                    = local.frontend_container_port
  to_port                      = local.frontend_container_port
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.delius_core_frontend_security_group.id
  tags                         = local.tags
}

# resource "aws_lb_listener" "listener" {
#   load_balancer_arn = aws_lb.delius_core_frontend.id
#   port              = 443
#   protocol          = "HTTPS"
#   certificate_arn   = aws_acm_certificate.external.arn
#   ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"

#   default_action {
#     target_group_arn = aws_lb_target_group.target_group_fargate.id
#     type             = "forward"
#   }
# }

# resource "aws_lb_target_group" "target_group_fargate" {
#   # checkov:skip=CKV_AWS_261

#   name                 = "${local.application_name}-tg-${local.environment}-new"
#   port                 = local.application_data.accounts[local.environment].server_port
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "ip"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     path                = "/User/Login?ReturnUrl=%2f"
#     healthy_threshold   = "5"
#     interval            = "120"
#     protocol            = "HTTP"
#     unhealthy_threshold = "2"
#     matcher             = "200-499"
#     timeout             = "5"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-tg-${local.environment}-new"
#     }
#   )
# }

# resource "aws_lb_target_group" "target_group" {
#   # checkov:skip=CKV_AWS_261

#   name                 = "${local.application_name}-tg-${local.environment}"
#   port                 = local.application_data.accounts[local.environment].server_port
#   protocol             = "HTTP"
#   vpc_id               = data.aws_vpc.shared.id
#   target_type          = "instance"
#   deregistration_delay = 30

#   stickiness {
#     type = "lb_cookie"
#   }

#   health_check {
#     path                = "/User/Login?ReturnUrl=%2f"
#     healthy_threshold   = "5"
#     interval            = "120"
#     protocol            = "HTTP"
#     unhealthy_threshold = "2"
#     matcher             = "200-499"
#     timeout             = "5"
#   }

#   tags = merge(
#     local.tags,
#     {
#       Name = "${local.application_name}-tg-${local.environment}"
#     }
#   )
# }

# resource "aws_route53_record" "external" {
#   provider = aws.core-vpc

#   zone_id = data.aws_route53_zone.external.zone_id
#   name    = local.app_url
#   type    = "A"

#   alias {
#     name                   = aws_lb.external.dns_name
#     zone_id                = aws_lb.external.zone_id
#     evaluate_target_health = true
#   }
# }

# resource "aws_acm_certificate" "external" {
#   domain_name       = "modernisation-platform.service.justice.gov.uk"
#   validation_method = "DNS"

#   subject_alternative_names = ["${var.networking[0].application}.${var.networking[0].business-unit}-${local.environment}.modernisation-platform.service.justice.gov.uk"]
#   tags = {
#     Environment = local.environment
#   }

#   lifecycle {
#     create_before_destroy = true
#   }
# }

# resource "aws_route53_record" "external_validation" {
#   provider = aws.core-network-services

#   allow_overwrite = true
#   name            = local.domain_name_main[0]
#   records         = local.domain_record_main
#   ttl             = 60
#   type            = local.domain_type_main[0]
#   zone_id         = data.aws_route53_zone.network-services.zone_id
# }

# resource "aws_route53_record" "external_validation_subdomain" {
#   provider = aws.core-vpc

#   allow_overwrite = true
#   name            = local.domain_name_sub[0]
#   records         = local.domain_record_sub
#   ttl             = 60
#   type            = local.domain_type_sub[0]
#   zone_id         = data.aws_route53_zone.external.zone_id
# }

# resource "aws_acm_certificate_validation" "external" {
#   certificate_arn         = aws_acm_certificate.external.arn
#   validation_record_fqdns = [local.domain_name_main[0], local.domain_name_sub[0]]
# }

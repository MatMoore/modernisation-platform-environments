module "ecs" {
  source = "github.com/ministryofjustice/modernisation-platform-terraform-ecs-cluster//cluster?ref=v1.0.0"

  environment = local.environment
  name        = format("%s-openldap", local.application_name)

  tags = local.tags
}

# Create s3 bucket for deployment state
module "s3_bucket_app_deployment" {

  source = "github.com/ministryofjustice/modernisation-platform-terraform-s3-bucket?ref=d2195ea6c28c44c83540978d71648c0a49497f38"

  providers = {
    aws.bucket-replication = aws
  }
  bucket_name        = "${local.application_name}-${local.environment}-openldap-deployment"
  versioning_enabled = true

  lifecycle_rule = [
    {
      id      = "main"
      enabled = "Enabled"
      prefix  = ""

      tags = {
        rule      = "log"
        autoclean = "true"
      }

      noncurrent_version_transition = [
        {
          days          = 90
          storage_class = "STANDARD_IA"
          }, {
          days          = 365
          storage_class = "GLACIER"
        }
      ]

      noncurrent_version_expiration = {
        days = 730
      }
    }
  ]

  tags = local.tags
}

resource "aws_security_group" "openldap" {
  vpc_id      = data.aws_vpc.shared.id
  name        = format("hmpps-%s-%s-openldap-service", local.environment, local.application_name)
  description = "Security group for the ${local.application_name} openldap service"
  tags        = local.tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group_rule" "allow_all_egress" {
  description       = "Allow all outbound traffic to any IPv4 address"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.openldap.id
}

# resource "aws_security_group_rule" "alb" {
#   description              = "Allow inbound traffic from ALB"
#   type                     = "ingress"
#   from_port                = local.openldap_port
#   to_port                  = local.openldap_port
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.load_balancer_security_group.id
#   security_group_id        = aws_security_group.openldap.id
# }

resource "aws_cloudwatch_log_group" "openldap" {
  name              = format("%s-openldap-ecs", local.application_name)
  retention_in_days = 30
}

output "s3_bucket_app_deployment_name" {
  value = module.s3_bucket_app_deployment.bucket.id
}

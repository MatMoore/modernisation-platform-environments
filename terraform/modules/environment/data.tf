#------------------------------------------------------------------------------
# Environment
#------------------------------------------------------------------------------

# Get environment specific configuration
data "http" "environments_file" {
  url = "https://raw.githubusercontent.com/ministryofjustice/modernisation-platform/main/environments/${var.application_name}.json"
}

#------------------------------------------------------------------------------
# Network
#------------------------------------------------------------------------------

data "aws_vpc" "this" {
  tags = {
    Name = local.vpc_name
  }
}

data "aws_subnets" "this" {
  for_each = toset(local.subnet_names[var.subnet_set])

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }
  tags = {
    Name = "${local.vpc_name}-${var.subnet_set}-${each.key}-${local.region}*"
  }
}

data "aws_route53_zone" "core_network_services" {
  for_each = { for key, value in local.route53_zones : key => value if value.account == "core-network-services" }

  provider = aws.core-network-services

  name         = "${each.key}."
  private_zone = each.value.private_zone
}

data "aws_route53_zone" "core_vpc" {
  for_each = { for key, value in local.route53_zones : key => value if value.account == "core-vpc" }

  provider = aws.core-vpc

  name         = "${each.key}."
  private_zone = each.value.private_zone
}

#------------------------------------------------------------------------------
# KMS
#------------------------------------------------------------------------------

data "aws_kms_key" "this" {
  for_each = toset(local.cmk_name_prefixes)
  key_id   = "arn:aws:kms:eu-west-2:${var.environment_management.account_ids["core-shared-services-production"]}:alias/${each.key}-${var.business_unit}"
}

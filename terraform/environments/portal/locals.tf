#### This file can be used to store locals specific to the member account ####
locals {
  oim_ami-id              = "ami-013d0d5e3de018001"
  first-cidr              = "10.202.0.0/20"
  second-cidr             = "10.200.0.0/20"
  third-cidr              = "10.200.16.0/20"
  prd-cidr                = "10.200.16.0/20"
  aws_region              = "eu-west-2"
  nonprod_workspaces_cidr = "10.200.0.0/20"
  prod_workspaces_cidr    = "10.200.16.0/20"
  redc_cidr               = "172.16.0.0/20"
  atos_cidr               = "10.0.0.0/8"
  portal_hosted_zone      = local.application_data.accounts[local.environment].hosted_zone

  # Temp local variable for environments where we wish to build out the EBS to be transfered to EFS
  ebs_conditional = ["testing", "preproduction", "production"]

  external_lb_validation_records = {
    for dvo in aws_acm_certificate.legalservices_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      zone = lookup(
        local.route53_zones,
        dvo.domain_name,
        lookup(
          local.route53_zones,
          replace(dvo.domain_name, "/^[^.]*./", ""),
          lookup(
            local.route53_zones,
            replace(dvo.domain_name, "/^[^.]*.[^.]*./", ""),
            { provider = "external" }
      )))
    }
  }


   route53_zones = merge({
    for key, value in data.aws_route53_zone.core_network_services : key => merge(value, {
      provider = "core-network-services"
    })
    }, {
    for key, value in data.aws_route53_zone.core_vpc : key => merge(value, {
      provider = "core-vpc"
    })
    }, {
    for key, value in data.aws_route53_zone.self : key => merge(value, {
      provider = "self"
    })
  })

   validation_records_external_lb = {
    for key, value in local.external_lb_validation_records : key => {
      name   = value.name
      record = value.record
      type   = value.type
    } if value.zone.provider == "external"
  }

    external_validation_records_created = false

}

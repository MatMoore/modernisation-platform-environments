data "aws_caller_identity" "current" {}

data "aws_vpc" "shared_vpc" {
  tags = {
    Name = "${var.business_unit}-${var.environment}"
  }
}

data "aws_subnet" "this" {
  tags = {
    Name = "${var.business_unit}-${var.environment}-${var.subnet_set}-${var.subnet_name}-${var.availability_zone}"
  }
}

data "aws_ami" "this" {
  most_recent = true
  owners      = [try(var.account_ids_lookup[var.ami_owner], var.ami_owner)]
  tags = {
    is-production = true # based on environment
  }

  filter {
    name   = "name"
    values = [var.ami_name]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

data "aws_kms_key" "by_alias" {
  key_id = "alias/aws/ebs"
}

data "aws_ec2_instance_type" "this" {
  instance_type = var.instance.instance_type
}

locals {
  user_data_part_count = [
    try(length(var.user_data_cloud_init.scripts), 0),
    try(length(var.user_data_cloud_init.write_files), 0)
  ]
}

data "cloudinit_config" "this" {
  count = sum(local.user_data_part_count) > 0 ? 1 : 0

  dynamic "part" {
    for_each = try(var.user_data_cloud_init.scripts, {})
    content {
      content_type = "text/x-shellscript"
      content      = templatefile("templates/${part.value}", local.user_data_args)
    }
  }
  dynamic "part" {
    for_each = try(var.user_data_cloud_init.write_files, {})
    content {
      content_type = "text/cloud-config"
      merge_type   = "list(append)+dict(recurse_list)+str(append)"
      content = yamlencode({
        write_files = [
          {
            encoding    = "b64"
            content     = base64encode(templatefile("templates/${part.key}", local.user_data_args))
            path        = part.value.path
            owner       = part.value.owner
            permissions = part.value.permissions
          }
        ]
      })
    }
  }
}

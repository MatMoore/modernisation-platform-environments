# Security Groups
resource "aws_security_group" "domain-controllers" {

  description = "Domain traffic only"
  name        = "domaincontrollers-${local.application_name}"
  vpc_id      = local.vpc_id

}

# Allow DCs to connect anywhere
resource "aws_security_group_rule" "dc-all-outbound-traffic" {
  depends_on        = [aws_security_group.domain-controllers]
  security_group_id = aws_security_group.domain-controllers.id
  type              = "egress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "dc-all-inbound-traffic" {
  depends_on        = [aws_security_group.domain-controllers]
  security_group_id = aws_security_group.domain-controllers.id
  type              = "ingress"
  description       = "allow all"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

# resource "aws_security_group_rule" "rdp-from-bastion" {
#   depends_on        = [aws_security_group.domain-controllers]
#   security_group_id = aws_security_group.domain-controllers.id
#   type              = "ingress"
#   description       = "SSH from Bastion"
#   from_port         = 3389
#   to_port           = 3389
#   protocol          = "TCP"
#   cidr_blocks       = ["${module.bastion_linux.bastion_private_ip}/32"]
# }

# resource "aws_security_group_rule" "dns-into-dc-tcp" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow DNS"
#   from_port                = 53
#   to_port                  = 53
#   protocol                 = "TCP"
#   source_security_group_id = aws_security_group.outbound-dns-resolver.id
# }

# resource "aws_security_group_rule" "dns-into-dc-udp" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow DNS"
#   from_port                = 53
#   to_port                  = 53
#   protocol                 = "UDP"
#   source_security_group_id = aws_security_group.outbound-dns-resolver.id
# }

# resource "aws_security_group_rule" "dc5" {
#   depends_on        = [aws_security_group.domain-controllers]
#   security_group_id = aws_security_group.domain-controllers.id
#   type              = "ingress"
#   description       = "allow DCs to listen to each other"
#   from_port         = 0
#   to_port           = 0
#   protocol          = -1
#   self              = true
# }


# resource "aws_security_group_rule" "dcs-from-app" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.app-server.id
# }


# resource "aws_security_group_rule" "dcs-from-cjim" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.cjim-server.id
# }


# resource "aws_security_group_rule" "dcs-from-cjip" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.cjip-server.id
# }


# resource "aws_security_group_rule" "dcs-from-portal" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.portal-server.id
# }

# resource "aws_security_group_rule" "dcs-from-exchange" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.exchange-server.id
# }

# resource "aws_security_group_rule" "dcs-from-db" {
#   depends_on               = [aws_security_group.domain-controllers]
#   security_group_id        = aws_security_group.domain-controllers.id
#   type                     = "ingress"
#   description              = "allow All"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = -1
#   source_security_group_id = aws_security_group.database-server.id
# }


resource "aws_security_group" "outbound-dns-resolver" {
  provider = aws.core-vpc

  description = "DNS traffic only"
  name        = "outbound-dns-resolver-${local.application_name}"
  vpc_id      = local.vpc_id
}

resource "aws_security_group_rule" "res1" {
  depends_on               = [aws_security_group.outbound-dns-resolver]
  security_group_id        = aws_security_group.outbound-dns-resolver.id
  provider                 = aws.core-vpc
  type                     = "egress"
  description              = "allow DNS"
  from_port                = 0
  to_port                  = 53
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.domain-controllers.id
}

resource "aws_security_group_rule" "res2" {
  depends_on               = [aws_security_group.outbound-dns-resolver]
  security_group_id        = aws_security_group.outbound-dns-resolver.id
  provider                 = aws.core-vpc
  type                     = "egress"
  description              = "allow DNS"
  from_port                = 0
  to_port                  = 53
  protocol                 = "UDP"
  source_security_group_id = aws_security_group.domain-controllers.id
}




resource "aws_instance" "infra1" {
  instance_type               = "t2.small"
  ami                         = local.application_data.accounts[local.environment].infra1-ami
  vpc_security_group_ids      = [aws_security_group.domain-controllers.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_a.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "infra1-${local.application_name}"
    }
  )
}

resource "aws_ebs_volume" "infra1-disk1" {
  availability_zone = "${local.region}a"
  type              = "gp2"
  encrypted         = true

  snapshot_id = local.application_data.accounts[local.environment].infra1-disk-1-snapshot

  tags = merge(
    local.tags,
    {
      Name = "infra1-disk1-${local.application_name}"
    }
  )
}

resource "aws_volume_attachment" "infra1-disk1" {
  device_name  = "/dev/xvdg"
  force_detach = true
  volume_id    = aws_ebs_volume.infra1-disk1.id
  instance_id  = aws_instance.infra1.id
}


resource "aws_instance" "infra2" {
  depends_on                  = [aws_security_group.domain-controllers, aws_security_group.outbound-dns-resolver]
  instance_type               = "t2.small"
  ami                         = local.application_data.accounts[local.environment].infra2-ami
  vpc_security_group_ids      = [aws_security_group.domain-controllers.id]
  monitoring                  = false
  associate_public_ip_address = false
  ebs_optimized               = false
  subnet_id                   = data.aws_subnet.private_az_b.id
  key_name                    = aws_key_pair.george.key_name


  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  root_block_device {
    encrypted = true
  }

  lifecycle {
    ignore_changes = [
      # This prevents clobbering the tags of attached EBS volumes. See
      # [this bug][1] in the AWS provider upstream.
      #
      # [1]: https://github.com/terraform-providers/terraform-provider-aws/issues/770
      volume_tags,
      #user_data,         # Prevent changes to user_data from destroying existing EC2s
      root_block_device,
      # Prevent changes to encryption from destroying existing EC2s - can delete once encryption complete
    ]
  }

  tags = merge(
    local.tags,
    {
      Name = "infra2-${local.application_name}"
    }
  )
}



resource "aws_route53_resolver_endpoint" "cjse-domain" {
  provider = aws.core-vpc

  name      = "cjse-sema-local"
  direction = "OUTBOUND"

  security_group_ids = [
    aws_security_group.outbound-dns-resolver.id
  ]

  ip_address {
    subnet_id = data.aws_subnet.private_az_a.id
  }

  ip_address {
    subnet_id = data.aws_subnet.private_az_b.id
  }

  tags = {
    Name = "cjse-sema-local-${local.application_name}-${local.environment}"
  }
}

resource "aws_route53_resolver_rule" "fwd" {
  provider = aws.core-vpc

  domain_name          = "cjse.sema.local"
  name                 = "cjse-sema-local"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.cjse-domain.id

  target_ip {
    ip = aws_instance.infra1.private_ip
  }

  target_ip {
    ip = aws_instance.infra2.private_ip
  }
}

resource "aws_route53_resolver_rule_association" "cjse-domain" {
  provider = aws.core-vpc

  resolver_rule_id = aws_route53_resolver_rule.fwd.id
  vpc_id           = local.vpc_id
}







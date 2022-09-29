locals {
  instance-userdata = <<EOF
#!/bin/bash
yum install -y httpd
systemctl start httpd
EOF
}
module "ec2_instance" {
  source                 = "terraform-aws-modules/ec2-instance/aws"
  version                = "~> 4.0"
  name                   = "mikereidhttptest"
  ami                    = "ami-06672d07f62285d1d"
  instance_type          = "t3a.small"
  vpc_security_group_ids = [module.mikereidhttptest_sg.security_group_id]
  subnet_id              = "subnet-06594eda5221bd3c9"
  user_data_base64       = base64encode(local.instance-userdata)
  tags = {
    Name        = "mikereidhttptest"
    Environment = "dev"
  }
}
module "mikereidhttptest_sg" {
  source      = "terraform-aws-modules/security-group/aws"
  version     = "~> 4.0"
  name        = "mikereidhttptest-sg"
  description = "Security group for TG connectivity testing between LAA LZ & MP"
  vpc_id      = "vpc-06febffe7b87ab37f"
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Outgoing"
      cidr_blocks = "0.0.0.0/0"
    }
  ]
  ingress_with_cidr_blocks = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP"
      cidr_blocks = "10.202.0.0/16"
    }
  ]
}
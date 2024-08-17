locals {
  ingress_rules = [

    {
      name        = "SSH-Port"
      port        = 22
      description = "port enabled for ssh logins"
    },

    {
      name        = "HTTP Port"
      port        = 80
      description = "port enabled for internet activity"

    },

    {
      name        = "HTTPS Port"
      port        = 443
      description = "Port enabled for secure internet activity"
    },

    {
      name        = "RDS - Port"
      port        = 3306
      description = "port enabled for rds activity"

    },

  ]
}

resource "aws_security_group" "app-vpc-ec2-sg" {
  name        = "App-Vpc-EC2-SG"
  vpc_id      = aws_vpc.app-vpc.id
  description = "Rules for Security Group"


  dynamic "ingress" {

    for_each = local.ingress_rules

    content {
      description = ingress.value.description
      to_port     = ingress.value.port
      from_port   = ingress.value.port
      cidr_blocks = ["${var.Global_CIDR}"]
      protocol    = "TCP"
    }
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["${var.Global_CIDR}"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "App-Vpc-EC2-SG"
  }

  lifecycle {
    create_before_destroy = true
  }
}
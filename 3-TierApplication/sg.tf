locals {
  ingress_rules = [
    {
      name        = "SSH-Port"
      port        = 22
      description = "Port for the secured Server access"
    },
    {
      name        = "HTTPS-Port"
      port        = 443
      description = "Port for the secured Traffic Moment"
    },
    {
      name        = "HTTP-Port"
      port        = 80
      description = "Port for unsecured traffic movement"
    },
    {
      name        = "RDS-Port"
      port        = 3306
      description = "RDS Port"
    },

  ]
}

resource "aws_security_group" "web-vpc-ec2-sg" {
  name        = "web-vpc-sg"
  vpc_id      = aws_vpc.app-vpc.id
  description = "Rules for the Security Group"


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
    "Name" = "web-vpc-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_security_group" "db-ec2-vpc-sg" {

  name        = "db-ec2-vpc-sg"
  vpc_id      = aws_vpc.app-vpc.id
  description = "Rules for the Security Group"


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
    "Name" = "db-ec2-vpc-sg"
  }

  lifecycle {
    create_before_destroy = true
  }
}
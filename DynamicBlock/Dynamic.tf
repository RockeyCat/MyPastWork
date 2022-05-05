variable "region" {
  type = string
  default = "ap-south-1"
}


provider "aws" {
  shared_config_files      = ["C:\\Users\\HP\\.aws\\config"]
  shared_credentials_files = ["C:\\Users\\HP\\.aws\\credentials"]
  region                   = var.region

}


resource "aws_default_vpc" "default" {
  
}

locals {
ingress_rules = [{
    name = "SSH"
    port = 22
    description = "SSH PORT"
},
{
    name = "HTTPS"
    port = 443
    description = "HTTPS PORT"
},
{
    name = "HTTP"
    port = 80
    description = "HTTP PORT"
}
]
}



resource "aws_security_group" "default-sg" {
  vpc_id = aws_default_vpc.default.id

dynamic "ingress"{
for_each = local.ingress_rules
iterator = port
content {

description = port.value.description
from_port = port.value.port
to_port = port.value.port
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
}

}

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    "Name" = "app-vp-ec2-sg"
  }


}
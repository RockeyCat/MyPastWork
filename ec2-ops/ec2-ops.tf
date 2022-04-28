variable "aws_access_key" {
  
}

variable "aws_secret_key" {
  
}

variable "region" {
  
}


variable "aws-vpc" {
  type = string
  default = "10.30.0.0/16"
}



variable "ec2-instance-type" {
  type = string
  default = "t2.small"
}
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}
resource "aws_vpc" "lb-vpc" {
  cidr_block = var.aws-vpc
  enable_dns_hostnames = true
  enable_dns_support = true
  instance_tenancy = "default"
  tags = {
    "Name" = "lb-vpc"
  }
}


data "aws_availability_zones" "azs" {
  
}

resource "aws_subnet" "Subnet-Public" {
  vpc_id = aws_vpc.lb-vpc.id
  count =var.aws-vpc == "10.30.0.0/16" ? 3 : 0
  cidr_block = element(cidrsubnets(var.aws-vpc,8,4,4), count.index)
  availability_zone = data.aws_availability_zones.azs.names[count.index]
  map_public_ip_on_launch = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  tags= {
      Name = "Public-Subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "lb-igw" {
  vpc_id = aws_vpc.lb-vpc.id
  tags = {
    "Name" = "lb-igw"
  }
}

resource "aws_route_table" "lb-rtable" {
  vpc_id = aws_vpc.lb-vpc.id
  

  tags = {
    "Name" = "lb-rt"
  }
}


resource "aws_route" "lb-r" {
  
route_table_id = aws_route_table.lb-rtable.id
destination_cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.lb-igw.id
}

resource "aws_route_table_association" "lb-rta" {
  
  count = length(aws_subnet.Subnet-Public) == 3?3 : 0
  route_table_id = aws_route_table.lb-rtable.id
  subnet_id = element(aws_subnet.Subnet-Public.*.id, count.index)
}



resource "aws_security_group" "ec2-sg-lb" {
  vpc_id = aws_vpc.lb-vpc.id
  name = "ec2-sg-lb"
  description = "sg"
  ingress {
        from_port = 22
        to_port = 22
        description = "ssh access"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }
     ingress {
        from_port = 443
        to_port = 443
        description = "https access"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

     ingress {
        from_port = 80
        to_port = 80
        description = "https access"
        cidr_blocks = ["0.0.0.0/0"]
        protocol = "tcp"
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}



data "aws_ami" "ec2-ami" {
    most_recent = true
    owners = ["amazon", "aws-marketplace"]
filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}


resource "aws_instance" "prod-ec2-instance" {
ami = data.aws_ami.ec2-ami.id
instance_type = var.ec2-instance-type
count = length(aws_subnet.Subnet-Public.*.id)
vpc_security_group_ids = [aws_security_group.ec2-sg-lb.id]
subnet_id = element(aws_subnet.Subnet-Public.*.id, count.index)
connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
  }

  tags = {
    Name = "prod-public-ec2-instance-${count.index+1}"
  }
}


resource "aws_lb_target_group" "lb-tg" {
    vpc_id = aws_vpc.lb-vpc.id
    name = "lb-tg"
    port = 80
    target_type = "instance"
    protocol = "HTTP"
  
}


resource "aws_alb_target_group_attachment" "lb-tg-a" {
  
count = length(aws_instance.prod-ec2-instance.*.id ) == 3 ? 3 : 0
target_group_arn = aws_lb_target_group.lb-tg.arn
target_id = element(aws_instance.prod-ec2-instance.*.id, count.index)

}

resource "aws_alb" "a-lb" {
  name = "a-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.ec2-sg-lb.id, ]
  subnets = aws_subnet.Subnet-Public.*.id
}
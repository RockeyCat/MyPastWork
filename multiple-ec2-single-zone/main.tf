variable "aws_access_key" {
  
}

variable "aws_secret_key" {
  
}

variable "region" {
  
}

variable "ssh_key_name" {
  
}

variable "private_key_path" {
  
}

variable "product" {
  
}

variable "environment" {
  
}

provider "aws" {
    region =   var.region
    access_key = var.aws_access_key
    secret_key = var.aws_secret_key

}




resource "aws_vpc" "prod-vpc" {
  
cidr_block = "10.0.0.0/16"
instance_tenancy = "default"
enable_dns_hostnames = "true"
enable_dns_support = "true"
enable_classiclink = "false"
enable_classiclink_dns_support = "false"
assign_generated_ipv6_cidr_block = "false"

tags = {
  "name" = "prod-vpc"
}
}


resource "aws_subnet" "prod-vpc-subnet-1" {
vpc_id = aws_vpc.prod-vpc.id
map_public_ip_on_launch = "true"
enable_resource_name_dns_a_record_on_launch = "true"

cidr_block = "10.0.0.0/24"

  tags = {
    "name" = "subnet-1"
  }
}


/*resource "aws_subnet" "prod-vpc-subnet-2" {
vpc_id = aws_vpc.prod-vpc.id
map_public_ip_on_launch = "true"
enable_resource_name_dns_a_record_on_launch = "true"
cidr_block = "10.0.1.0/24"

  tags = {
    "name" = "subnet-2"
  }
}

resource "aws_subnet" "prod-vpc-subnet-3" {
vpc_id = aws_vpc.prod-vpc.id
map_public_ip_on_launch = "true"
enable_resource_name_dns_a_record_on_launch = "true"
cidr_block = "10.0.2.0/24"

  tags = {
    "name" = "subnet-3"
  }
}*/



resource "aws_internet_gateway" "prod-vpc-igw" {
  
  vpc_id = aws_vpc.prod-vpc.id
}

resource "aws_route_table" "prod-vpc-rt" {
vpc_id = aws_vpc.prod-vpc.id

route {
cidr_block = "0.0.0.0/0"
gateway_id = "${aws_internet_gateway.prod-vpc-igw.id}"
}
}


resource "aws_route_table_association" "subnet-map" {
  subnet_id = aws_subnet.prod-vpc-subnet-1.id
  route_table_id = aws_route_table.prod-vpc-rt.id
}

resource "aws_security_group" "ec2-sg-common" {
  name = "ec2-sg-common"
  description = "sg for ec2"
  vpc_id = aws_vpc.prod-vpc.id
  
  ingress  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "ssh port"
    from_port = 22
    protocol = "tcp"
    to_port = 22
  } 
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "https port"
    from_port = 443
    protocol = "tcp"
    to_port = 443
  }
  ingress {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = "http port"
    from_port = 80
    protocol = "tcp"
    to_port = 80
  }

tags = {
  "Name" = "ec2-sg-common"
}
}


data "aws_ami" "default" {
  most_recent = true
  owners = [ "amazon","aws-marketplace"]

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



resource "aws_instance" "ec2" {
  ami           = data.aws_ami.default.id
  instance_type = "t2.micro"
  key_name = var.ssh_key_name
  count = 3
  vpc_security_group_ids = [aws_security_group.ec2-sg-common.id]
  subnet_id = aws_subnet.prod-vpc-subnet-1.id
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_path)
  }
  tags = {
    Name = "${var.environment}.${var.product}-${count.index+1}"
  }
}



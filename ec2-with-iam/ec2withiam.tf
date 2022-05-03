variable "region" {
  type = string
  default = "ap-south-1"
}

###################
#       Deafult VPC
###################



provider "aws" {
shared_config_files = [ "C:\\Users\\HP\\.aws\\config" ]
shared_credentials_files = [ "C:\\Users\\HP\\.aws\\credentials" ]
}


data "aws_availability_zones" "azs" {
  state = "available"
}

variable "ec2-vpc" {
  type = string
  default = "10.0.0.0/16"
}

variable "azs" {
  type = list
  default = ["ap-south-1a","ap-south-1b"]
}


variable "instance-type" {
}

resource "aws_iam_role" "ssm-role" {
  name = "ssm-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "aws_iam_policy" "default" {
  arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


resource "aws_iam_role_policy_attachment" "name" {
  role = aws_iam_role.ssm-role.name
  policy_arn = data.aws_iam_policy.default.arn

}

resource "aws_default_vpc" "default-vpc" {
  

  tags = {
    Name = "Default VPC"
  }
}

resource "aws_default_subnet" "default-subnet" {
  count = length(var.azs)
  availability_zone = element(var.azs, count.index)
}


resource "aws_default_security_group" "default-sg" {
  vpc_id = aws_default_vpc.default-vpc.id
}

data "aws_ami" "default" {
  most_recent = true
  owners = [ "amazon", "aws-marketplace"]

  filter {
    name = "name"
    values = [ "amzn2-ami-hvm*" ]
  }

   filter {
    name = "root-device-type"
    values = [ "ebs" ]
  }
   filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }
}

resource "aws_iam_instance_profile" "ssm-role" {
  name = "ssm-role"
  role = aws_iam_role.ssm-role.name
}

resource "aws_instance" "first-ec2" {
  ami = data.aws_ami.default.id
  count = length(var.azs)
  instance_type = var.instance-type
  subnet_id = element(aws_default_subnet.default-subnet.*.id , count.index)
  iam_instance_profile = aws_iam_instance_profile.ssm-role.name
  security_groups = [aws_default_security_group.default-sg.id,]


  tags = {
    "Name" = "first-ec2-${count.index}"
  }
}

# MAC/LINUX
# aws ec2 create-key-pair --key-name tf_key --query 'KeyMaterial' --output text > tf_key.pem
###
# WINDOWS
# aws ec2 create-key-pair --key-name tf_key --query 'KeyMaterial' --output text | out-file -encoding ascii -filepath tf_key.pem



#####################################
#       Region
#####################################


variable "region" {
  type    = string
  default = "ap-south-1ping "
}

#####################################
#       CustomVPC Variable
#####################################

variable "custom_vpc" {
  description = "CIDR Definition of the VPC for Fluent declaration in Code"
  type        = string
  default     = "10.31.0.0/16"
}

#####################################
#      Instance Tenancy
#####################################

variable "instance_tenancy" {
  description = "Instance tenancy used to define wheather it is default or dedicated (Hardaware(Placement Groups))"
  type        = string
  default     = "default"
}

#####################################
#       Instance Type
#####################################
variable "instance_type" {
  description = "Declaring Instance Type"
  type        = string
  default     = "t2.small"
}

#####################################
#       Provider
#####################################

provider "aws" {
  shared_config_files      = ["C:\\Users\\HP\\.aws\\config"]
  shared_credentials_files = ["C:\\Users\\HP\\.aws\\credentials"]
  region                   = var.region

}

######################################
#           AMI
######################################
data "aws_ami" "default" {
  most_recent = true
  owners      = ["amazon", "aws-marketplace"]

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

#######################################
#             Security Group 
#######################################


locals {
  ingress_rules = [{
    name        = "HTTPS"
    port        = 443
    description = "Ingress for HTTPS"
    },
    {
      name        = "HTTP"
      port        = 80
      description = "Ingress for HTTP"
    },
    {
      name        = "SSH"
      port        = 22
      description = "Ingress for SSH"
  }]
}

resource "aws_security_group" "app-vpc-ec2-sg" {
  name        = "app-vpc-ec2-sg"
  description = "Allow Inbound Traffic for Instance"
  vpc_id      = aws_vpc.app-vpc.id


  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.description
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = "tcp"
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

#######################################
#            AZ-Declaration
#######################################
data "aws_availability_zones" "default" {

}

#######################################
#               VPC
#######################################

resource "aws_vpc" "app-vpc" {

  cidr_block           = var.custom_vpc
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "app-vpc"
  }
}

#######################################
#             Subnet Defination
#######################################

resource "aws_subnet" "app-vpc-subnet" {
  count                                       = var.custom_vpc == "10.31.0.0/16" ? 3 : 0
  vpc_id                                      = aws_vpc.app-vpc.id
  cidr_block                                  = element(cidrsubnets(var.custom_vpc, 8, 4, 4), count.index)
  availability_zone                           = data.aws_availability_zones.default.names[count.index]
  map_public_ip_on_launch                     = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  tags = {
    Name = "aws-vpc-subnet-${count.index + 1}"
  }
}

#######################################
#             IGW-defination
#######################################

resource "aws_internet_gateway" "apc-vpc-igw" {
  vpc_id = aws_vpc.app-vpc.id
  tags = {
    "Name" = "app-vpc-igw"
  }
}

#######################################
#             Route Table
#######################################

resource "aws_route_table" "app-vpc-rt-table" {

  vpc_id = aws_vpc.app-vpc.id
  tags = {
    "Name" = "app-vpc-rt-table"
  }
}

#######################################
#             Route 
#######################################

resource "aws_route" "app-vpc-rt" {
  route_table_id         = aws_route_table.app-vpc-rt-table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.apc-vpc-igw.id
}

resource "aws_route_table_association" "app-vpc-rt-table-association" {

  count          = length(aws_subnet.app-vpc-subnet) == 3 ? 3 : 0
  subnet_id      = element(aws_subnet.app-vpc-subnet.*.id, count.index)
  route_table_id = aws_route_table.app-vpc-rt-table.id
}


#######################################
#             AWS EC2 Instance
#######################################

resource "aws_instance" "app-vpc-ec2-instance" {
  ami             = data.aws_ami.default.id
  count           = length(aws_subnet.app-vpc-subnet.*.id)
  instance_type   = var.instance_type
  subnet_id       = element(aws_subnet.app-vpc-subnet.*.id, count.index)
  security_groups = [aws_security_group.app-vpc-ec2-sg.id, ]
  key_name        = "appkey"
  tags = {
    "Name"       = "app-vpc-ec2-instance-${count.index + 1}"
    "Created By" = "RockeyCat"
  }

  timeouts {
    create = "10m"
  }
}

#######################################
#             Null Resource for Def 
#######################################

resource "null_resource" "null" {
  count = length(aws_subnet.app-vpc-subnet.*.id)
  provisioner "file" {
    source      = "./userdata.sh"
    destination = "/home/ec2-user/userdata.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/userdata.sh",
      "sh  /home/ec2-user/userdata.sh",
    ]
    on_failure = continue
  

  connection {
    type        = "ssh"
    user        = "ec2-user"
    port        = "22"
    host        = element(aws_eip.eip.*.public_ip, count.index)
    private_key = file("./mykey.pem")
  }
  }
}
#######################################
#             EIP 
#######################################

resource "aws_eip" "eip" {
  count            = length(aws_instance.app-vpc-ec2-instance.*.id)
  instance         = element(aws_instance.app-vpc-ec2-instance.*.id, count.index)
  public_ipv4_pool = "amazon"
  vpc              = true


  tags = {
    "Name" = "EIP-${count.index + 1}"
  }
}

#######################################
#             EIP association
#######################################
resource "aws_eip_association" "eip-a" {
  count         = length(aws_eip.eip)
  instance_id   = element(aws_instance.app-vpc-ec2-instance.*.id, count.index)
  allocation_id = element(aws_eip.eip.*.id, count.index)
}


#######################################
#         Target Group Creation
#######################################
resource "aws_lb_target_group" "tg" {
  name        = "TG"
  port        = 80
  target_type = "instance"
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app-vpc.id
}

#######################################
#         Target Group Attachment
#######################################
resource "aws_alb_target_group_attachment" "tg-a" {
  count            = length(aws_instance.app-vpc-ec2-instance.*.id) == 3 ? 3 : 0
  # Condition Variable Condition ? true_value : false_value
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = element(aws_instance.app-vpc-ec2-instance.*.id, count.index)
}


#######################################
#         Application Load Balancer
#######################################

resource "aws_lb" "alb" {
  name               = "ALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.app-vpc-ec2-sg.id, ]
  subnets            = aws_subnet.app-vpc-subnet.*.id
}

#######################################
#       Load Balancer Listner
#######################################
resource "aws_lb_listener" "front" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

#######################################
#      Listner Rule
#######################################

resource "aws_lb_listener_rule" "static" {
  listener_arn = aws_lb_listener.front.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }

  condition {
    path_pattern {
      values = ["/var/www/html/index.html"]
    }
  }
}

#################################
#           Output
#################################

output "private_ip" {
  value = zipmap(aws_instance.app-vpc-ec2-instance.*.tags.Name, aws_instance.app-vpc-ec2-instance.*.private_ip)
# mapping the keys with their values using zipmap function
}
output "public_ip" {
  value = zipmap(aws_instance.app-vpc-ec2-instance.*.tags.Name, aws_eip.eip.*.public_ip)
}
output "public_dns" {
  value = zipmap(aws_instance.app-vpc-ec2-instance.*.tags.Name, aws_eip.eip.*.public_dns)
}
output "private_dns" {
  value = zipmap(aws_instance.app-vpc-ec2-instance.*.tags.Name, aws_instance.app-vpc-ec2-instance.*.private_dns)
}
output "alb_id" {
  value = aws_lb.alb.dns_name
}









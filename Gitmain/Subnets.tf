variable "region" {
  type    = string
  default = "ap-south-1"
}

##############SINGLE CIDR DEFINATION##################
variable "eks-vpc" {
  type        = string
  default     = "10.0.0.0/16"
  description = "Mentioned CIDR for our VPC"

}

locals {
  cluster_name = "eks-cluster"
}

provider "aws" {
  region                   = var.region
  shared_config_files      = ["C:\\Users\\HP\\.aws\\config"]
  shared_credentials_files = ["C:\\Users\\HP\\.aws\\credentials"]
}

data "aws_availability_zones" "azs" {
  state = "available"
}

##########VPC DEFINATION##################

resource "aws_vpc" "eks-vpc" {
  cidr_block           = var.eks-vpc
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    "Name" = "EKS-VPC-Main"
  }
}

##########Public Subnet  DEFINATION##################

resource "aws_subnet" "public-subnet" {
  vpc_id                                      = aws_vpc.eks-vpc.id
  count                                       = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  cidr_block                                  = cidrsubnet(var.eks-vpc, 8, count.index)
  map_public_ip_on_launch                     = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  availability_zone                           = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "Public-Subnet-${count.index + 1}"

  }

}
##########Private Subnet  DEFINATION##################

resource "aws_subnet" "private-subnet" {
  vpc_id                                      = aws_vpc.eks-vpc.id
  count                                       = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  cidr_block                                  = cidrsubnet(var.eks-vpc, 8, count.index+3)
  map_public_ip_on_launch                     = "true"
  enable_resource_name_dns_a_record_on_launch = "true"
  availability_zone                           = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "Private-Subnet-${count.index + 1}"
  }

}



resource "aws_eip" "eip" {
  count = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  vpc   = true
}


resource "aws_nat_gateway" "eks-vpc-n-gw" {
  count         = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  allocation_id = element(aws_eip.eip.*.id, count.index)
  subnet_id     = element(aws_subnet.public-subnet.*.id, count.index)

  tags = {
    "Name" = "eks-vpc-n-gw-${count.index + 1}"
  }
}


resource "aws_route" "eks-vpc-r-private" {
  count                  = var.eks-vpc == "10.0.0.0/16" ? 3 : 0
  route_table_id         = aws_route_table.eks-vpc-rt-private.id
  gateway_id             = element(aws_nat_gateway.eks-vpc-n-gw.*.id, count.index)
  destination_cidr_block = element(aws_subnet.private-subnet.*.cidr_block, count.index)
}


resource "aws_route_table" "eks-vpc-rt-private" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "eks-vpc-rt-private"
  }
}


resource "aws_route_table_association" "eks-vpc-rt-a-private" {
  count          = var.eks-vpc == 3 ? 3 : 0
  route_table_id = aws_route_table.eks-vpc-rt-private.id
  subnet_id      = element(aws_subnet.private-subnet.*.id, count.index)
}

resource "aws_internet_gateway" "eks-vpc-ig" {
  vpc_id = aws_vpc.eks-vpc.id
  tags = {
    "Name" = "eks-vpc-ig"
  }
}


resource "aws_route" "eks-vpc-r" {
  route_table_id         = aws_route_table.eks-vpc-rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks-vpc-ig.id
}


resource "aws_route_table" "eks-vpc-rt" {
  vpc_id = aws_vpc.eks-vpc.id

  tags = {
    "Name" = "eks-vpc-rt"
  }
}


resource "aws_route_table_association" "eks-vpc-rt-a" {
  count          = length(aws_subnet.public-subnet) == 3 ? 3 : 0
  subnet_id      = element(aws_subnet.public-subnet.*.id, count.index)
  route_table_id = aws_route_table.eks-vpc-rt.id

}


provider "aws" {
  region = "us-east-1"
}


data "aws_availability_zones" "azs" {
  state = "available"
}

output "available_zones" {
  value = data.aws_availability_zones.azs.names
}

resource "aws_vpc" "app-vpc" {
  cidr_block           = var.app-vpc
  instance_tenancy     = "default"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    "Name" = "App-VPC"
  }
}


resource "aws_internet_gateway" "app-vpc-ig" {
  vpc_id = aws_vpc.app-vpc.id

  tags = {
    "Name" = "APP-VPC-IG"
  }

}


resource "aws_subnet" "app-vpc-public-subnet" {
  vpc_id                  = aws_vpc.app-vpc.id
  count                   = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  cidr_block              = cidrsubnet(var.app-vpc, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "APP-VPC-PUBLIC-SUBNET-${count.index + 1}"
  }
}

resource "aws_route_table" "app-vpc-r-public" {

  vpc_id = aws_vpc.app-vpc.id
  tags = {
    "Name" = "APP-VPC-R-PUBLIC"
  }
}


resource "aws_route" "app-vpc-route-public" {

  route_table_id         = aws_route_table.app-vpc-r-public.id
  destination_cidr_block = var.Global_CIDR
  gateway_id             = aws_internet_gateway.app-vpc-ig.id

}

resource "aws_route_table_association" "app-vpc-rta-public" {
  count          = length(aws_subnet.app-vpc-public-subnet) == 3 ? 3 : 0
  subnet_id      = element(aws_subnet.app-vpc-public-subnet.*.id, count.index)
  route_table_id = aws_route_table.app-vpc-r-public.id
}

resource "aws_subnet" "app-vpc-private-subnet" {
  vpc_id            = aws_vpc.app-vpc.id
  count             = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  cidr_block        = cidrsubnet(var.app-vpc, 8, count.index + 3)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "APP-VPC-Private-Subnet-${count.index + 1}"
  }
}

resource "aws_eip" "app-vpc-eip" {
  count  = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  domain = "vpc"
  tags = {
    "Name" = "app-vpc-eip-${count.index + 1}"
  }
}



resource "aws_nat_gateway" "app-vpc-nat-gw" {
  count         = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  allocation_id = element(aws_eip.app-vpc-eip.*.id, count.index)
  subnet_id     = element(aws_subnet.app-vpc-public-subnet.*.id, count.index)

  tags = {
    "Name" = "app-vpc-nat-gw-${count.index + 1}"
  }

}


resource "aws_route_table" "app-vpc-r-private" {

  vpc_id = aws_vpc.app-vpc.id
  tags = {
    "Name" = "APP-VPC-R-PRIVATE"
  }

}


resource "aws_route" "app-vpc-route-private" {

  count                  = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  route_table_id         = aws_route_table.app-vpc-r-private.id
  gateway_id             = element(aws_nat_gateway.app-vpc-nat-gw.*.id, count.index)
  destination_cidr_block = element(aws_subnet.app-vpc-private-subnet.*.cidr_block, count.index)

}

resource "aws_route_table_association" "app-vpc-rta-private" {
  count          = length(aws_subnet.app-vpc-private-subnet) == 3 ? 3 : 0
  route_table_id = aws_route_table.app-vpc-r-private.id
  subnet_id      = element(aws_subnet.app-vpc-private-subnet.*.id, count.index)
}


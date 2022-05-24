provider "aws" {
}

data "aws_availability_zones" "azs" {
  state = "available"
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
    "Name" = "app-vpc-ig"
  }
}
resource "aws_subnet" "app-vpc-public-subnet" {
  vpc_id                  = aws_vpc.app-vpc.id
  count                   = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  cidr_block              = cidrsubnet(var.app-vpc, 8, count.index)
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.azs.names[count.index]


  tags = {
    "Name" = "App-Vpc-Public-Subnet-${count.index + 1}"
  }
}

resource "aws_route_table" "app-vpc-rt-public" {
  vpc_id = aws_vpc.app-vpc.id

  tags = {
    "Name" = "app-vpc-rt"
  }
}

resource "aws_route" "app-vpc-r-public" {
  route_table_id         = aws_route_table.app-vpc-rt-public.id
  destination_cidr_block = var.Global_CIDR
  gateway_id             = aws_internet_gateway.app-vpc-ig.id
}

resource "aws_route_table_association" "app-vpc-rta-public" {
  count          = length(aws_subnet.app-vpc-public-subnet) == 3 ? 3 : 0
  subnet_id      = element(aws_subnet.app-vpc-public-subnet.*.id, count.index)
  route_table_id = aws_route_table.app-vpc-rt-public.id
}

resource "aws_subnet" "app-vpc-private-subnet" {
  vpc_id            = aws_vpc.app-vpc.id
  count             = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  cidr_block        = cidrsubnet(var.app-vpc, 8, count.index + 3)
  availability_zone = data.aws_availability_zones.azs.names[count.index]

  tags = {
    "Name" = "App-VPC-Private-Subnet-${count.index + 1}"
  }
}


resource "aws_eip" "app-vpc-eip" {
  count = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  vpc   = true
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

resource "aws_route_table" "app-vpc-rt-private" {
  vpc_id = aws_vpc.app-vpc.id
  tags = {
    "Name" = "App-Vpc-Rt-Private"
  }
}
resource "aws_route" "app-vpc-r-private" {
  count                  = var.app-vpc == "10.22.0.0/16" ? 3 : 0
  route_table_id         = aws_route_table.app-vpc-rt-private.id
  gateway_id             = element(aws_nat_gateway.app-vpc-nat-gw.*.id, count.index)
  destination_cidr_block = element(aws_subnet.app-vpc-private-subnet.*.cidr_block, count.index)
}

resource "aws_route_table_association" "app-vpc-rta-private" {
  count          = length(aws_subnet.app-vpc-private-subnet) == 3 ? 3 : 0
  route_table_id = aws_route_table.app-vpc-rt-private.id
  subnet_id      = element(aws_subnet.app-vpc-private-subnet.*.id, count.index)
}




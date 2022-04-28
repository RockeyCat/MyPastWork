variable "aws_access_key" { 
}
variable "aws_secret_key" { 
}
variable "region" { 
}

variable "azs" {
  type = list
  default = ["ap-south-1a","ap-south-1b"]
}

variable "prod-public-subnets" {
  type = list
  default = ["10.22.0.0/24","10.22.1.0/24"]
}

variable "prod-private-subnets" {
  type = list
  default = ["10.22.3.0/24","10.22.4.0/24"]
}


variable "ec2-instance-type" {
  type = string
  default = "t2.micro"
}


variable "public-subnet" {
  type = list
  default = ["20.20.20.0/24","30.30.30.0/24"]
}
provider "aws" {
  
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}

resource "aws_vpc" "prod-vpc" {
  
  cidr_block = "10.22.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support = "true"
  instance_tenancy = "default"


  tags = {
    "Name" = "prod-vpc"
  }
}




resource "aws_subnet" "prod-public-subnets" {
    vpc_id = aws_vpc.prod-vpc.id
    count = length(var.azs)
    cidr_block = element(var.prod-public-subnets, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
      "Name" = "prod-public-subnet-${count.index+1}"
    }
  
}


resource "aws_subnet" "prod-private-subnets" {
    vpc_id = aws_vpc.prod-vpc.id
    count = length(var.azs)
    cidr_block = element(var.prod-private-subnets, count.index)
    availability_zone = element(var.azs, count.index)

    tags = {
      "Name" = "prod-private-subnet-${count.index+1}"
    }
  
}

/*
resource "aws_security_group" "prod-vpc-sg" {
  vpc_id = aws_vpc.prod-vpc.id
  count = length(var.azs)
  description = "ec2-sgs"
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

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    
    }

    tags = {
        "name" = "prod-vpc-sg${count.index+1}"
    }

}*/


resource "aws_internet_gateway" "prod-vpc-igw" {
  
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    "Name" = "prod-vpc-igw"
  }
}

resource "aws_route_table" "prod-vpc-rt-public" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    "Name" = "prod-vpc-rt-public"
  }
}


resource "aws_route_table" "prod-vpc-rt-private" {
  vpc_id = aws_vpc.prod-vpc.id

  tags = {
    "Name" = "prod-vpc-rt-private"
  }
}


resource "aws_route_table_association" "public-subnet-association" {
  
  count = length(var.prod-public-subnets)
  route_table_id = aws_route_table.prod-vpc-rt-public.id
  subnet_id = element(aws_subnet.prod-public-subnets.*.id, count.index)
  
}

resource "aws_route_table_association" "private-subnet-association" {
  
  count = length(var.prod-private-subnets)
  route_table_id = aws_route_table.prod-vpc-rt-private.id
  subnet_id = element(aws_subnet.prod-private-subnets.*.id, count.index)

}


resource "aws_eip" "prod-nat-eip" {
  count = length(var.azs)
  vpc = true


  tags = {
    "Name" = "prod-nat-eip-${count.index+1}"
  }
}


resource "aws_nat_gateway" "prod-nat-gw" {
  count = length(var.azs)
  allocation_id = element(aws_eip.prod-nat-eip.*.id, count.index)
  subnet_id = element(aws_subnet.prod-public-subnets.*.id, count.index)

    tags = {
      "Name" = "prod-nat-gw-${count.index+1}"
    }

}



resource "aws_route" "prod-rt-public" {
  count = length(var.public-subnet)
  route_table_id = aws_route_table.prod-vpc-rt-public.id
  destination_cidr_block = element(var.public-subnet, count.index)
  gateway_id = aws_internet_gateway.prod-vpc-igw.id

}

resource "aws_route" "prod-rt-private" {
  count = length(var.prod-private-subnets)
  route_table_id = aws_route_table.prod-vpc-rt-private.id  
  destination_cidr_block = element(var.prod-private-subnets, count.index)
  gateway_id = element(aws_nat_gateway.prod-nat-gw.*.id, count.index)
}

resource "aws_route" "prod-rt-nat-ref" {
  count = length(var.prod-private-subnets)
  route_table_id = aws_route_table.prod-vpc-rt-private.id  
  destination_cidr_block = element(var.prod-public-subnets, count.index)
  gateway_id = element(aws_nat_gateway.prod-nat-gw.*.id, count.index)
}
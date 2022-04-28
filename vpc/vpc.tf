variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}


resource "aws_vpc" "TestVPC" {
  cidr_block = "10.0.0.0/16"

  tags=  {
      Name = "TestVPC"
  }
  enable_dns_hostnames = "true" 
  enable_dns_support = "true"
  enable_classiclink = "false"
  instance_tenancy = "default"
  
}

resource "aws_subnet" "Subnet-1" {
  vpc_id = aws_vpc.TestVPC.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = "true"
  map_customer_owned_ip_on_launch = "false"
  enable_resource_name_dns_a_record_on_launch = "true"
  tags= {
      Name = "Subnet-1"
  }
}

resource "aws_subnet" "Subnet-2" {
  vpc_id = aws_vpc.TestVPC.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = "true"
  map_customer_owned_ip_on_launch = "false"
  enable_resource_name_dns_a_record_on_launch = "true"
  tags= {
      Name = "Subnet-2"
  }
}

resource "aws_subnet" "Subnet-3" {
  vpc_id = aws_vpc.TestVPC.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  map_customer_owned_ip_on_launch = "false"
  enable_resource_name_dns_a_record_on_launch = "true"
  tags= {
      Name = "Subnet-3"
  }
}

resource "aws_internet_gateway" "igw-test" {
  vpc_id = aws_vpc.TestVPC.id
  tags = {
      Name = "igw-test"
  }
}

resource "aws_route_table" "subnetrt" {
 vpc_id = aws_vpc.TestVPC.id

 route {
  cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw-test.id
 } 

 tags = {
     Name = "subnetrt"
 }
}
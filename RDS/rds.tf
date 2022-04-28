variable "aws_access_key" {
  
}

variable "aws_secret_key" {
  
}

variable "region" {
  
}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}


resource "aws_db_instance" "myfirstrds" {
  
allocated_storage = 10
max_allocated_storage = 20
engine = "mysql"
engine_version = "5.7"
instance_class = "db.t3.micro"
db_name = "myfirstrds"
username = "admin"
password = "admin123456"
parameter_group_name = "default.mysql5.7"
db_subnet_group_name = "default"
option_group_name = "default:mysql-5-7"
skip_final_snapshot = "true"

tags = {
  "Name" = "Blackmamba"
}
}

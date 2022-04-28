variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}




provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key 
  region = var.region

}


resource "aws_dynamodb_table" "mytable" {
  name = "basictable"
  billing_mode = "PROVISIONED"
  read_capacity = 20
  write_capacity = 20
  hash_key = "UserId"
  range_key = "GameTitle"


  attribute {
    name = "UserId"
    type = "S"
  }

   attribute {
    name = "GameTitle"
    type = "S"
  }

  attribute {
    name = "TopScore"
    type = "N"
  }  


    global_secondary_index {
    name = "GameTitleIndex"
    hash_key = "GameTitle"
    range_key = "TopScore"
    write_capacity = 10
    read_capacity = 10
    projection_type = "INCLUDE"
    non_key_attributes = ["UserId"]
    }
}
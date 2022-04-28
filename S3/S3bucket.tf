

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "region" {}

provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = var.region
}


resource "aws_s3_bucket" "newbucket0209" {
  bucket = "newbucket0209"
}

resource "aws_s3_bucket_public_access_block" "newbucket0209" {
  bucket = aws_s3_bucket.newbucket0209.id
  block_public_acls = true
  block_public_policy = true
}


resource "aws_s3_bucket_server_side_encryption_configuration" "newbucket0209" {
  bucket = aws_s3_bucket.newbucket0209.id

  rule {
    apply_server_side_encryption_by_default {

        sse_algorithm = "AES256"
    }
  }

}
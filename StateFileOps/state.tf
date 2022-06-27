provider "aws" {
  shared_config_files      = ["/var/root/.aws/config"]
  shared_credentials_files = ["/var/root/.aws/credentials"]
}

terraform {
  backend "s3" {
    bucket = "av-aws-cicd-s3-bucket"
    key    = "network/demo.tfstate"
    region = "us-east-2"
    dynamodb_table = "av-test-table"
  }
}

resource "time_sleep" "wait" {
  create_duration = "60s"
}
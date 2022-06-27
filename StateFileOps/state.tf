provider "aws" {
  shared_config_files      = ["/var/root/.aws/config"]
  shared_credentials_files = ["/var/root/.aws/credentials"]
}

terraform {
  backend "s3" {
    bucket = "av-aws-cicd-s3-bucket"
    key    = "network/tmp.tfstate"
    region = "us-east-2"
  }
}

resource "time_sleep" "wait" {
  create_duration = "150s"
}
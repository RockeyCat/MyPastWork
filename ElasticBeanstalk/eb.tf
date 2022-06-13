variable "region" {
  type    = string
  default = "us-east-2"
}

provider "aws" {
  shared_config_files      = ["/var/root/.aws/config"]
  shared_credentials_files = ["/var/root/.aws/credentials"]
  region                   = var.region
}

data "aws_s3_bucket" "av-aws-cicd-s3-bucket" {

  bucket = "av-aws-cicd-s3-bucket"
}

resource "aws_elastic_beanstalk_application" "ebs-a-poc" {
  name = "ebs-a-poc"
}

resource "aws_elastic_beanstalk_environment" "ebs-a-poc-e" {
  name                = "ebs-a-poc-e"
  application         = aws_elastic_beanstalk_application.ebs-a-poc.name
  solution_stack_name = "64bit Amazon Linux 2 v4.2.15 running Tomcat 8.5 Corretto 11"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws_instance_testing_role_for_elastic_beanstalk"
  }

}


resource "aws_elastic_beanstalk_application_version" "ebs-a-poc-v" {
  name        = "ebs-a-poc-v"
  application = aws_elastic_beanstalk_application.ebs-a-poc.name
  bucket      = data.aws_s3_bucket.av-aws-cicd-s3-bucket.id
  description = "Version Deployment for test EBS"
  key         = "Pipeline-Pj/MyWebApp//jobs/Pipeline-Pj/34/MyWebApp.war"

}

output "app_version" {
  value = aws_elastic_beanstalk_application.ebs-a-poc.name
}
output "env_name" {
  value = aws_elastic_beanstalk_environment.ebs-a-poc-e.name
}

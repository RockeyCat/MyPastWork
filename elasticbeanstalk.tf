resource "aws_elastic_beanstalk_application" "app" {
  name = var.aws_elastic_beanstalk_application
  description = "test eleastic beanstalk application"


  appversion_lifecycle {
    service_role = aws_iam_role.ssm-role.arn
    max_count = 128
    delete_source_from_s3 = true  
    }
}


resource "aws_s3_object" "default" {
  bucket = aws_s3_bucket.aws-s3-bucket.id
  key = "beanstalk/go-v1.zip"
  source = "go-v1.zip"
}

resource "aws_elastic_beanstalk_application_version" "app-version" {
  name = "app-test-version"
  application = "app"
  description = "app-el-bs"
  bucket = aws_s3_bucket.aws-s3-bucket.id
  key = aws_s3_object.default.id

}


resource "aws_elastic_beanstalk_configuration_template" "app-template" {
  name = "app-elastic-beanstalk"
  application = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2015.09 v2.0.8 running Go 1.4"
}


resource "aws_elastic_beanstalk_environment" "app-env" {
  name = "app-elastic-env"
  application = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2015.03 v2.0.3 running Go 1.4"

  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCID"
    value = aws_vpc.app-vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Public-Subnet"
    value = join(",", aws_subnet.app-vpc-public-subnet[*].id)

  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "Private-Subnet"
    value = join(",", aws_subnet.app-vpc-private-subnet[*].id)
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "Autoscaling LC"
    value = var.instance_type
  }

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "SSHSourceRestriction"
        value     = "tcp, 22, 22, ${var.app-vpc}"
    } 

 

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "EC2KeyName"
        value     = "${var.EC2KeyName}"
    }

    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name      = "ServiceRole"
        value     = "${aws_iam_instance_profile.ssm-role.name}"
    }

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name      = "IamInstanceProfile"
        value     = "${aws_iam_instance_profile.ssm-role.name}"
    }
}




output "arn" {
  value = aws_elastic_beanstalk_application.app.arn
}

output "description" {
  value = aws_elastic_beanstalk_application.app.description
}
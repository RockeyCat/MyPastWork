variable "app-vpc" {
  type        = string
  default     = "10.22.0.0/16"
  description = "Predefined VPC CIDR"
}

variable "Global_CIDR" {
  type    = string
  default = "0.0.0.0/0"

}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "instance_type" {
  type    = string
  default = "t2.small"

}

variable "azs" {
  type    = list(any)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "port" {
  type    = number
  default = 80
}
variable "protocol" {
  type    = string
  default = "HTTP"
}
variable "storage" {
  type    = number
  default = 20

}

variable "aws-s3-bucket" {
  type    = string
  default = "aws-hajmola-imli-az"
}


variable "cluster_name" {
  type = string
  default = "aws-cluster-hajmola"
}


variable "min_size" {
  type = number
  default = 1
}

variable "desired_size" {
  type = number
  default = 2
}


variable "max_size" {
  type = number
  default = 3
}


variable "node_group_name" {
  type = string
  default = "app-ec2"
}

variable "pracx" {
  type = string
  default = "pracx"
}

variable "retention_in_days" {
  type = number
  default = 7
}


variable "aws_elastic_beanstalk_application" {
  type = string
  default = "aws-app-eb"
  
}

variable "EC2KeyName" {
  type = string
  default = "app_key.pem"
}


variable "FullRepositoryID" {
  type = string
  default = "Himanshuuj1997/Data-Science"
}


variable "db_username" {
  type = string
  default = "master"
}

variable "db_password" {
  type = string
  default = "Qwertyuiop@1234567890"
}
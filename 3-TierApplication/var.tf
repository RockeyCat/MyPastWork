variable "app-vpc" {
  type        = string
  default     = "10.22.0.0/16"
  description = "Predifined VPC CIDR "
}


variable "Global_CIDR" {
  type    = string
  default = "0.0.0.0/0"
}


variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "azs" {
  type    = list(any)
  default = ["ap-south-1a", "ap-south-1b"]
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
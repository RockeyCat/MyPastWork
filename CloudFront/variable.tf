variable "bucket_prefix" {
  type        = string
  description = "Name of the s3 bucket to be created."
  default = "avawss3bucketfortest"
}

variable "region" {
  type        = string
  default     = "us-east-2"
  description = "Name of the s3 bucket to be created."
}
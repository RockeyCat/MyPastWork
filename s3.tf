resource "aws_s3_bucket" "aws-s3-bucket" {
  bucket = var.aws-s3-bucket
}


resource "aws_s3_bucket_website_configuration" "aws-s3-bucket-website" {
  bucket = aws_s3_bucket.aws-s3-bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}



resource "aws_s3_bucket_policy" "aws-s3-bucket-policy" {
  bucket = aws_s3_bucket.aws-s3-bucket.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "PublicReadGetObject",
            "Effect": "Allow",
            "Principal": "*",
            "Action": [
                "s3:GetObject"
            ],
            "Resource": [
                "arn:aws:s3:::${aws_s3_bucket.aws-s3-bucket.id}/*"
            ]
        }
    ]
}
POLICY
}


resource "aws_s3_bucket_public_access_block" "aws-s3-bucket" {
  bucket              = aws_s3_bucket.aws-s3-bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "aws-s3-bucket" {
  bucket = aws_s3_bucket.aws-s3-bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }

}

output "s3_bucket_name" {
  value       = aws_s3_bucket.aws-s3-bucket.bucket
  description = "The name of the S3 bucket."
}


output "s3_bucket_arn" {
  value = aws_s3_bucket.aws-s3-bucket.arn
}

output "s3_bucket_id" {
  value = aws_s3_bucket.aws-s3-bucket.id
}


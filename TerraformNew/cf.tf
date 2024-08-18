# Create an Origin Access Identity to allow CloudFront to access the S3 bucket
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "Origin Access Identity for S3 bucket"
}

# Create a CloudFront Distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "CloudFront distribution for S3 bucket"

  # Define the S3 bucket as the origin
  origin {
    domain_name = aws_s3_bucket.aws-s3-bucket.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.aws-s3-bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  # Default cache behavior configuration
  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.aws-s3-bucket.id}"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]

    compress    = true
    default_ttl = 3600
    min_ttl     = 0
    max_ttl     = 86400

    forwarded_values {
      query_string = true

      cookies {
        forward = "none"
      }
    }
  }

  # Configure CloudFront logging
  logging_config {
    include_cookies = false
    bucket          = "my-cloudfront-logs.s3.amazonaws.com"
    prefix          = "example-prefix"
  }

  # Price class for distribution
  price_class = "PriceClass_All"

  # Viewer certificate configuration
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  # Custom error responses
  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/error.html"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/error.html"
  }

  # Restrictions block
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Tags for the distribution
  tags = {
    Name        = "CloudFront Distribution for S3 Bucket"
    Environment = "Production"
  }
}

output "cloudfront_domain_name" {
  value       = aws_cloudfront_distribution.cdn.domain_name
  description = "The domain name of the CloudFront distribution."
}

output "cloudfront_distribution_id" {
  value       = aws_cloudfront_distribution.cdn.id
  description = "The ID of the CloudFront distribution."
}

resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "null_resource" "git_clone_and_upload" {
  depends_on = [aws_s3_bucket.my_bucket, aws_s3_bucket_public_access_block.my_bucket_block]

  triggers = {
    git_clone_trigger = "${aws_s3_bucket.my_bucket.id}"
  }

  provisioner "local-exec" {
    command = "git clone https://github.com/sami-dev/aws-s3-static-website-sample.git"
  }

  provisioner "local-exec" {
    command = "aws s3 sync aws-s3-static-website-sample/Website s3://${aws_s3_bucket.my_bucket.id}"
  }

  provisioner "local-exec" {
    command = "rm -r aws-s3-static-website-sample"
  }
}

resource "aws_cloudfront_origin_access_identity" "cloudfront" {
  comment = "CloudFront OAI for S3 bucket"
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Id      = "PolicyForCloudFront",
    Statement = [
      {
        Sid       = "GrantS3GetObject",
        Effect    = "Allow",
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.cloudfront.iam_arn
        },
        Action = "s3:*",
        Resource = aws_s3_bucket.my_bucket.arn
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "cloudfront" {
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfront.cloudfront_access_identity_path
    }
  }

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    target_origin_id = "S3Origin"

    viewer_protocol_policy = "allow-all"
    allowed_methods      = ["GET", "HEAD", "OPTIONS"]
    cached_methods       = ["GET", "HEAD"]
    min_ttl              = 0
    default_ttl          = 3600
    max_ttl              = 86400
    compress             = true
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  default_root_object = "index.html"

  viewer_certificate {
    acm_certificate_arn = var.acm_certificate_arn
    ssl_support_method = "sni-only"
  }
}

resource "aws_waf_ipset" "ipset" {
  name = "tfIPSet"

  ip_set_descriptors {
    type  = "IPV4"
    value = var.ip_set_value
  }
}

resource "aws_waf_rule" "wafrule" {
  depends_on  = [aws_waf_ipset.ipset]
  name        = "tfWAFRule"
  metric_name = "tfWAFRule"

  predicates {
    data_id = aws_waf_ipset.ipset.id
    negated = false
    type    = "IPMatch"
  }
}

resource "aws_waf_web_acl" "wafacl" {
  depends_on  = [aws_waf_rule.wafrule]
  name        = "tfWebACL"
  metric_name = "tfWebACL"

  default_action {
    type = "ALLOW"
  }

  rules {
    action {
      type = "BLOCK"
    }

    priority = 1
    rule_id  = aws_waf_rule.wafrule.id
    type     = "REGULAR"
  }
}

resource "aws_wafv2_web_acl_association" "cloudfront" {
  depends_on    = [aws_waf_web_acl.wafacl, aws_cloudfront_distribution.cloudfront]
  web_acl_arn    = aws_waf_web_acl.wafacl.id
  resource_arn  = aws_cloudfront_distribution.s3_distribution.arn
}

output "aws_waf_web_acl_id" {
  value = aws_waf_web_acl.wafacl.id
}

output "aws_cloudfront_distribution_arn" {
  value = aws_cloudfront_distribution.cloudfront.arn
}
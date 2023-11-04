variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "your-unique-bucket-name-sadasdasdasdasdasdasdasdadad"
}

variable "acm_certificate_arn" {
  description = "The ARN of the ACM certificate for CloudFront"
  type        = string
  default     = "arn:aws:acm:us-east-1:038777287445:certificate/155b9eec-676b-485e-a390-e1df7efa6f02"
}

variable "ip_set_value" {
  description = "The value for the WAF IP set"
  type        = string
  default     = "192.0.7.0/24"
}

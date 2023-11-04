variable "subnet_ids" {
  description = "A list of subnet IDs"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

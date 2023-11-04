
# Variables
variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "vpc"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "docker_image" {
  description = "Docker image URL for the container"
  type        = string
  default     = "nginxdemos/hello:latest" 
}

variable "availability_zones" {
  description = "List of Availability Zones"
  type        = list(string)
  default     = ["us-east-1d", "us-east-1b", "us-east-1c", "us-east-1e", "us-east-1a", "us-east-1f"]
}

variable "updated_subnet_cidr_blocks" {
  description = "CIDR blocks for updated subnets"
  type        = list(string)
  default     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24", "10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}
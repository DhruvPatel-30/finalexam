
variable "student_name" {
  description = "dhruvmaheshbhaipatel"
  type        = string
}

variable "student_number" {
  description = "9062297"
  type        = string
}

variable "team" {
  description = "Owning team"
  type        = string
  default     = "devops"
}

variable "aws_region" {
  description = "AWS region, e.g. us-east-1"
  type        = string
  default     = "us-east-1"
}

variable "azs" {
  description = "List of two availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_username" {
  description = "RDS username"
  type        = string
  default     = "admin"
}

variable "db_password" {
  description = "RDS password (DO NOT COMMIT REAL SECRETS)"
  type        = string
  sensitive   = true
}

variable "s3_bucket_name" {
  description = "Name for the S3 bucket (must be globally unique)"
  type        = string
}
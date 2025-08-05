
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_subnet_1_cidr" {
  type        = string
  default     = "172.16.1.0/24"
}

variable "public_subnet_2_cidr" {
  type        = string
  default     = "172.16.2.0/24"
}

variable "private_subnet_1_cidr" {
  type        = string
  default     = "172.16.3.0/24"
}

variable "private_subnet_2_cidr" {
  type        = string
  default     = "172.16.4.0/24"
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t3.micro"
}

variable "db_username" {
  type        = string
  default     = "admin"
}

variable "db_password" {
  type        = string
  sensitive   = true
}

variable "db_sg_id" {
  type        = string
  description = "Security group ID for RDS"
}

variable "ec2_sg_id" {
  type        = string
  description = "Security group ID for EC2"
}

variable "ssm_sg_id" {
  type        = string
  description = "Security group ID for SSM VPC endpoint"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for CloudFront origin"
  type        = string
}

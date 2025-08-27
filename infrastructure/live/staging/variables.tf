variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "naas-prod"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
}

variable "key_pair_name" {
  description = "AWS Key Pair name for EC2 instances"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for Kubernetes master nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for Kubernetes worker nodes"
  type        = string
  default     = "t3.small"
}

variable "master_count" {
  description = "Number of master nodes"
  type        = number
  default     = 1
}

variable "worker_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 2
}

variable "budget_limit" {
  description = "Monthly budget limit in USD"
  type        = number
  default     = 100
}

variable "alert_threshold" {
  description = "Budget alert threshold percentage"
  type        = number
  default     = 80
}

variable "alert_emails" {
  description = "Email addresses for budget alerts"
  type        = list(string)
  default     = []
}
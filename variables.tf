# ============================================================================
# Variables for Team Alpha Compute
# ============================================================================

variable "app_name" {
  type        = string
  description = "Application name for resource naming"
  default     = "team-alpha"
}

variable "ami_name_prefix" {
  type        = string
  description = "Prefix to search for AMI (from team-alpha-infra)"
  default     = "team-alpha-web-server-"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  default     = "t3.micro"
}

variable "instance_count" {
  type        = number
  description = "Number of instances to launch"
  default     = 1

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 10
    error_message = "Instance count must be between 1 and 10"
  }
}

variable "allocate_elastic_ips" {
  type        = bool
  description = "Whether to allocate elastic IPs for instances"
  default     = true
}

variable "allowed_http_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed to access HTTP/HTTPS"
  default     = ["0.0.0.0/0"]
}

variable "allowed_ssh_cidrs" {
  type        = list(string)
  description = "CIDR blocks allowed SSH access"
  default     = ["0.0.0.0/0"]
}

variable "iam_instance_profile" {
  type        = string
  description = "IAM instance profile to attach to instances"
  default     = null
}

variable "user_data" {
  type        = string
  description = "User data script (optional, AMI already has Nginx)"
  default     = null
}

variable "enable_monitoring" {
  type        = bool
  description = "Enable detailed CloudWatch monitoring"
  default     = true
}

variable "encrypt_ebs" {
  type        = bool
  description = "Encrypt EBS volumes"
  default     = true
}

variable "root_volume_size" {
  type        = number
  description = "Root volume size in GB"
  default     = 20
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags for all resources"
  default = {
    Terraform   = "true"
    Project     = "team-alpha"
    Environment = "development"
    ManagedBy   = "Terraform"
  }
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production"
  }
}

variable "aws_region" {
  type        = string
  description = "AWS region for resources"
  default     = "eu-west-2"
}

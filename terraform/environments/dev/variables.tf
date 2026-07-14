# ============================================================
# Environment Variables - Notes CRUD Application
# ============================================================

# -----------------------------------------------------------
# Provider & Environment
# -----------------------------------------------------------
variable "aws_region" {
  description = "AWS region to deploy resources into"
  type        = string
  default     = "ap-south-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region identifier (e.g., ap-south-1, us-east-1)."
  }
}

variable "environment" {
  description = "Environment name for resource tagging and naming"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner/team responsible for the resources"
  type        = string
  default     = "platform-team"

  validation {
    condition     = length(var.owner) > 0
    error_message = "Owner cannot be empty."
  }
}

variable "aws_account_id" {
  description = "AWS Account ID for IAM resource ARNs"
  type        = string

  validation {
    condition     = can(regex("^\\d{12}$", var.aws_account_id))
    error_message = "AWS Account ID must be a 12-digit number."
  }
}

# -----------------------------------------------------------
# Network Configuration
# -----------------------------------------------------------
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_a_cidr, 0))
    error_message = "Public subnet A CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrhost(var.public_subnet_b_cidr, 0))
    error_message = "Public subnet B CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string
  default     = "10.0.11.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_a_cidr, 0))
    error_message = "Private subnet A CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string
  default     = "10.0.12.0/24"

  validation {
    condition     = can(cidrhost(var.private_subnet_b_cidr, 0))
    error_message = "Private subnet B CIDR must be a valid IPv4 CIDR notation."
  }
}

# -----------------------------------------------------------
# Security Group Configuration
# -----------------------------------------------------------
variable "app_port" {
  description = "Application port for EC2 instances (default: 3000 for Node.js)"
  type        = number
  default     = 3000

  validation {
    condition     = var.app_port > 0 && var.app_port <= 65535
    error_message = "Application port must be between 1 and 65535."
  }
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH access to EC2 instances (restrict in production)"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition     = alltrue([for cidr in var.ssh_allowed_cidrs : can(cidrhost(cidr, 0))])
    error_message = "All SSH allowed CIDRs must be valid IPv4 CIDR notation."
  }
}

# -----------------------------------------------------------
# IAM Configuration
# -----------------------------------------------------------
variable "cloudwatch_agent_s3_bucket" {
  description = "S3 bucket name for CloudWatch Agent configuration (if using S3)"
  type        = string
  default     = ""

  validation {
    condition     = var.cloudwatch_agent_s3_bucket == "" || can(regex("^[a-z0-9.-]+$", var.cloudwatch_agent_s3_bucket))
    error_message = "S3 bucket name must be valid (lowercase, numbers, dots, hyphens)."
  }
}

# -----------------------------------------------------------
# NAT Gateway Configuration
# -----------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnet internet access (DISABLE for Free Tier)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------
# EC2 Launch Template Configuration
# -----------------------------------------------------------
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t4g.micro", "t4g.small"], var.instance_type)
    error_message = "Instance type must be a supported burstable type."
  }
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "node_version" {
  description = "Node.js LTS major version to install"
  type        = string
  default     = "20"

  validation {
    condition     = contains(["18", "20", "22"], var.node_version)
    error_message = "Node.js version must be a supported LTS version (18, 20, 22)."
  }
}

variable "enable_cloudwatch_agent" {
  description = "Enable CloudWatch Agent installation and configuration"
  type        = bool
  default     = true
}

variable "enable_ssm_agent" {
  description = "Enable SSM Agent installation for Session Manager"
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 20

  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 16384
    error_message = "Root volume size must be between 8 and 16384 GB."
  }
}

variable "root_volume_type" {
  description = "Root volume type (gp3, gp2, io1, io2)"
  type        = string
  default     = "gp3"

  validation {
    condition     = contains(["gp3", "gp2", "io1", "io2"], var.root_volume_type)
    error_message = "Root volume type must be gp3, gp2, io1, or io2."
  }
}

variable "root_volume_delete_on_termination" {
  description = "Delete root volume on instance termination"
  type        = bool
  default     = true
}

variable "root_volume_encrypted" {
  description = "Encrypt root volume"
  type        = bool
  default     = true
}

variable "root_volume_kms_key_id" {
  description = "KMS Key ID for root volume encryption (optional, uses default if empty)"
  type        = string
  default     = ""
}

variable "associate_public_ip" {
  description = "Associate public IP address with instance"
  type        = bool
  default     = true
}

variable "github_repo" {
  description = "GitHub repository URL for application code"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch to deploy"
  type        = string
  default     = "main"
}

# -----------------------------------------------------------
# SSL / Domain Configuration
# -----------------------------------------------------------
variable "domain_name" {
  description = "Domain name for Let's Encrypt certificate (optional, empty = self-signed/IP-based)"
  type        = string
  default     = ""
}

variable "hosted_zone_id" {
  description = "Route 53 Hosted Zone ID for DNS validation and A record (required if domain_name is set)"
  type        = string
  default     = ""
}

variable "ssl_email" {
  description = "Email for Let's Encrypt registration (required if domain_name is set)"
  type        = string
  default     = "admin@localhost"
}

# -----------------------------------------------------------
# RDS Database Configuration (Free Tier)
# -----------------------------------------------------------
variable "db_name" {
  description = "Database name"
  type        = string
  default     = "notes_db"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "Database master password (use AWS Secrets Manager in production)"
  type        = string
  sensitive   = true
  default     = "changeme123" # CHANGE THIS IN PRODUCTION!
}

# -----------------------------------------------------------
# Optional EC2 Instance (for dev without ASG)
# -----------------------------------------------------------
variable "create_instance" {
  description = "Create an EC2 instance from the launch template (for dev without ASG)"
  type        = bool
  default     = true
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
  default     = "dev-notes-crud-instance"
}
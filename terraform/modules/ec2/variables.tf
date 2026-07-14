# ============================================================
# EC2 Module Variables
# ============================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "Invalid AWS region format."
  }
}

variable "owner" {
  description = "Owner tag for resources"
  type        = string
  default     = "platform-team"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = contains(["t3.micro", "t3.small", "t3.medium", "t4g.micro", "t4g.small"], var.instance_type)
    error_message = "Instance type must be a supported burstable type."
  }
}

variable "subnet_id" {
  description = "Subnet ID for EC2 instance (public subnet for ALB target)"
  type        = string

  validation {
    condition     = can(regex("^subnet-[0-9a-f]{8,}$", var.subnet_id))
    error_message = "Subnet ID must be a valid subnet identifier."
  }
}

variable "security_group_ids" {
  description = "List of Security Group IDs for EC2 instances"
  type        = list(string)

  validation {
    condition     = alltrue([for sg in var.security_group_ids : can(regex("^sg-[0-9a-f]{8,}$", sg))])
    error_message = "All security group IDs must be valid (sg-xxxxxxxx)."
  }
}

variable "instance_profile_arn" {
  description = "IAM Instance Profile ARN"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:iam::[0-9]{12}:instance-profile/", var.instance_profile_arn))
    error_message = "Instance Profile ARN must be a valid IAM instance profile ARN."
  }
}

variable "key_name" {
  description = "EC2 Key Pair name for SSH access (optional)"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "Application port (Node.js Express default 3000)"
  type        = number
  default     = 3000

  validation {
    condition     = var.app_port > 0 && var.app_port < 65536
    error_message = "App port must be between 1 and 65535."
  }
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

variable "cloudwatch_agent_s3_bucket" {
  description = "S3 bucket for CloudWatch Agent config (optional)"
  type        = string
  default     = ""
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

variable "ssl_email" {
  description = "Email for Let's Encrypt registration (required if domain_name is set)"
  type        = string
  default     = "admin@localhost"
}

# -----------------------------------------------------------
# Optional EC2 Instance (for dev environments without ASG)
# -----------------------------------------------------------
variable "create_instance" {
  description = "Whether to create an EC2 instance from the launch template (for dev without ASG)"
  type        = bool
  default     = false
}

variable "instance_name" {
  description = "Name for the EC2 instance (used when create_instance is true)"
  type        = string
  default     = ""
}
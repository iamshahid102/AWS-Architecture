variable "vpc_id" {
  description = "The ID of the VPC to create subnets in"
  type        = string
}

variable "environment" {
  description = "The environment name for resource tagging"
  type        = string

  validation {
    condition     = length(var.environment) > 0
    error_message = "Environment name must not be empty."
  }
}

variable "availability_zones" {
  description = "List of availability zones to deploy subnets into (must have at least 2)"
  type        = list(string)

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least 2 availability zones are required."
  }
}

variable "public_subnet_a_cidr" {
  description = "CIDR block for public subnet A"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_a_cidr, 0))
    error_message = "Public subnet A CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "public_subnet_b_cidr" {
  description = "CIDR block for public subnet B"
  type        = string

  validation {
    condition     = can(cidrhost(var.public_subnet_b_cidr, 0))
    error_message = "Public subnet B CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "private_subnet_a_cidr" {
  description = "CIDR block for private subnet A"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_subnet_a_cidr, 0))
    error_message = "Private subnet A CIDR must be a valid IPv4 CIDR notation."
  }
}

variable "private_subnet_b_cidr" {
  description = "CIDR block for private subnet B"
  type        = string

  validation {
    condition     = can(cidrhost(var.private_subnet_b_cidr, 0))
    error_message = "Private subnet B CIDR must be a valid IPv4 CIDR notation."
  }
}

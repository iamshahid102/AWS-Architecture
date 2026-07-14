# ACM Module Variables

variable "domain_name" {
  type        = string
  description = "Fully qualified domain name (e.g., api.example.com)"
  default     = ""
}

variable "hosted_zone_id" {
  type        = string
  description = "Route 53 Hosted Zone ID for DNS validation"
  default     = ""
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
}

variable "owner" {
  type        = string
  description = "Owner tag"
  default     = "platform-team"
}
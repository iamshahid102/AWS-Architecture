# variables

variable "vpc_cidr" {
  description = "CIDR Block of VPC"

  type = string
}

variable "environment" {
  type = string
}

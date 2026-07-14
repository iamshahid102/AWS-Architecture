provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "notes-crud-app"
      Environment = var.environment
      Terraform   = "true"
      ManagedBy   = "terraform"
    }
  }
}

# Bootstrap Terraform Configuration for Remote State Backend
# This creates the S3 bucket and DynamoDB table for Terraform state storage
# Uses local state (chicken-and-egg: the bucket that stores state can't use that bucket for state)

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# Random suffix for globally unique bucket name
resource "random_id" "tfstate_suffix" {
  byte_length = 8
}

# S3 Bucket for Terraform state
resource "aws_s3_bucket" "tfstate" {
  bucket = "notes-crud-tfstate-${random_id.tfstate_suffix.hex}"
}

resource "aws_s3_bucket_versioning" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  bucket = aws_s3_bucket.tfstate.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB table for state locking
resource "aws_dynamodb_table" "tfstate_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    Project     = "notes-crud"
    Environment = "bootstrap"
    ManagedBy   = "terraform"
  }
}

# Outputs for backend configuration
output "bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.tfstate.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.tfstate_locks.name
}

output "bucket_region" {
  description = "AWS region of the state bucket"
  value       = "ap-south-1"
}
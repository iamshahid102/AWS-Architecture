# ACM Module - Public Certificate with DNS Validation

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  # Determine if we should create the certificate
  create_cert = var.domain_name != ""
}

# ACM Certificate with DNS validation (only created when domain_name is provided)
resource "aws_acm_certificate" "notes_crud" {
  count = local.create_cert ? 1 : 0

  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.environment}-notes-crud-acm"
  })
}

# Route 53 validation records (only created when cert is created)
resource "aws_route53_record" "validation" {
  count = local.create_cert ? length(aws_acm_certificate.notes_crud[0].domain_validation_options) : 0

  name    = element(aws_acm_certificate.notes_crud[0].domain_validation_options, count.index).resource_record_name
  type    = element(aws_acm_certificate.notes_crud[0].domain_validation_options, count.index).resource_record_type
  ttl     = 60
  records = [element(aws_acm_certificate.notes_crud[0].domain_validation_options, count.index).resource_record_value]
  zone_id = var.hosted_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "notes_crud" {
  count                   = local.create_cert ? 1 : 0
  certificate_arn         = aws_acm_certificate.notes_crud[0].arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

# Outputs
output "certificate_arn" {
  description = "ARN of the ACM certificate"
  value       = local.create_cert ? aws_acm_certificate.notes_crud[0].arn : ""
}

output "certificate_id" {
  description = "ID of the ACM certificate"
  value       = local.create_cert ? aws_acm_certificate.notes_crud[0].id : ""
}

output "domain_validation_options" {
  description = "Domain validation options for manual verification"
  value       = local.create_cert ? aws_acm_certificate.notes_crud[0].domain_validation_options : []
}
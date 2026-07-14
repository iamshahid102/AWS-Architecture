output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "The CIDR block of the VPC"
  value       = aws_vpc.this.cidr_block
}

output "vpc_arn" {
  description = "The ARN of the VPC"
  value       = aws_vpc.this.arn
}

output "vpc_main_route_table_id" {
  description = "The ID of the main route table associated with the VPC"
  value       = aws_vpc.this.main_route_table_id
}

output "vpc_dns_hostnames_enabled" {
  description = "Whether DNS hostnames are enabled in the VPC"
  value       = aws_vpc.this.enable_dns_hostnames
}

output "vpc_dns_support_enabled" {
  description = "Whether DNS support is enabled in the VPC"
  value       = aws_vpc.this.enable_dns_support
}

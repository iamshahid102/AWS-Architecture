output "public_route_table_id" {
  description = "The ID of the public route table"
  value       = aws_route_table.public.id
}

output "public_route_table_arn" {
  description = "The ARN of the public route table"
  value       = aws_route_table.public.arn
}

output "private_route_table_id" {
  description = "The ID of the private route table"
  value       = aws_route_table.private.id
}

output "private_route_table_arn" {
  description = "The ARN of the private route table"
  value       = aws_route_table.private.arn
}
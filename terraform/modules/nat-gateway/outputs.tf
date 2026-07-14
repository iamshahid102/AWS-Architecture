output "nat_gateway_id" {
  description = "The ID of the NAT Gateway"
  value       = aws_nat_gateway.this.id
}

output "nat_gateway_public_ip" {
  description = "The public IP address of the NAT Gateway"
  value       = aws_nat_gateway.this.public_ip
}

output "nat_gateway_private_ip" {
  description = "The private IP address of the NAT Gateway"
  value       = aws_nat_gateway.this.private_ip
}

output "nat_gateway_subnet_id" {
  description = "The subnet ID where the NAT Gateway is deployed"
  value       = aws_nat_gateway.this.subnet_id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-nat-eip"
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

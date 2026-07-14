resource "aws_internet_gateway" "this" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

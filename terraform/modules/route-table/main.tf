resource "aws_route_table" "public" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.environment}-public-rt"
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

resource "aws_route_table" "private" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "${var.environment}-private-rt"
    Environment = var.environment
    Terraform   = "true"
    ManagedBy   = "terraform"
  }
}

# Public route to Internet Gateway
resource "aws_route" "public_to_igw" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = var.igw_id
}

# Private route to NAT Gateway (conditional - only created if create_nat_route is true)
resource "aws_route" "private_to_nat" {
  count = var.create_nat_route ? 1 : 0

  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = var.nat_gateway_id
}

# Public subnet associations
resource "aws_route_table_association" "public_a" {
  subnet_id      = var.public_subnet_ids[0]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = var.public_subnet_ids[1]
  route_table_id = aws_route_table.public.id
}

# Private subnet associations
resource "aws_route_table_association" "private_a" {
  subnet_id      = var.private_subnet_ids[0]
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = var.private_subnet_ids[1]
  route_table_id = aws_route_table.private.id
}
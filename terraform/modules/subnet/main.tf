resource "aws_subnet" "public_a" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_a_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = true

  tags = {
    Name                                       = "${var.environment}-public-subnet-a"
    Environment                                = var.environment
    Terraform                                  = "true"
    ManagedBy                                  = "terraform"
    "kubernetes.io/role/elb"                   = "1"
    "kubernetes.io/cluster/${var.environment}" = "shared"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.public_subnet_b_cidr
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = true

  tags = {
    Name                                       = "${var.environment}-public-subnet-b"
    Environment                                = var.environment
    Terraform                                  = "true"
    ManagedBy                                  = "terraform"
    "kubernetes.io/role/elb"                   = "1"
    "kubernetes.io/cluster/${var.environment}" = "shared"
  }
}

resource "aws_subnet" "private_a" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_a_cidr
  availability_zone       = var.availability_zones[0]
  map_public_ip_on_launch = false

  tags = {
    Name                                       = "${var.environment}-private-subnet-a"
    Environment                                = var.environment
    Terraform                                  = "true"
    ManagedBy                                  = "terraform"
    "kubernetes.io/role/internal-elb"          = "1"
    "kubernetes.io/cluster/${var.environment}" = "shared"
  }
}

resource "aws_subnet" "private_b" {
  vpc_id                  = var.vpc_id
  cidr_block              = var.private_subnet_b_cidr
  availability_zone       = var.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name                                       = "${var.environment}-private-subnet-b"
    Environment                                = var.environment
    Terraform                                  = "true"
    ManagedBy                                  = "terraform"
    "kubernetes.io/role/internal-elb"          = "1"
    "kubernetes.io/cluster/${var.environment}" = "shared"
  }
}

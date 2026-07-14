# RDS Module - PostgreSQL for Notes CRUD
# Free Tier: db.t3.micro, Single-AZ, 20GB gp3, private subnets

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  db_subnet_group_name = "${var.environment}-notes-crud-db-subnet-group"
  db_instance_name     = "${var.environment}-notes-crud-db"
}

# DB Subnet Group (required for private subnets)
resource "aws_db_subnet_group" "notes_crud" {
  name       = local.db_subnet_group_name
  subnet_ids = var.private_subnet_ids

  tags = merge(local.common_tags, {
    Name = local.db_subnet_group_name
  })
}

# RDS Instance
resource "aws_db_instance" "notes_crud" {
  identifier        = local.db_instance_name
  engine            = "postgres"
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage
  storage_type      = var.storage_type
  storage_encrypted = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = var.security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.notes_crud.name

  multi_az                = var.multi_az
  publicly_accessible     = var.publicly_accessible
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  skip_final_snapshot     = true # Free Tier: no final snapshot

  # Monitoring
  monitoring_interval = 60
  monitoring_role_arn = aws_iam_role.enhanced_monitoring.arn

  tags = merge(local.common_tags, {
    Name = local.db_instance_name
  })

  lifecycle {
    ignore_changes = [
      password,
    ]
  }
}

# IAM Role for Enhanced Monitoring
resource "aws_iam_role" "enhanced_monitoring" {
  name = "${var.environment}-rds-enhanced-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "monitoring.rds.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "enhanced_monitoring" {
  role       = aws_iam_role.enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
# ============================================================
# Dev Environment Variables - FREE TIER OPTIMIZED
# ============================================================

# Provider & Environment
aws_region     = "ap-south-1"
environment    = "dev"
owner          = "shahid"
aws_account_id = "265751833804"

# Network Configuration
vpc_cidr              = "10.0.0.0/16"
public_subnet_a_cidr  = "10.0.1.0/24"
public_subnet_b_cidr  = "10.0.2.0/24"
private_subnet_a_cidr = "10.0.11.0/24"
private_subnet_b_cidr = "10.0.12.0/24"

# NAT Gateway - DISABLED for Free Tier (saves ~$32/month)
enable_nat_gateway = false

# Security Configuration
app_port          = 3000
ssh_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict to your IP in production!

# IAM
cloudwatch_agent_s3_bucket = ""

# EC2 Launch Template (Free Tier: t3.micro)
instance_type                     = "t3.micro"
key_name                          = "notes_app"
node_version                      = "20"
enable_cloudwatch_agent           = true
enable_ssm_agent                  = true
root_volume_size                  = 20
root_volume_type                  = "gp3"
root_volume_delete_on_termination = true
root_volume_encrypted             = true
root_volume_kms_key_id            = ""
associate_public_ip               = true

# Application Code
github_repo   = "https://github.com/iamshahid102/AWS-3-project.git"
github_branch = "main"

# Domain & SSL - DISABLED for Free Tier (using ALB DNS instead)
domain_name    = ""
hosted_zone_id = ""
ssl_email      = "admin@localhost"

# Database (Free Tier: db.t3.micro)
db_name     = "notesdb"
db_username = "notesadmin"
db_password = "likh5245102"

# Disable standalone EC2 instance (using ASG instead)
create_instance = false
instance_name   = "notes-crud-dev"
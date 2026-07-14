# ============================================================
# Dev Environment Variables
# ============================================================

aws_region            = "ap-south-1"
environment           = "dev"
aws_account_id        = "123456789012" # Replace with your AWS Account ID
vpc_cidr              = "10.0.0.0/16"
public_subnet_a_cidr  = "10.0.1.0/24"
public_subnet_b_cidr  = "10.0.2.0/24"
private_subnet_a_cidr = "10.0.11.0/24"
private_subnet_b_cidr = "10.0.12.0/24"

# Security Group
app_port = 3000
# ssh_allowed_cidrs = ["YOUR_IP/32"]  # Replace YOUR_IP with `curl ifconfig.me` output
# Example: ssh_allowed_cidrs = ["203.0.113.42/32"]
ssh_allowed_cidrs = ["0.0.0.0/0"] # TODO: Restrict to your IP only!

# IAM
cloudwatch_agent_s3_bucket = ""

# NAT Gateway - DISABLE for Free Tier (costs ~$45/month)
enable_nat_gateway = false

# EC2 Launch Template
instance_type                     = "t3.micro"
key_name                          = ""
node_version                      = "20"
enable_cloudwatch_agent           = true
enable_ssm_agent                  = true
root_volume_size                  = 20
root_volume_type                  = "gp3"
root_volume_delete_on_termination = true
root_volume_encrypted             = true
root_volume_kms_key_id            = ""
associate_public_ip               = true
github_repo                       = "https://github.com/iamshahid102/AWS-Architecture.git"
github_branch                     = "main"

# Disable standalone EC2 instance (use ASG instead)
create_instance = false
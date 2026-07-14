# ============================================================
# EC2 Module - Launch Template for Notes CRUD Application
# ============================================================

locals {
  common_tags = {
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "terraform"
    Owner       = var.owner
  }

  launch_template_name = "${var.environment}-notes-crud-lt-v2"
}

# -----------------------------------------------------------
# Data Source: Custom Notes CRUD AMI (built by Packer)
# Falls back to Ubuntu 24.04 LTS if custom AMI not found
# -----------------------------------------------------------
data "aws_ami" "notes_crud_custom" {
  count       = 1
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "tag:Project"
    values = ["notes-crud"]
  }

  filter {
    name   = "tag:ManagedBy"
    values = ["packer"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

data "aws_ami" "ubuntu_2404" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["*ubuntu*noble*24.04*amd64*server*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------
# User Data Template
# Renders userdata.sh with variable interpolation using templatefile()
# -----------------------------------------------------------
locals {
  # Use custom AMI if available, otherwise fall back to Ubuntu 24.04
  ami_id = try(data.aws_ami.notes_crud_custom[0].id, data.aws_ami.ubuntu_2404.id)

  user_data = templatefile("${path.module}/userdata.sh", {
    environment                = var.environment
    app_port                   = var.app_port
    node_version               = var.node_version
    enable_cloudwatch_agent    = var.enable_cloudwatch_agent
    enable_ssm_agent           = var.enable_ssm_agent
    aws_region                 = var.aws_region
    cloudwatch_agent_s3_bucket = var.cloudwatch_agent_s3_bucket
    github_repo                = var.github_repo
    github_branch              = var.github_branch
    domain_name                = var.domain_name
    ssl_email                  = var.ssl_email
    db_host                    = var.db_host
    db_port                    = var.db_port
    db_user                    = var.db_user
    db_password                = var.db_password
    db_name                    = var.db_name
  })
}

# -----------------------------------------------------------
# Launch Template
# Used by Auto Scaling Group (created in later phase)
# -----------------------------------------------------------
resource "aws_launch_template" "notes_crud" {
  name_prefix   = local.launch_template_name
  description   = "Launch template for Notes CRUD Application (${var.environment}) - v2"
  image_id      = local.ami_id
  instance_type = var.instance_type
  key_name      = var.key_name

  iam_instance_profile {
    arn = var.instance_profile_arn
  }

  user_data = base64encode(local.user_data)

  update_default_version = true

  network_interfaces {
    security_groups = var.security_group_ids
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = var.root_volume_encrypted
      kms_key_id            = var.root_volume_kms_key_id != "" ? var.root_volume_kms_key_id : null
      delete_on_termination = var.root_volume_delete_on_termination
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(local.common_tags, {
      Name = "${var.environment}-notes-crud-instance"
      Role = "application"
    })
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(local.common_tags, {
      Name = "${var.environment}-notes-crud-root-volume"
    })
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------
# EC2 Instance (optional - for dev environments without ASG)
# Uses the launch template above
# -----------------------------------------------------------
resource "aws_instance" "notes_crud" {
  count = var.create_instance ? 1 : 0

  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip

  launch_template {
    id      = aws_launch_template.notes_crud.id
    version = aws_launch_template.notes_crud.latest_version
  }

  tags = merge(local.common_tags, {
    Name = var.instance_name != "" ? var.instance_name : "${var.environment}-notes-crud-instance"
    Role = "application"
  })
}

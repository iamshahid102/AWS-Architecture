packer {
  required_plugins {
    amazon = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "ap-south-1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "source_ami_filter" {
  type = object({
    name      = string
    owners    = list(string)
    most_recent = bool
  })
  default = {
    name      = "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"
    owners    = ["099720109477"]
    most_recent = true
  }
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "vpc_id" {
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}

variable "security_group_id" {
  type    = string
  default = ""
}

variable "app_port" {
  type    = number
  default = 3000
}

variable "node_version" {
  type    = string
  default = "20"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "domain_name" {
  type    = string
  default = ""
}

variable "ssl_email" {
  type    = string
  default = "admin@localhost"
}

variable "enable_cloudwatch_agent" {
  type    = bool
  default = true
}

variable "enable_ssm_agent" {
  type    = bool
  default = true
}

variable "github_repo" {
  type    = string
  default = ""
}

variable "github_branch" {
  type    = string
  default = "main"
}

locals {
  timestamp          = formatdate("YYYYMMDDHHmmss", timestamp())
  ami_name           = "notes-crud-${var.environment}-${local.timestamp}"
  ami_description    = "Notes CRUD AMI with Nginx reverse proxy, Node.js ${var.node_version}, PM2, Certbot - ${var.environment}"
  tags = {
    Name        = local.ami_name
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "packer"
    Owner       = "platform-team"
    BuildTime   = local.timestamp
  }
}

source "amazon-ebs" "notes_crud" {
  region                   = var.aws_region
  instance_type            = var.instance_type
  source_ami_filter        = var.source_ami_filter
  ssh_username             = var.ssh_username
  ami_name                 = local.ami_name
  ami_description          = local.ami_description
  tags                     = local.tags
  vpc_id                   = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                = var.subnet_id != "" ? var.subnet_id : null
  security_group_id        = var.security_group_id != "" ? var.security_group_id : null
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
    delete_on_termination = true
  }
}

build {
  sources = ["source.amazon-ebs.notes_crud"]

  provisioner "shell" {
    inline = [
      "echo '=== Starting Notes CRUD AMI Build ==='",
      "echo 'Timestamp: ${local.timestamp}'",
      "echo 'Environment: ${var.environment}'",
      "echo 'App Port: ${var.app_port}'",
      "echo 'Node Version: ${var.node_version}'",
      "export DEBIAN_FRONTEND=noninteractive",
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y curl wget gnupg lsb-release ca-certificates software-properties-common unzip jq git"
    ]
  }

  provisioner "shell" {
    script = "./scripts/install-nodejs.sh"
    env_vars = [
      "NODE_VERSION=${var.node_version}"
    ]
  }

  provisioner "shell" {
    script = "./scripts/install-pm2.sh"
  }

  provisioner "shell" {
    script = "./scripts/install-nginx-certbot.sh"
  }

  provisioner "shell" {
    script = "./scripts/configure-nginx.sh"
    env_vars = [
      "APP_PORT=${var.app_port}",
      "DOMAIN_NAME=${var.domain_name}",
      "SSL_EMAIL=${var.ssl_email}"
    ]
  }

  provisioner "shell" {
    script = "./scripts/setup-app-directory.sh"
    env_vars = [
      "APP_PORT=${var.app_port}",
      "GITHUB_REPO=${var.github_repo}",
      "GITHUB_BRANCH=${var.github_branch}"
    ]
  }

  provisioner "shell" {
    script = "./scripts/install-cloudwatch-agent.sh"
    env_vars = [
      "ENABLE_CLOUDWATCH_AGENT=${var.enable_cloudwatch_agent}",
      "ENVIRONMENT=${var.environment}"
    ]
  }

  provisioner "shell" {
    script = "./scripts/install-ssm-agent.sh"
    env_vars = [
      "ENABLE_SSM_AGENT=${var.enable_ssm_agent}"
    ]
  }

  provisioner "shell" {
    script = "./scripts/finalize-ami.sh"
    env_vars = [
      "DOMAIN_NAME=${var.domain_name}",
      "SSL_EMAIL=${var.ssl_email}"
    ]
  }

  post-processor "manifest" {
    output = "manifest.json"
    strip_path = true
  }
}
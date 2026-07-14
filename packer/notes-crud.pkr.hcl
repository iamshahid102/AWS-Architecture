packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1.0"
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

variable "domain_name" {
  type    = string
  default = ""
}

variable "ssl_email" {
  type    = string
  default = "admin@localhost"
}

variable "environment" {
  type    = string
  default = "dev"
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
  timestamp = formatdate("YYYYMMDDHHmmss", timestamp())
  ami_name  = "notes-crud-${var.environment}-${local.timestamp}"
}

source "amazon-ebs" "notes_crud" {
  region                   = var.aws_region
  instance_type            = var.instance_type
  ssh_username             = var.ssh_username
  vpc_id                   = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                = var.subnet_id != "" ? var.subnet_id : null
  security_group_id        = var.security_group_id != "" ? var.security_group_id : null
  source_ami_filter {
    filters = {
      name                = "*ubuntu*noble*24.04*amd64*server*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
      architecture        = "x86_64"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  ami_name                 = local.ami_name
  ami_description          = "Notes CRUD AMI - Node.js ${var.node_version}, Nginx, PM2, CloudWatch, SSM - ${var.environment}"

  ami_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp3"
    encrypted   = false
    delete_on_termination = true
  }

  tags = {
    Name        = local.ami_name
    Environment = var.environment
    Project     = "notes-crud"
    ManagedBy   = "packer"
    NodeVersion = var.node_version
  }

  run_tags = {
    Name        = "packer-build-${local.ami_name}"
    Environment = var.environment
    Project     = "notes-crud"
  }
}

build {
  name    = "notes-crud"
  sources = ["source.amazon-ebs.notes_crud"]

  # ==========================================
  # System Packages
  # ==========================================
  provisioner "shell" {
    inline = [
      "echo '=========================================='",
      "echo 'Starting Notes CRUD AMI Build'",
      "echo 'Timestamp: $(date)'",
      "echo '=========================================='"
    ]
  }

  provisioner "shell" {
    inline = [
      "export DEBIAN_FRONTEND=noninteractive",
      "sudo apt-get update -y",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y curl wget gnupg lsb-release ca-certificates software-properties-common unzip jq git nginx"
    ]
  }

  # ==========================================
  # Node.js + PM2
  # ==========================================
  provisioner "shell" {
    inline = [
      "curl -fsSL https://deb.nodesource.com/setup_${var.node_version}.x | sudo bash -",
      "sudo apt-get install -y nodejs",
      "sudo npm install -g pm2@latest"
    ]
  }

  provisioner "shell" {
    inline = [
      "sudo pm2 startup systemd -u ubuntu --hp /home/ubuntu 2>&1 || true",
      "sudo pm2 save || true"
    ]
  }

  # ==========================================
  # CloudWatch Agent
  # ==========================================
  provisioner "shell" {
    inline = [
      "cd /tmp",
      "wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "sudo dpkg -i -E ./amazon-cloudwatch-agent.deb",
      "rm -f ./amazon-cloudwatch-agent.deb",
      "sudo tee /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG' > /dev/null",
      "{",
      "  \"agent\": { \"metrics_collection_interval\": 60, \"run_as_user\": \"root\" },",
      "  \"logs\": {",
      "    \"logs_collected\": {",
      "      \"files\": {",
      "        \"collect_list\": [",
      "          { \"file_path\": \"/var/log/user-data.log\", \"log_group_name\": \"/aws/ec2/${var.environment}/user-data\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 },",
      "          { \"file_path\": \"/home/ubuntu/notes-crud/logs/*.log\", \"log_group_name\": \"/aws/ec2/${var.environment}/notes-crud\", \"log_stream_name\": \"{instance_id}\", \"retention_in_days\": 30 }",
      "        ]",
      "      }",
      "    }",
      "  },",
      "  \"metrics\": {",
      "    \"namespace\": \"NotesCRUD/EC2\",",
      "    \"metrics_collected\": {",
      "      \"cpu\": { \"measurement\": [\"cpu_usage_idle\", \"cpu_usage_user\"], \"metrics_collection_interval\": 60, \"resources\": [\"*\"], \"totalcpu\": false },",
      "      \"mem\": { \"measurement\": [\"mem_used_percent\"], \"metrics_collection_interval\": 60 },",
      "      \"disk\": { \"measurement\": [\"used_percent\"], \"metrics_collection_interval\": 60, \"resources\": [\"/\"] }",
      "    }",
      "  }",
      "}",
      "CWCONFIG",
      "sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
      "sudo systemctl enable amazon-cloudwatch-agent"
    ]
  }

  # ==========================================
  # SSM Agent
  # ==========================================
  provisioner "shell" {
    inline = [
      "sudo snap install amazon-ssm-agent --classic",
      "sudo systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent"
    ]
  }

  # ==========================================
  # Nginx Configuration (HTTP-only for Free Tier)
  # ==========================================
  provisioner "shell" {
    inline = [
      "sudo tee /etc/nginx/nginx.conf << 'NGINXCONF' > /dev/null",
      "user www-data;",
      "worker_processes auto;",
      "pid /run/nginx.pid;",
      "include /etc/nginx/modules-enabled/*.conf;",
      "",
      "events {",
      "    worker_connections 1024;",
      "    multi_accept on;",
      "    use epoll;",
      "}",
      "",
      "http {",
      "    sendfile on;",
      "    tcp_nopush on;",
      "    tcp_nodelay on;",
      "    keepalive_timeout 65;",
      "    types_hash_max_size 2048;",
      "    server_tokens off;",
      "",
      "    include /etc/nginx/mime.types;",
      "    default_type application/octet-stream;",
      "",
      "    gzip on;",
      "    gzip_vary on;",
      "    gzip_proxied any;",
      "    gzip_comp_level 5;",
      "    gzip_min_length 256;",
      "    gzip_types application/javascript application/json text/css text/xml;",
      "",
      "    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;",
      "",
      "    add_header X-Frame-Options \"SAMEORIGIN\" always;",
      "    add_header X-Content-Type-Options \"nosniff\" always;",
      "    add_header X-XSS-Protection \"1; mode=block\" always;",
      "",
      "    log_format main '$remote_addr - $remote_user [$time_local] \"$request\" '",
      "                    '$status $body_bytes_sent \"$http_referer\" '",
      "                    '\"$http_user_agent\" \"$http_x_forwarded_for\"';",
      "",
      "    access_log /var/log/nginx/access.log main;",
      "    error_log /var/log/nginx/error.log warn;",
      "",
      "    include /etc/nginx/conf.d/*.conf;",
      "    include /etc/nginx/sites-enabled/*;",
      "}",
      "NGINXCONF",
      "",
      "# HTTP-only site config (no SSL needed for Free Tier ALB access)",
      "sudo tee /etc/nginx/sites-available/notes-crud << 'SITECONF' > /dev/null",
      "server {",
      "    listen 80;",
      "    server_name _;",
      "",
      "    # Health check for ALB target group",
      "    location /health {",
      "        proxy_pass http://127.0.0.1:${var.app_port};",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "        access_log off;",
      "    }",
      "",
      "    # Frontend static files",
      "    location /css/ {",
      "        alias /home/ubuntu/notes-crud/frontend/css/;",
      "        expires 1y;",
      "        add_header Cache-Control \"public, immutable\";",
      "        access_log off;",
      "    }",
      "",
      "    location /js/ {",
      "        alias /home/ubuntu/notes-crud/frontend/js/;",
      "        expires 1y;",
      "        add_header Cache-Control \"public, immutable\";",
      "        access_log off;",
      "    }",
      "",
      "    # API proxy to Node.js backend",
      "    location /api/ {",
      "        proxy_pass http://127.0.0.1:${var.app_port};",
      "        proxy_http_version 1.1;",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "        proxy_cache_bypass $http_upgrade;",
      "    }",
      "",
      "    # Frontend index.html (SPA entry point)",
      "    location / {",
      "        root /home/ubuntu/notes-crud/frontend;",
      "        index index.html;",
      "        try_files $uri $uri/ /index.html;",
      "    }",
      "}",
      "SITECONF",
      "",
      "sudo ln -sf /etc/nginx/sites-available/notes-crud /etc/nginx/sites-enabled/",
      "sudo rm -f /etc/nginx/sites-enabled/default",
      "sudo nginx -t",
      "echo 'Nginx configured in HTTP-only mode.'"
    ]
  }

  # ==========================================
  # Application Directory Setup
  # ==========================================
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /home/ubuntu/notes-crud",
      "sudo mkdir -p /home/ubuntu/notes-crud/logs",
      "sudo mkdir -p /home/ubuntu/notes-crud/frontend",
      "sudo mkdir -p /home/ubuntu/notes-crud/backend",
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/notes-crud"
    ]
  }

  # ==========================================
  # Upload Application Files (from local project)
  # Baking backend/ and frontend/ directly into AMI
  # No GitHub clone needed - repo may be private
  # ==========================================
  provisioner "file" {
    source      = "${path.cwd}/../backend/"
    destination = "/home/ubuntu/notes-crud/backend/"
  }

  provisioner "file" {
    source      = "${path.cwd}/../frontend/"
    destination = "/home/ubuntu/notes-crud/frontend/"
  }

  provisioner "shell" {
    inline = [
      "sudo chown -R ubuntu:ubuntu /home/ubuntu/notes-crud",
      "# Fix permissions for Nginx (runs as www-data)",
      "sudo chmod o+x /home/ubuntu",
      "sudo chmod -R o+rX /home/ubuntu/notes-crud",
      "echo \"Application files uploaded: $(ls /home/ubuntu/notes-crud/backend/src/server.js 2>/dev/null && echo OK || echo MISSING)\""
    ]
  }

  # ==========================================
  # PM2 Ecosystem Config (baked into AMI)
  # ==========================================
  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/ecosystem.config.js << 'ECOSYSTEM'",
      "module.exports = {",
      "  apps: [{",
      "    name: 'notes-crud',",
      "    script: 'src/server.js',",
      "    cwd: '/home/ubuntu/notes-crud/backend',",
      "    instances: 1,",
      "    exec_mode: 'fork',",
      "    env: {",
      "      NODE_ENV: 'production',",
      "      PORT: ${var.app_port}",
      "    },",
      "    env_production: {",
      "      NODE_ENV: 'production',",
      "      PORT: ${var.app_port}",
      "    },",
      "    error_file: '/home/ubuntu/notes-crud/logs/err.log',",
      "    out_file: '/home/ubuntu/notes-crud/logs/out.log',",
      "    log_file: '/home/ubuntu/notes-crud/logs/combined.log',",
      "    time: true,",
      "    max_memory_restart: '500M',",
      "    restart_delay: 5000,",
      "    max_restarts: 10,",
      "    min_uptime: '10s',",
      "    watch: false,",
      "    kill_timeout: 5000,",
      "    wait_ready: true,",
      "    listen_timeout: 8000",
      "  }]",
      "};",
      "ECOSYSTEM",
      "sudo chown ubuntu:ubuntu /home/ubuntu/notes-crud/ecosystem.config.js"
    ]
  }

  # ==========================================
  # Start Script
  # ==========================================
  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/start.sh << 'STARTSCRIPT'",
      "#!/bin/bash",
      "set -e",
      "",
      "cd /home/ubuntu/notes-crud",
      "",
      "echo \"Starting Notes CRUD Application...\"",
      "echo \"Backend files: $(ls /home/ubuntu/notes-crud/backend/src/server.js 2>/dev/null && echo OK || echo MISSING)\"",
      "echo \"Frontend files: $(ls /home/ubuntu/notes-crud/frontend/index.html 2>/dev/null && echo OK || echo MISSING)\"",
      "",
      "# Install npm dependencies",
      "if [ -f \"/home/ubuntu/notes-crud/backend/package.json\" ]; then",
      "    echo \"Installing npm dependencies...\"",
      "    cd /home/ubuntu/notes-crud/backend",
      "    npm ci --production || npm install --production",
      "fi",
      "",
      "# Start PM2",
      "pm2 start /home/ubuntu/notes-crud/ecosystem.config.js --env production",
      "pm2 save",
      "",
      "echo \"Application started!\"",
      "STARTSCRIPT",
      "chmod +x /home/ubuntu/notes-crud/start.sh",
      "sudo chown ubuntu:ubuntu /home/ubuntu/notes-crud/start.sh"
    ]
  }

  # ==========================================
  # Health Check Script
  # ==========================================
  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/health.sh << 'HEALTHSCRIPT'",
      "#!/bin/bash",
      "curl -sf http://localhost:${var.app_port}/health > /dev/null 2>&1",
      "exit $?",
      "HEALTHSCRIPT",
      "chmod +x /home/ubuntu/notes-crud/health.sh",
      "sudo chown ubuntu:ubuntu /home/ubuntu/notes-crud/health.sh"
    ]
  }

  # ==========================================
  # Log Rotation + System Tuning
  # ==========================================
  provisioner "shell" {
    inline = [
      "sudo tee /etc/logrotate.d/notes-crud << 'LOGROTATE' > /dev/null",
      "/home/ubuntu/notes-crud/logs/*.log {",
      "    daily",
      "    missingok",
      "    rotate 14",
      "    compress",
      "    delaycompress",
      "    notifempty",
      "    create 0640 ubuntu ubuntu",
      "    sharedscripts",
      "    postrotate",
      "        pm2 reloadLogs > /dev/null 2>&1 || true",
      "    endscript",
      "}",
      "LOGROTATE",
      "",
      "sudo tee -a /etc/security/limits.conf << 'LIMITS'",
      "ubuntu soft nofile 65536",
      "ubuntu hard nofile 65536",
      "LIMITS",
      "",
      "sudo tee /etc/sysctl.d/99-notes-crud.conf << 'SYSCTL'",
      "net.core.somaxconn = 65535",
      "net.ipv4.tcp_fin_timeout = 15",
      "net.ipv4.tcp_tw_reuse = 1",
      "vm.swappiness = 10",
      "SYSCTL",
      "",
      "sudo sysctl --system",
      "",
      "echo \"System limits configured.\""
    ]
  }

  # ==========================================
  # Final Summary
  # ==========================================
  provisioner "shell" {
    inline = [
      "echo \"==========================================\"",
      "echo \"AMI Build Complete!\"",
      "echo \"Timestamp: $(date)\"",
      "echo \"==========================================\"",
      "echo \"Installed Versions:\"",
      "echo \"  Node.js: $(node --version)\"",
      "echo \"  NPM: $(npm --version)\"",
      "echo \"  PM2: $(pm2 --version)\"",
      "echo \"  Nginx: $(nginx -v 2>&1)\"",
      "echo \"Application Directory: /home/ubuntu/notes-crud\"",
      "echo \"==========================================\""
    ]
  }

  post-processor "manifest" {
    output     = "manifest.json"
    strip_path = true
  }
}

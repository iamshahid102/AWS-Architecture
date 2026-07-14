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
  base_ami_filter = {
    name   = "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"
    values = ["ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*"]
  }
}

source "amazon-ebs" "notes_crud" {
  region                   = var.aws_region
  instance_type            = var.instance_type
  ssh_username             = var.ssh_username
  vpc_id                   = var.vpc_id != "" ? var.vpc_id : null
  subnet_id                = var.subnet_id != "" ? var.subnet_id : null
  security_group_id        = var.security_group_id != "" ? var.security_group_id : null
  ami_name                 = local.ami_name
  ami_description          = "Notes CRUD Application AMI - Node.js ${var.node_version}, Nginx, PM2, Certbot - ${var.environment}"
  ami_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
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

  provisioner "shell" {
    inline = [
      "echo '=========================================='",
      "echo 'Starting Notes CRUD AMI Build'",
      "echo 'Timestamp: $(date)'",
      "echo '=========================================='",
      "echo 'Configuration:'",
      "echo '  App Port: ${var.app_port}'",
      "echo '  Environment: ${var.environment}'",
      "echo '  Node Version: ${var.node_version}'",
      "echo '  Domain: ${var.domain_name != \"\" ? var.domain_name : \"none (self-signed)\"}'",
      "echo '  SSL Email: ${var.ssl_email}'",
      "echo '  GitHub Repo: ${var.github_repo != \"\" ? var.github_repo : \"none\"}'"
    ]
  }

  provisioner "shell" {
    inline = [
      "apt-get update -y",
      "apt-get upgrade -y",
      "apt-get install -y curl wget gnupg lsb-release ca-certificates software-properties-common unzip jq git"
    ]
  }

  provisioner "shell" {
    inline = [
      "curl -fsSL https://deb.nodesource.com/setup_${var.node_version}.x | bash -",
      "apt-get install -y nodejs",
      "node --version",
      "npm --version",
      "npm install -g pm2@latest",
      "pm2 --version"
    ]
  }

  provisioner "shell" {
    inline = [
      "PM2_STARTUP_CMD=$(pm2 startup systemd -u ubuntu --hp /home/ubuntu 2>&1 | tail -1)",
      "echo \"PM2 startup command: $PM2_STARTUP_CMD\"",
      "eval \"$PM2_STARTUP_CMD\"",
      "pm2 save"
    ]
  }

  provisioner "shell" {
    inline = [
      "cd /tmp",
      "wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "dpkg -i -E ./amazon-cloudwatch-agent.deb",
      "rm -f ./amazon-cloudwatch-agent.deb",
      "cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWCONFIG'",
      "{",
      "  \"agent\": {",
      "    \"metrics_collection_interval\": 60,",
      "    \"run_as_user\": \"root\"",
      "  },",
      "  \"logs\": {",
      "    \"logs_collected\": {",
      "      \"files\": {",
      "        \"collect_list\": [",
      "          {",
      "            \"file_path\": \"/var/log/user-data.log\",",
      "            \"log_group_name\": \"/aws/ec2/${var.environment}/user-data\",",
      "            \"log_stream_name\": \"{instance_id}\",",
      "            \"retention_in_days\": 30",
      "          },",
      "          {",
      "            \"file_path\": \"/home/ubuntu/notes-crud/logs/*.log\",",
      "            \"log_group_name\": \"/aws/ec2/${var.environment}/notes-crud\",",
      "            \"log_stream_name\": \"{instance_id}\",",
      "            \"retention_in_days\": 30",
      "          },",
      "          {",
      "            \"file_path\": \"/var/log/syslog\",",
      "            \"log_group_name\": \"/aws/ec2/${var.environment}/syslog\",",
      "            \"log_stream_name\": \"{instance_id}\",",
      "            \"retention_in_days\": 14",
      "          }",
      "        ]",
      "      }",
      "    }",
      "  },",
      "  \"metrics\": {",
      "    \"namespace\": \"NotesCRUD/EC2\",",
      "    \"metrics_collected\": {",
      "      \"cpu\": {",
      "        \"measurement\": [\"cpu_usage_idle\", \"cpu_usage_iowait\", \"cpu_usage_user\", \"cpu_usage_system\"],",
      "        \"metrics_collection_interval\": 60,",
      "        \"resources\": [\"*\"],",
      "        \"totalcpu\": false",
      "      },",
      "      \"disk\": {",
      "        \"measurement\": [\"used_percent\", \"inodes_free\"],",
      "        \"metrics_collection_interval\": 60,",
      "        \"resources\": [\"/\"],",
      "        \"ignore_file_system_types\": [\"sysfs\", \"devtmpfs\"]",
      "      },",
      "      \"diskio\": {",
      "        \"measurement\": [\"reads\", \"writes\", \"read_bytes\", \"write_bytes\", \"read_time\", \"write_time\"],",
      "        \"metrics_collection_interval\": 60,",
      "        \"resources\": [\"*\"]",
      "      },",
      "      \"mem\": {",
      "        \"measurement\": [\"mem_used_percent\", \"mem_available\", \"mem_total\"],",
      "        \"metrics_collection_interval\": 60",
      "      },",
      "      \"netstat\": {",
      "        \"measurement\": [\"tcp_established\", \"tcp_time_wait\"],",
      "        \"metrics_collection_interval\": 60",
      "      },",
      "      \"swap\": {",
      "        \"measurement\": [\"swap_used_percent\"],",
      "        \"metrics_collection_interval\": 60",
      "      }",
      "    }",
      "  }",
      "}",
      "CWCONFIG",
      "/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s",
      "systemctl enable amazon-cloudwatch-agent"
    ]
  }

  provisioner "shell" {
    inline = [
      "snap install amazon-ssm-agent --classic",
      "systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent",
      "systemctl start snap.amazon-ssm-agent.amazon-ssm-agent"
    ]
  }

  provisioner "shell" {
    inline = [
      "apt-get install -y nginx certbot python3-certbot-nginx",
      "systemctl stop nginx 2>/dev/null || true"
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /etc/nginx/nginx.conf << 'NGINXCONF'",
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
      "    # Gzip Compression",
      "    gzip on;",
      "    gzip_vary on;",
      "    gzip_proxied any;",
      "    gzip_comp_level 5;",
      "    gzip_min_length 256;",
      "    gzip_types",
      "        application/atom+xml",
      "        application/geo+json",
      "        application/javascript",
      "        application/x-javascript",
      "        application/json",
      "        application/ld+json",
      "        application/manifest+json",
      "        application/rdf+xml",
      "        application/rss+xml",
      "        application/xhtml+xml",
      "        application/xml",
      "        font/eot",
      "        font/otf",
      "        font/ttf",
      "        image/svg+xml",
      "        text/css",
      "        text/javascript",
      "        text/plain",
      "        text/xml;",
      "",
      "    # Rate Limiting",
      "    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;",
      "    limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;",
      "",
      "    # Upstream Node.js app",
      "    upstream notes_crud_backend {",
      "        least_conn;",
      "        server 127.0.0.1:${var.app_port} max_fails=3 fail_timeout=30s;",
      "        keepalive 32;",
      "    }",
      "",
      "    # Security Headers",
      "    add_header X-Frame-Options \"SAMEORIGIN\" always;",
      "    add_header X-Content-Type-Options \"nosniff\" always;",
      "    add_header X-XSS-Protection \"1; mode=block\" always;",
      "    add_header Referrer-Policy \"strict-origin-when-cross-origin\" always;",
      "    add_header Permissions-Policy \"geolocation=(), microphone=(), camera=()\" always;",
      "",
      "    # HSTS (enable only after HTTPS works)",
      "    # add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;",
      "",
      "    log_format main '$remote_addr - $remote_user [$time_local] \"$request\" '",
      "                    '$status $body_bytes_sent \"$http_referer\" '",
      "                    '\"$http_user_agent\" \"$http_x_forwarded_for\" '",
      "                    'rt=$request_time uct=\"$upstream_connect_time\" '",
      "                    'uht=\"$upstream_header_time\" urt=\"$upstream_response_time\"';",
      "",
      "    access_log /var/log/nginx/access.log main;",
      "    error_log /var/log/nginx/error.log warn;",
      "",
      "    include /etc/nginx/conf.d/*.conf;",
      "    include /etc/nginx/sites-enabled/*;",
      "}",
      "NGINXCONF"
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /etc/nginx/sites-available/notes-crud << 'SITECONF'",
      "# HTTP server - redirect to HTTPS + serve ACME challenges",
      "server {",
      "    listen 80;",
      "    listen [::]:80;",
      "    server_name ${var.domain_name != \"\" ? var.domain_name : \"_\"};",
      "",
      "    # ACME challenge location for Let's Encrypt",
      "    location /.well-known/acme-challenge/ {",
      "        root /var/www/certbot;",
      "        allow all;",
      "    }",
      "",
      "    # Health check endpoint (allow HTTP for ALB/target group health checks)",
      "    location /health {",
      "        proxy_pass http://notes_crud_backend;",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "        access_log off;",
      "    }",
      "",
      "    # Redirect all other traffic to HTTPS",
      "    location / {",
      "        return 301 https://$host$request_uri;",
      "    }",
      "}",
      "",
      "# HTTPS server - main configuration",
      "server {",
      "    listen 443 ssl http2;",
      "    listen [::]:443 ssl http2;",
      "    server_name ${var.domain_name != \"\" ? var.domain_name : \"_\"};",
      "",
      "    # SSL certificates (Certbot will populate these paths)",
      "    ssl_certificate /etc/letsencrypt/live/${var.domain_name != \"\" ? var.domain_name : \"_\"}/fullchain.pem;",
      "    ssl_certificate_key /etc/letsencrypt/live/${var.domain_name != \"\" ? var.domain_name : \"_\"}/privkey.pem;",
      "",
      "    # SSL Security Configuration",
      "    ssl_protocols TLSv1.2 TLSv1.3;",
      "    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;",
      "    ssl_prefer_server_ciphers off;",
      "    ssl_session_cache shared:SSL:10m;",
      "    ssl_session_timeout 10m;",
      "    ssl_session_tickets off;",
      "",
      "    # OCSP Stapling",
      "    ssl_stapling on;",
      "    ssl_stapling_verify on;",
      "    resolver 8.8.8.8 8.8.4.4 valid=300s;",
      "    resolver_timeout 5s;",
      "",
      "    # Security Headers (additional for HTTPS)",
      "    add_header Strict-Transport-Security \"max-age=31536000; includeSubDomains\" always;",
      "",
      "    # Static files - serve directly with caching",
      "    location /static/ {",
      "        alias /home/ubuntu/notes-crud/public/;",
      "        expires 1y;",
      "        add_header Cache-Control \"public, immutable\";",
      "        access_log off;",
      "        try_files $uri $uri/ =404;",
      "    }",
      "",
      "    location /assets/ {",
      "        alias /home/ubuntu/notes-crud/public/assets/;",
      "        expires 1y;",
      "        add_header Cache-Control \"public, immutable\";",
      "        access_log off;",
      "        try_files $uri $uri/ =404;",
      "    }",
      "",
      "    # Favicon, robots.txt, etc.",
      "    location = /favicon.ico {",
      "        alias /home/ubuntu/notes-crud/public/favicon.ico;",
      "        expires 1y;",
      "        add_header Cache-Control \"public, immutable\";",
      "        access_log off;",
      "    }",
      "",
      "    location = /robots.txt {",
      "        alias /home/ubuntu/notes-crud/public/robots.txt;",
      "        expires 1d;",
      "        add_header Cache-Control \"public\";",
      "        access_log off;",
      "    }",
      "",
      "    # API routes - rate limited, proxied to Node.js",
      "    location /api/ {",
      "        limit_req zone=api burst=20 nodelay;",
      "        limit_req_status 429;",
      "",
      "        proxy_pass http://notes_crud_backend;",
      "        proxy_http_version 1.1;",
      "        proxy_set_header Upgrade $http_upgrade;",
      "        proxy_set_header Connection 'upgrade';",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "        proxy_cache_bypass $http_upgrade;",
      "",
      "        # Timeouts",
      "        proxy_connect_timeout 5s;",
      "        proxy_send_timeout 30s;",
      "        proxy_read_timeout 30s;",
      "",
      "        # Buffer settings",
      "        proxy_buffering on;",
      "        proxy_buffer_size 4k;",
      "        proxy_buffers 8 4k;",
      "    }",
      "",
      "    # Auth endpoints - stricter rate limiting",
      "    location ~ ^/api/(auth|login|register) {",
      "        limit_req zone=login burst=5 nodelay;",
      "        limit_req_status 429;",
      "",
      "        proxy_pass http://notes_crud_backend;",
      "        proxy_http_version 1.1;",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "    }",
      "",
      "    # Main application - proxy to Node.js",
      "    location / {",
      "        proxy_pass http://notes_crud_backend;",
      "        proxy_http_version 1.1;",
      "        proxy_set_header Upgrade $http_upgrade;",
      "        proxy_set_header Connection 'upgrade';",
      "        proxy_set_header Host $host;",
      "        proxy_set_header X-Real-IP $remote_addr;",
      "        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;",
      "        proxy_set_header X-Forwarded-Proto $scheme;",
      "        proxy_cache_bypass $http_upgrade;",
      "",
      "        # Timeouts",
      "        proxy_connect_timeout 5s;",
      "        proxy_send_timeout 60s;",
      "        proxy_read_timeout 60s;",
      "",
      "        # WebSocket support",
      "        proxy_set_header Upgrade $http_upgrade;",
      "        proxy_set_header Connection \"upgrade\";",
      "    }",
      "",
      "    # Deny access to hidden files",
      "    location ~ /\\.(?!well-known) {",
      "        deny all;",
      "        access_log off;",
      "        log_not_found off;",
      "    }",
      "",
      "    # Deny access to backup/config files",
      "    location ~* \\.(bak|config|sql|fla|psd|ini|log|sh|inc|swp|dist)$ {",
      "        deny all;",
      "        access_log off;",
      "        log_not_found off;",
      "    }",
      "}",
      "SITECONF"
    ]
  }

  provisioner "shell" {
    inline = [
      "ln -sf /etc/nginx/sites-available/notes-crud /etc/nginx/sites-enabled/",
      "rm -f /etc/nginx/sites-enabled/default",
      "mkdir -p /var/www/certbot",
      "nginx -t",
      "echo 'Nginx configuration written successfully.'"
    ]
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /home/ubuntu/notes-crud",
      "mkdir -p /home/ubuntu/notes-crud/logs",
      "mkdir -p /home/ubuntu/notes-crud/public",
      "chown -R ubuntu:ubuntu /home/ubuntu/notes-crud"
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/ecosystem.config.js << 'ECOSYSTEM'",
      "module.exports = {",
      "  apps: [{",
      "    name: 'notes-crud',",
      "    script: 'server.js',",
      "    cwd: '/home/ubuntu/notes-crud',",
      "    instances: 'max',",
      "    exec_mode: 'cluster',",
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
      "    ignore_watch: ['logs', 'node_modules'],",
      "    kill_timeout: 5000,",
      "    wait_ready: true,",
      "    listen_timeout: 8000",
      "  }]",
      "};",
      "ECOSYSTEM",
      "chown ubuntu:ubuntu /home/ubuntu/notes-crud/ecosystem.config.js"
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/start.sh << 'STARTSCRIPT'",
      "#!/bin/bash",
      "set -e",
      "",
      "cd /home/ubuntu/notes-crud",
      "",
      "echo \"Starting Notes CRUD Application...\"",
      "echo \"Environment: $${ENVIRONMENT:-production}\"",
      "echo \"Port: $${PORT:-${var.app_port}}\"",
      "",
      "# Clone repository if provided and directory is empty",
      "if [ -n \"$${GITHUB_REPO:-}\" ] && [ -z \"$(ls -A /home/ubuntu/notes-crud 2>/dev/null || true)\" ]; then",
      "    echo \"Cloning repository...\"",
      "    git clone -b \"$${GITHUB_BRANCH:-main}\" \"$${GITHUB_REPO}\" /home/ubuntu/notes-crud",
      "    chown -R ubuntu:ubuntu /home/ubuntu/notes-crud",
      "fi",
      "",
      "# Install dependencies if package.json exists",
      "if [ -f \"package.json\" ]; then",
      "    echo \"Installing npm dependencies...\"",
      "    npm ci --production",
      "fi",
      "",
      "# Start application with PM2",
      "pm2 start ecosystem.config.js --env production",
      "pm2 save",
      "",
      "echo \"Application started successfully!\"",
      "pm2 status",
      "STARTSCRIPT",
      "chmod +x /home/ubuntu/notes-crud/start.sh",
      "chown ubuntu:ubuntu /home/ubuntu/notes-crud/start.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /home/ubuntu/notes-crud/health.sh << 'HEALTHSCRIPT'",
      "#!/bin/bash",
      "# Health check script for ALB target group",
      "PORT=$${PORT:-${var.app_port}}",
      "curl -sf http://localhost:$PORT/health > /dev/null 2>&1",
      "exit $?",
      "HEALTHSCRIPT",
      "chmod +x /home/ubuntu/notes-crud/health.sh",
      "chown ubuntu:ubuntu /home/ubuntu/notes-crud/health.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "DOMAIN=\"${var.domain_name}\"",
      "EMAIL=\"${var.ssl_email}\"",
      "",
      "if [ -n \"$DOMAIN\" ] && [ \"$DOMAIN\" != \"_\" ]; then",
      "    echo \"Domain provided: $DOMAIN\"",
      "    echo \"Requesting Let's Encrypt certificate...\"",
      "",
      "    # Update nginx config with actual domain",
      "    sed -i \"s/server_name _;/server_name $DOMAIN;/g\" /etc/nginx/sites-available/notes-crud",
      "    sed -i \"s|/etc/letsencrypt/live/_/fullchain.pem|/etc/letsencrypt/live/$DOMAIN/fullchain.pem|g\" /etc/nginx/sites-available/notes-crud",
      "    sed -i \"s|/etc/letsencrypt/live/_/privkey.pem|/etc/letsencrypt/live/$DOMAIN/privkey.pem|g\" /etc/nginx/sites-available/notes-crud",
      "",
      "    # Start nginx in HTTP-only mode for ACME challenge",
      "    nginx -t && systemctl start nginx",
      "    sleep 3",
      "",
      "    # Get certificate using webroot plugin",
      "    certbot certonly \\",
      "        --webroot \\",
      "        --webroot-path=/var/www/certbot \\",
      "        --email \"$EMAIL\" \\",
      "        --agree-tos \\",
      "        --no-eff-email \\",
      "        --non-interactive \\",
      "        -d \"$DOMAIN\" \\",
      "        --expand",
      "",
      "    if [ $? -eq 0 ]; then",
      "        echo \"Certificate obtained successfully!\"",
      "        # Setup auto-renewal",
      "        cat > /etc/cron.d/certbot-renew << 'CRON'",
      "0 */12 * * * root certbot renew --quiet --post-hook \"systemctl reload nginx\" >> /var/log/certbot-renew.log 2>&1",
      "CRON",
      "        echo \"Auto-renewal cron job installed.\"",
      "    else",
      "        echo \"WARNING: Let's Encrypt failed, falling back to self-signed certificate\"",
      "        DOMAIN=\"\"",
      "    fi",
      "fi",
      "",
      "if [ -z \"$DOMAIN\" ] || [ \"$DOMAIN\" = \"_\" ]; then",
      "    echo \"No domain provided or Let's Encrypt failed. Generating self-signed certificate...\"",
      "",
      "    PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo \"localhost\")",
      "    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \\",
      "        -keyout /etc/ssl/private/nginx-selfsigned.key \\",
      "        -out /etc/ssl/certs/nginx-selfsigned.crt \\",
      "        -subj \"/CN=$PUBLIC_IP\" \\",
      "        -addext \"subjectAltName=IP:$PUBLIC_IP\"",
      "",
      "    # Update nginx config for self-signed cert",
      "    sed -i \"s|/etc/letsencrypt/live/_/fullchain.pem|/etc/ssl/certs/nginx-selfsigned.crt|g\" /etc/nginx/sites-available/notes-crud",
      "    sed -i \"s|/etc/letsencrypt/live/_/privkey.pem|/etc/ssl/private/nginx-selfsigned.key|g\" /etc/nginx/sites-available/notes-crud",
      "    sed -i \"s/server_name _;/server_name $PUBLIC_IP;/\" /etc/nginx/sites-available/notes-crud",
      "",
      "    echo \"Self-signed certificate generated for $PUBLIC_IP\"",
      "fi",
      "",
      "# Test and start nginx",
      "nginx -t",
      "systemctl enable nginx",
      "systemctl restart nginx",
      "",
      "echo \"Nginx started with SSL configuration.\""
    ]
  }

  provisioner "shell" {
    inline = [
      "cat > /etc/logrotate.d/notes-crud << 'LOGROTATE'",
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
      "cat >> /etc/security/limits.conf << 'LIMITS'",
      "ubuntu soft nofile 65536",
      "ubuntu hard nofile 65536",
      "root soft nofile 65536",
      "root hard nofile 65536",
      "LIMITS",
      "",
      "cat > /etc/sysctl.d/99-notes-crud.conf << 'SYSCTL'",
      "net.core.somaxconn = 65535",
      "net.ipv4.tcp_max_syn_backlog = 65535",
      "net.core.netdev_max_backlog = 65535",
      "net.ipv4.tcp_fin_timeout = 15",
      "net.ipv4.tcp_tw_reuse = 1",
      "vm.swappiness = 10",
      "SYSCTL",
      "",
      "sysctl --system",
      "",
      "echo \"System limits and kernel parameters configured.\""
    ]
  }

  provisioner "shell" {
    inline = [
      "echo \"==========================================\"",
      "echo \"AMI Build Complete!\"",
      "echo \"==========================================\"",
      "echo \"Timestamp: $(date)\"",
      "INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo \"unknown\")",
      "AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo \"unknown\")",
      "PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo \"none\")",
      "echo \"Instance ID: $INSTANCE_ID\"",
      "echo \"Availability Zone: $AZ\"",
      "echo \"Public IP: $PUBLIC_IP\"",
      "echo \"\"",
      "echo \"Installed Versions:\"",
      "echo \"  Node.js: $(node --version)\"",
      "echo \"  NPM: $(npm --version)\"",
      "echo \"  PM2: $(pm2 --version)\"",
      "echo \"  Git: $(git --version)\"",
      "echo \"  Nginx: $(nginx -v 2>&1)\"",
      "echo \"  Certbot: $(certbot --version 2>&1 | head -1)\"",
      "echo \"  CloudWatch Agent: $(/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a status 2>/dev/null | grep -o 'running' || echo 'not installed')\"",
      "echo \"  SSM Agent: $(systemctl is-active snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null || echo 'not installed')\"",
      "echo \"\"",
      "echo \"Application Directory: /home/ubuntu/notes-crud\"",
      "echo \"PM2 Config: /home/ubuntu/notes-crud/ecosystem.config.js\"",
      "echo \"Start Script: /home/ubuntu/notes-crud/start.sh\"",
      "echo \"Health Check: /home/ubuntu/notes-crud/health.sh\"",
      "echo \"Nginx Config: /etc/nginx/sites-available/notes-crud\"",
      "echo \"SSL Certs: /etc/letsencrypt/live/ (Let's Encrypt) or /etc/ssl/certs/nginx-selfsigned.crt (self-signed)\"",
      "echo \"==========================================\""
    ]
  }
}
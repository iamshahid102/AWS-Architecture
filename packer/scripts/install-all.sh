#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building Notes CRUD Custom AMI"
echo "Timestamp: $(date)"
echo "=========================================="

export DEBIAN_FRONTEND=noninteractive

# ----------------------------------------------------------
# System Packages
# ----------------------------------------------------------
echo "Installing system packages..."
apt-get update -y
apt-get upgrade -y

# Add universe repository for certbot
apt-get install -y software-properties-common 2>/dev/null || true
add-apt-repository universe -y 2>/dev/null || true

apt-get install -y \
    curl wget gnupg lsb-release ca-certificates \
    unzip jq git nginx

# ----------------------------------------------------------
# Node.js LTS
# ----------------------------------------------------------
echo "Installing Node.js..."
NODE_VERSION="${NODE_VERSION:-20}"
curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
apt-get install -y nodejs
# Keep npm at a version compatible with Node.js 20
npm install -g npm@10 2>/dev/null || true

# ----------------------------------------------------------
# PM2
# ----------------------------------------------------------
echo "Installing PM2..."
npm install -g pm2@latest

# ----------------------------------------------------------
# Nginx Configuration
# ----------------------------------------------------------
echo "Configuring Nginx..."

cat > /etc/nginx/nginx.conf << 'NGINXCONF'
user www-data;
worker_processes auto;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    multi_accept on;
    use epoll;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 5;
    gzip_min_length 256;
    gzip_types application/javascript application/json text/css text/xml;

    limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log warn;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}
NGINXCONF

cat > /etc/nginx/sites-available/notes-crud << 'SITECONF'
server {
    listen 80;
    server_name _;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
        allow all;
    }

    location /health {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
SITECONF

ln -sf /etc/nginx/sites-available/notes-crud /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
mkdir -p /var/www/certbot
nginx -t

# ----------------------------------------------------------
# CloudWatch Agent
# ----------------------------------------------------------
echo "Installing CloudWatch Agent..."
cd /tmp
wget -q https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb
rm -f ./amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << CWCONFIG
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/aws/ec2/${ENVIRONMENT:-dev}/user-data",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          },
          {
            "file_path": "/home/ubuntu/notes-crud/logs/*.log",
            "log_group_name": "/aws/ec2/${ENVIRONMENT:-dev}/notes-crud",
            "log_stream_name": "{instance_id}",
            "retention_in_days": 30
          }
        ]
      }
    }
  },
  "metrics": {
    "namespace": "NotesCRUD/EC2",
    "metrics_collected": {
      "cpu": {
        "measurement": ["cpu_usage_idle", "cpu_usage_iowait", "cpu_usage_user", "cpu_usage_system"],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": false
      },
      "mem": {
        "measurement": ["mem_used_percent"],
        "metrics_collection_interval": 60
      },
      "disk": {
        "measurement": ["used_percent"],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      }
    }
  }
}
CWCONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s 2>/dev/null || true

# ----------------------------------------------------------
# SSM Agent
# ----------------------------------------------------------
echo "Installing SSM Agent..."
snap install amazon-ssm-agent --classic 2>/dev/null || true

# ----------------------------------------------------------
# Application directories
# ----------------------------------------------------------
echo "Setting up application directories..."
mkdir -p /home/ubuntu/notes-crud
mkdir -p /home/ubuntu/notes-crud/logs
mkdir -p /home/ubuntu/notes-crud/public
chown -R ubuntu:ubuntu /home/ubuntu/notes-crud

# ----------------------------------------------------------
# PM2 startup config
# ----------------------------------------------------------
cat > /home/ubuntu/notes-crud/ecosystem.config.js << 'ECOSYSTEM'
module.exports = {
  apps: [{
    name: 'notes-crud',
    script: 'src/server.js',
    cwd: '/home/ubuntu/notes-crud/backend',
    instances: 1,
    exec_mode: 'fork',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    error_file: '/home/ubuntu/notes-crud/logs/err.log',
    out_file: '/home/ubuntu/notes-crud/logs/out.log',
    log_file: '/home/ubuntu/notes-crud/logs/combined.log',
    time: true,
    max_memory_restart: '500M',
    restart_delay: 5000,
    max_restarts: 10,
    min_uptime: '10s',
    watch: false,
    kill_timeout: 5000,
    wait_ready: true,
    listen_timeout: 8000
  }]
};
ECOSYSTEM
chown ubuntu:ubuntu /home/ubuntu/notes-crud/ecosystem.config.js

# ----------------------------------------------------------
# Certbot via snap (more reliable than apt)
# ----------------------------------------------------------
echo "Installing Certbot..."
snap install certbot --classic 2>/dev/null || apt-get install -y certbot python3-certbot-nginx 2>/dev/null || true
ln -sf /snap/bin/certbot /usr/bin/certbot 2>/dev/null || true

# ----------------------------------------------------------
# Log rotation
# ----------------------------------------------------------
cat > /etc/logrotate.d/notes-crud << 'LOGROTATE'
/home/ubuntu/notes-crud/logs/*.log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 0640 ubuntu ubuntu
    sharedscripts
    postrotate
        pm2 reloadLogs > /dev/null 2>&1 || true
    endscript
}
LOGROTATE

# ----------------------------------------------------------
# System limits
# ----------------------------------------------------------
cat >> /etc/security/limits.conf << 'LIMITS'
ubuntu soft nofile 65536
ubuntu hard nofile 65536
root soft nofile 65536
root hard nofile 65536
LIMITS

cat > /etc/sysctl.d/99-notes-crud.conf << 'SYSCTL'
net.core.somaxconn = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_tw_reuse = 1
vm.swappiness = 10
SYSCTL
sysctl --system

# ----------------------------------------------------------
# Cleanup
# ----------------------------------------------------------
echo "Cleaning up..."
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/*

echo "=========================================="
echo "AMI Build Complete!"
echo "Timestamp: $(date)"
echo "=========================================="
echo "Installed Versions:"
echo "  Node.js: $(node --version)"
echo "  NPM: $(npm --version)"
echo "  PM2: $(pm2 --version)"
echo "  Git: $(git --version)"
echo "  Nginx: $(nginx -v 2>&1)"
echo "  Certbot: $(certbot --version 2>&1 | head -1)"
echo "=========================================="

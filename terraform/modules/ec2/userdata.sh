#!/bin/bash
set -euo pipefail

# Minimal user-data: only runtime startup tasks
# Heavy lifting (Nginx, Node.js, PM2, Certbot, CloudWatch, SSM) baked into AMI via Packer

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

echo "=========================================="
echo "Starting Notes CRUD EC2 Runtime Setup"
echo "Timestamp: $$(date)"
echo "=========================================="

# Environment Variables (passed from Terraform template - these use $${var} for Terraform interpolation)
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
AWS_REGION="${aws_region}"
ENABLE_CLOUDWATCH_AGENT="${enable_cloudwatch_agent}"
ENABLE_SSM_AGENT="${enable_ssm_agent}"
GITHUB_REPO="${github_repo}"
GITHUB_BRANCH="${github_branch}"
DOMAIN_NAME="${domain_name}"
SSL_EMAIL="${ssl_email}"

echo "Configuration:"
echo "  App Port: $${APP_PORT}"
echo "  Environment: $${ENVIRONMENT}"
echo "  AWS Region: $${AWS_REGION}"
echo "  GitHub Repo: $${GITHUB_REPO:-none}"
echo "  Domain: $${DOMAIN_NAME:-none (self-signed)}"

# ----------------------------------------------------------
# Clone / Update Application Repository
# ----------------------------------------------------------
echo "=========================================="
echo "Setting up application..."
echo "=========================================="

mkdir -p /home/ubuntu/notes-crud
mkdir -p /home/ubuntu/notes-crud/logs
chown -R ubuntu:ubuntu /home/ubuntu/notes-crud

if [ -n "$${GITHUB_REPO:-}" ] && [ ! -d "/home/ubuntu/notes-crud/backend" ]; then
    echo "Cloning repository..."
    TEMP_DIR=$$(mktemp -d)
    git clone -b "$${GITHUB_BRANCH:-main}" "$${GITHUB_REPO}" "$${TEMP_DIR}"
    
    if [ -d "$${TEMP_DIR}/backend" ]; then
        mv "$${TEMP_DIR}/backend" /home/ubuntu/notes-crud/
    fi
    if [ -d "$${TEMP_DIR}/frontend" ]; then
        mv "$${TEMP_DIR}/frontend" /home/ubuntu/notes-crud/
    fi
    rm -rf "$${TEMP_DIR}"
    chown -R ubuntu:ubuntu /home/ubuntu/notes-crud
fi

# ----------------------------------------------------------
# Install Backend Dependencies
# ----------------------------------------------------------
if [ -f "/home/ubuntu/notes-crud/backend/package.json" ]; then
    echo "Installing npm dependencies..."
    cd /home/ubuntu/notes-crud/backend
    sudo -u ubuntu npm ci --production
fi

# ----------------------------------------------------------
# SSL Certificate Setup (Let's Encrypt / Self-signed)
# ----------------------------------------------------------
echo "=========================================="
echo "Setting up SSL certificates..."
echo "=========================================="

DOMAIN="$${DOMAIN_NAME:-}"
EMAIL="$${SSL_EMAIL:-admin@localhost}"

if [ -n "$${DOMAIN}" ] && [ "$${DOMAIN}" != "auto" ]; then
    echo "Domain provided: $${DOMAIN}"
    echo "Requesting Let's Encrypt certificate..."
    
    # Update nginx config with actual domain
    sed -i "s/server_name _;/server_name $${DOMAIN};/g" /etc/nginx/sites-available/notes-crud
    sed -i "s|/etc/letsencrypt/live/_/fullchain.pem|/etc/letsencrypt/live/$${DOMAIN}/fullchain.pem|g" /etc/nginx/sites-available/notes-crud
    sed -i "s|/etc/letsencrypt/live/_/privkey.pem|/etc/letsencrypt/live/$${DOMAIN}/privkey.pem|g" /etc/nginx/sites-available/notes-crud
    
    # Start nginx for ACME challenge
    nginx -t && systemctl start nginx
    sleep 3
    
    certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email "$${EMAIL}" \
        --agree-tos \
        --no-eff-email \
        --non-interactive \
        -d "$${DOMAIN}" \
        --expand
    
    if [ $$? -eq 0 ]; then
        echo "Certificate obtained successfully!"
        cat > /etc/cron.d/certbot-renew << 'CRON'
0 */12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx" >> /var/log/certbot-renew.log 2>&1
CRON
        echo "Auto-renewal cron job installed."
    else
        echo "WARNING: Let's Encrypt failed, falling back to self-signed certificate"
        DOMAIN=""
    fi
fi

if [ -z "$${DOMAIN}" ] || [ "$${DOMAIN}" = "auto" ]; then
    echo "No domain provided or Let's Encrypt failed. Generating self-signed certificate..."
    PUBLIC_IP=$$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "localhost")
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/ssl/private/nginx-selfsigned.key \
        -out /etc/ssl/certs/nginx-selfsigned.crt \
        -subj "/CN=$${PUBLIC_IP}" \
        -addext "subjectAltName=IP:$${PUBLIC_IP}"
    
    sed -i "s|/etc/letsencrypt/live/_/fullchain.pem|/etc/ssl/certs/nginx-selfsigned.crt|g" /etc/nginx/sites-available/notes-crud
    sed -i "s|/etc/letsencrypt/live/_/privkey.pem|/etc/ssl/private/nginx-selfsigned.key|g" /etc/nginx/sites-available/notes-crud
    sed -i "s/server_name _;/server_name $${PUBLIC_IP};/g" /etc/nginx/sites-available/notes-crud
    echo "Self-signed certificate generated for $${PUBLIC_IP}"
fi

# ----------------------------------------------------------
# Start Services
# ----------------------------------------------------------
echo "=========================================="
echo "Starting services..."
echo "=========================================="

nginx -t
systemctl enable nginx
systemctl restart nginx

# Start application with PM2
cd /home/ubuntu/notes-crud
if [ -f "backend/ecosystem.config.js" ]; then
    sudo -u ubuntu pm2 start backend/ecosystem.config.js --env production
    sudo -u ubuntu pm2 save
    sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu
fi

# Start CloudWatch Agent if enabled
if [ "$${ENABLE_CLOUDWATCH_AGENT}" = "true" ]; then
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
        -s
    systemctl enable amazon-cloudwatch-agent
fi

# Start SSM Agent if enabled
if [ "$${ENABLE_SSM_AGENT}" = "true" ]; then
    systemctl enable snap.amazon-ssm-agent.amazon-ssm-agent
    systemctl start snap.amazon-ssm-agent.amazon-ssm-agent
fi

# ----------------------------------------------------------
# Final Summary
# ----------------------------------------------------------
echo "=========================================="
echo "Bootstrap Complete!"
echo "=========================================="
echo "Timestamp: $$(date)"
INSTANCE_ID=$$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
AZ=$$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo "unknown")
PUBLIC_IP=$$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "none")
echo "Instance ID: $${INSTANCE_ID}"
echo "Availability Zone: $${AZ}"
echo "Public IP: $${PUBLIC_IP}"
echo ""
echo "Installed Versions:"
echo "  Node.js: $$(node --version 2>/dev/null || echo 'not installed')"
echo "  NPM: $$(npm --version 2>/dev/null || echo 'not installed')"
echo "  PM2: $$(pm2 --version 2>/dev/null || echo 'not installed')"
echo "  Nginx: $$(nginx -v 2>&1 | head -1)"
echo "  Certbot: $$(certbot --version 2>&1 | head -1)"
echo ""
echo "Application Directory: /home/ubuntu/notes-crud"
echo "PM2 Config: /home/ubuntu/notes-crud/backend/ecosystem.config.js"
echo "Start Script: /home/ubuntu/notes-crud/start.sh"
echo "Health Check: /home/ubuntu/notes-crud/health.sh"
echo "Nginx Config: /etc/nginx/sites-available/notes-crud"
echo "SSL Certs: /etc/letsencrypt/live/ or /etc/ssl/certs/nginx-selfsigned.crt"
echo "=========================================="
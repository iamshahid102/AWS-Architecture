#!/bin/bash
# Notes CRUD EC2 bootstrap script
# Designed for Terraform templatefile() interpolation
# Shell-only variables use double-dollar {VAR_NAME} to escape from Terraform

exec > /var/log/user-data.log 2>&1

echo "=========================================="
echo "Starting Notes CRUD EC2 Runtime Setup"
echo "Timestamp: $(date)"
echo "=========================================="

# Terraform-substituted variables
APP_PORT="${app_port}"
ENVIRONMENT="${environment}"
AWS_REGION="${aws_region}"
ENABLE_CLOUDWATCH_AGENT="${enable_cloudwatch_agent}"
ENABLE_SSM_AGENT="${enable_ssm_agent}"
GITHUB_REPO="${github_repo}"
GITHUB_BRANCH="${github_branch}"
DB_HOST="${db_host}"
DB_PORT="${db_port}"
DB_USER="${db_user}"
DB_PASSWORD="${db_password}"
DB_NAME="${db_name}"

echo "Configuration:"
echo "  App Port: $${APP_PORT}"
echo "  Environment: $${ENVIRONMENT}"
echo "  AWS Region: $${AWS_REGION}"
echo "  DB Host: $${DB_HOST}"

# ----------------------------------------------------------
# Install system packages (fallback for generic AMI)
# ----------------------------------------------------------
echo "Installing system packages..."
apt-get update -y
apt-get install -y git curl postgresql-client

if ! command -v node &>/dev/null; then
    echo "Node.js not found. Installing..."
    curl -fsSL "https://deb.nodesource.com/setup_20.x" | bash -
    apt-get install -y nodejs
fi

if ! command -v nginx &>/dev/null; then
    echo "Nginx not found. Installing..."
    apt-get install -y nginx
    systemctl stop nginx 2>/dev/null || true
fi

if ! command -v pm2 &>/dev/null; then
    echo "PM2 not found. Installing..."
    npm install -g pm2@latest
fi

echo "Versions:"
echo "  Node.js: $(node --version)"
echo "  NPM: $(npm --version)"
echo "  PM2: $(pm2 --version 2>/dev/null || echo 'not installed')"

# ----------------------------------------------------------
# Clone / Update Application Repository
# ----------------------------------------------------------
echo "Setting up application..."

mkdir -p /home/ubuntu/notes-crud
mkdir -p /home/ubuntu/notes-crud/logs
chown -R ubuntu:ubuntu /home/ubuntu/notes-crud

if [ -n "$${GITHUB_REPO}" ] && [ ! -d "/home/ubuntu/notes-crud/backend" ]; then
    echo "Cloning repository..."
    TEMP_DIR=$(mktemp -d)
    git clone -b "$${GITHUB_BRANCH}" "$${GITHUB_REPO}" "$${TEMP_DIR}"

    mkdir -p /home/ubuntu/notes-crud/backend /home/ubuntu/notes-crud/frontend
    if [ -d "$${TEMP_DIR}/backend" ]; then
        cp -r "$${TEMP_DIR}/backend"/* /home/ubuntu/notes-crud/backend/ 2>/dev/null || true
    fi
    if [ -d "$${TEMP_DIR}/frontend" ]; then
        cp -r "$${TEMP_DIR}/frontend"/* /home/ubuntu/notes-crud/frontend/ 2>/dev/null || true
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
    sudo -u ubuntu npm ci --production || sudo -u ubuntu npm install --production
fi

# ----------------------------------------------------------
# Ensure Nginx HTTP-only configuration (Free Tier - no SSL)
# ----------------------------------------------------------
NGINX_SITE="/etc/nginx/sites-available/notes-crud"
if [ ! -f "$${NGINX_SITE}" ] || ! grep -q "listen 80" "$${NGINX_SITE}"; then
    echo "Creating HTTP-only Nginx configuration..."
    cat > "$${NGINX_SITE}" << 'NGINX_SITE_EOF'
server {
    listen 80;
    server_name _;

    location /health {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        access_log off;
    }

    location /css/ {
        alias /home/ubuntu/notes-crud/frontend/css/;
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    location /js/ {
        alias /home/ubuntu/notes-crud/frontend/js/;
        expires 1y;
        add_header Cache-Control "public, immutable";
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
        root /home/ubuntu/notes-crud/frontend;
        index index.html;
        try_files $uri $uri/ /index.html;
    }
}
NGINX_SITE_EOF

    ln -sf "$${NGINX_SITE}" /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    echo "Nginx HTTP-only configuration created."
fi

# ----------------------------------------------------------
# Fix file permissions for Nginx access
# ----------------------------------------------------------
echo "Fixing Nginx file permissions..."
chmod o+x /home/ubuntu 2>/dev/null || true
chmod -R o+rX /home/ubuntu/notes-crud 2>/dev/null || true
echo "Permissions fixed."

# ----------------------------------------------------------
# Create .env file with database credentials
# ----------------------------------------------------------
echo "Creating .env file..."
# Write .env file with actual values (unquoted heredoc allows shell expansion)
cat > /home/ubuntu/notes-crud/backend/.env << ENVEOF
DB_HOST=$${DB_HOST}
DB_PORT=$${DB_PORT}
DB_USER=$${DB_USER}
DB_PASSWORD=$${DB_PASSWORD}
DB_NAME=$${DB_NAME}
NODE_ENV=production
PORT=$${APP_PORT}
ENVEOF
chown ubuntu:ubuntu /home/ubuntu/notes-crud/backend/.env
chmod 600 /home/ubuntu/notes-crud/backend/.env
echo ".env file created with DB credentials."

# ----------------------------------------------------------
# Initialize Database Schema (idempotent - safe to run multiple times)
# ----------------------------------------------------------
if command -v psql &>/dev/null && [ -n "$${DB_HOST}" ]; then
    echo "Initializing database schema..."
    PGPASSWORD="$${DB_PASSWORD}" psql -h "$${DB_HOST}" -p "$${DB_PORT}" -U "$${DB_USER}" -d "$${DB_NAME}" -c "
        CREATE TABLE IF NOT EXISTS notes (
            id SERIAL PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            content TEXT NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        );
    " 2>&1 || echo "DB schema: table may already exist or psql not available"
    
    PGPASSWORD="$${DB_PASSWORD}" psql -h "$${DB_HOST}" -p "$${DB_PORT}" -U "$${DB_USER}" -d "$${DB_NAME}" -c "
        CREATE INDEX IF NOT EXISTS idx_notes_created_at ON notes(created_at DESC);
    " 2>&1 || echo "DB schema: index creation skipped"
    
    PGPASSWORD="$${DB_PASSWORD}" psql -h "$${DB_HOST}" -p "$${DB_PORT}" -U "$${DB_USER}" -d "$${DB_NAME}" -c "
        INSERT INTO notes (title, content) 
        SELECT 'Welcome to Notes CRUD', 'Your Notes CRUD application is deployed on AWS!'
        WHERE NOT EXISTS (SELECT 1 FROM notes LIMIT 1);
    " 2>&1 || echo "DB seed: sample data insertion skipped"
    
    echo "Database initialization complete."
else
    echo "psql not available or DB_HOST not set. Skipping DB init."
fi

# ----------------------------------------------------------
# Start Services
# ----------------------------------------------------------
echo "Starting services..."

# Test and start Nginx
nginx -t 2>/dev/null && systemctl enable nginx && systemctl restart nginx || echo "Nginx config test skipped/warning"

# Start application with PM2
cd /home/ubuntu/notes-crud
if [ -f "ecosystem.config.js" ]; then
    echo "Starting PM2 with ecosystem.config.js..."
    sudo -u ubuntu pm2 start ecosystem.config.js --env production 2>/dev/null || sudo -u ubuntu pm2 start ecosystem.config.js --env production --update-env
elif [ -f "backend/ecosystem.config.js" ]; then
    echo "Starting PM2 with backend/ecosystem.config.js..."
    sudo -u ubuntu pm2 start backend/ecosystem.config.js --env production 2>/dev/null || sudo -u ubuntu pm2 start backend/ecosystem.config.js --env production --update-env
else
    echo "Starting PM2 with server.js directly..."
    sudo -u ubuntu pm2 delete notes-crud 2>/dev/null || true
    sudo -u ubuntu env "PORT=$${APP_PORT}" pm2 start /home/ubuntu/notes-crud/backend/src/server.js --name notes-crud --update-env
fi
sudo -u ubuntu pm2 save
sudo -u ubuntu pm2 startup systemd -u ubuntu --hp /home/ubuntu 2>/dev/null || true
sudo -u ubuntu pm2 restart notes-crud 2>/dev/null || true

# Start CloudWatch Agent if enabled
if [ "$${ENABLE_CLOUDWATCH_AGENT}" = "true" ]; then
    /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
        -s 2>/dev/null || true
fi

# Start SSM Agent if enabled (already running from AMI)
if [ "$${ENABLE_SSM_AGENT}" = "true" ]; then
    systemctl enable amazon-ssm-agent 2>/dev/null || true
    systemctl start amazon-ssm-agent 2>/dev/null || systemctl start snap.amazon-ssm-agent.amazon-ssm-agent 2>/dev/null || true
fi

# ----------------------------------------------------------
# Final Summary
# ----------------------------------------------------------
echo "=========================================="
echo "Bootstrap Complete!"
echo "=========================================="
echo "Timestamp: $(date)"
echo "Installed Versions:"
echo "  Node.js: $(node --version 2>/dev/null || echo 'not installed')"
echo "  NPM: $(npm --version 2>/dev/null || echo 'not installed')"
echo "  PM2: $(pm2 --version 2>/dev/null || echo 'not installed')"
echo "  Nginx: $(nginx -v 2>&1 | head -1)"
echo ""
echo "Application Directory: /home/ubuntu/notes-crud"
echo "=========================================="

#!/bin/bash
set -euo pipefail

echo "=== Installing Node.js ${NODE_VERSION} LTS ==="
curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
apt-get install -y nodejs
node --version
npm --version
npm install -g npm@latest
echo "Node.js $(node --version) and NPM $(npm --version) installed"
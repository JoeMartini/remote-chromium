#!/bin/bash
# 一键启动 Remote Chromium
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/JoeMartini/remote-chromium/main"
WORK_DIR="${SERVER_BROWSER_WORK_DIR:-$HOME/remote-chromium}"

echo "=== Remote Chromium Quick Start ==="
echo "Work directory: $WORK_DIR"

mkdir -p "$WORK_DIR" "$WORK_DIR/configs" "$WORK_DIR/extensions" "$WORK_DIR/scripts"
cd "$WORK_DIR"

# Download required files
echo "Downloading scripts..."
curl -fsSL "$REPO_RAW/scripts/start.sh" -o scripts/start.sh
curl -fsSL "$REPO_RAW/scripts/stop.sh" -o scripts/stop.sh
curl -fsSL "$REPO_RAW/scripts/apply-auth-mode.sh" -o scripts/apply-auth-mode.sh
curl -fsSL "$REPO_RAW/scripts/install-extension.sh" -o scripts/install-extension.sh

echo "Downloading configs..."
curl -fsSL "$REPO_RAW/configs/Dockerfile" -o configs/Dockerfile
curl -fsSL "$REPO_RAW/configs/autostart" -o configs/autostart
curl -fsSL "$REPO_RAW/configs/socat-cdp.sh" -o configs/socat-cdp.sh
curl -fsSL "$REPO_RAW/configs/managed_policies.json" -o configs/managed_policies.json
curl -fsSL "$REPO_RAW/configs/openresty-chrome-basic.conf" -o configs/openresty-chrome-basic.conf
curl -fsSL "$REPO_RAW/configs/openresty-chrome-oidc.conf" -o configs/openresty-chrome-oidc.conf
curl -fsSL "$REPO_RAW/configs/oauth2-proxy.env.example" -o configs/oauth2-proxy.env.example

echo "Downloading docker-compose and .env..."
curl -fsSL "$REPO_RAW/docker-compose.yml" -o docker-compose.yml
curl -fsSL "$REPO_RAW/examples/.env.example" -o .env.example

chmod +x scripts/*.sh

if [ ! -f .env ]; then
    cp .env.example .env
    echo ""
    echo "Created .env from template. Please edit it with your settings, then run:"
    echo "  ./scripts/start.sh"
else
    echo ".env already exists, skipping"
fi

echo ""
echo "Done. Next steps:"
echo "  1. vim $WORK_DIR/.env"
echo "  2. $WORK_DIR/scripts/start.sh"
echo "  3. open https://your-domain:8443/"

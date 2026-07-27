#!/bin/bash
set -euo pipefail

if [ -f .env ]; then
    set -a
    # shellcheck source=/dev/null
    source .env
    set +a
fi

CONTAINER_NAME="${CHROME_CONTAINER_NAME:-remote-chromium}"
OAUTH2_PROXY_CONTAINER="${OAUTH2_PROXY_CONTAINER_NAME:-oauth2-proxy-remote-chromium}"

echo "Stopping container $CONTAINER_NAME..."
docker stop "$CONTAINER_NAME" 2>/dev/null || true
docker rm "$CONTAINER_NAME" 2>/dev/null || true

echo "Stopping OAuth2-Proxy container $OAUTH2_PROXY_CONTAINER..."
docker stop "$OAUTH2_PROXY_CONTAINER" 2>/dev/null || true
docker rm "$OAUTH2_PROXY_CONTAINER" 2>/dev/null || true

echo "Stopped."

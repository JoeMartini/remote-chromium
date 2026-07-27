#!/bin/bash
# 切换 Remote Chromium 反代鉴权模式：basic 或 oidc
set -euo pipefail

# 切换到项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
cd "$PROJECT_DIR"

# 加载环境变量
if [ -f .env ]; then
    set -a
    # shellcheck source=/dev/null
    source .env
    set +a
fi

CONFIG_DIR="./configs"
AUTH_MODE="${AUTH_MODE:-basic}"

# OpenResty 容器名（在 .env 中设置 OPENRESTY_CONTAINER）
OR_CONTAINER="${OPENRESTY_CONTAINER:-}"
OR_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d"

if [ -z "$OR_CONTAINER" ]; then
    echo "[apply-auth-mode] ERROR: OPENRESTY_CONTAINER is not set."
    echo "  Set it in .env, e.g.: OPENRESTY_CONTAINER=your-openresty-container-name"
    exit 1
fi

case "$AUTH_MODE" in
  basic)
    SRC="$CONFIG_DIR/openresty-chrome-basic.conf"
    echo "[apply-auth-mode] Switching to BASIC auth"
    ;;
  oidc)
    SRC="$CONFIG_DIR/openresty-chrome-oidc.conf"
    echo "[apply-auth-mode] Switching to OIDC auth (OAuth2-Proxy)"
    ;;
  *)
    echo "[apply-auth-mode] Invalid AUTH_MODE=$AUTH_MODE (use 'basic' or 'oidc')"
    exit 1
    ;;
esac

if [ ! -f "$SRC" ]; then
    echo "[apply-auth-mode] Missing config: $SRC"
    exit 1
fi

echo "[apply-auth-mode] Deploying to OpenResty container: $OR_CONTAINER"
docker cp "$SRC" "$OR_CONTAINER:$OR_CONF_DIR/remote-chromium.conf"
docker exec "$OR_CONTAINER" nginx -t
docker exec "$OR_CONTAINER" nginx -s reload

echo "[apply-auth-mode] Applied $AUTH_MODE mode and reloaded OpenResty"

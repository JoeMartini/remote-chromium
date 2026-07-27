#!/bin/bash
# 切换 Remote Chromium 反代鉴权模式：basic 或 oidc
set -euo pipefail

# 加载环境变量
if [ -f .env ]; then
    set -a
    # shellcheck source=/dev/null
    source .env
    set +a
fi

WORK_DIR="${SERVER_BROWSER_WORK_DIR:-$HOME/remote-chromium}"
CONFIG_DIR="${CHROME_CONFIG_DIR:-$WORK_DIR/configs}"
AUTH_MODE="${AUTH_MODE:-basic}"

# OpenResty 容器名（可通过 .env 覆盖）
OR_CONTAINER="${OPENRESTY_CONTAINER:-1Panel-openresty-DrBW}"
OR_CONF_DIR="/usr/local/openresty/nginx/conf/conf.d"

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

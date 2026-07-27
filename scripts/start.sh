#!/bin/bash
# 启动 Remote Chromium 容器
set -euo pipefail

# 切换到项目根目录（脚本所在目录的上一级）
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

# 默认值
CONTAINER_NAME="${CHROME_CONTAINER_NAME:-remote-chromium}"
IMAGE="${CHROME_IMAGE:-remote-chromium:latest}"
WORK_DIR="${SERVER_BROWSER_WORK_DIR:-$HOME/remote-chromium}"
CONFIG_DIR="${CHROME_CONFIG_DIR:-$WORK_DIR/config}"
EXTENSIONS_DIR="${CHROME_EXTENSIONS_DIR:-$WORK_DIR/extensions}"
POLICIES_FILE="${CHROME_POLICIES_FILE:-$WORK_DIR/configs/managed_policies.json}"

KASM_PORT="${KASM_HTTP_PORT:-3800}"
KASM_HTTPS_PORT="${KASM_HTTPS_PORT:-3801}"
CDP_PORT="${CHROME_CDP_PORT:-9222}"
CDP_PROXY_PORT="${CHROME_CDP_PROXY_PORT:-9224}"
PUID="${PUID:-1000}"
PGID="${PGID:-1000}"
TZ="${TZ:-Asia/Shanghai}"
SHM_SIZE="${CHROME_SHM_SIZE:-1gb}"
AUTH_MODE="${AUTH_MODE:-basic}"

mkdir -p "$CONFIG_DIR/chromium"
mkdir -p "$EXTENSIONS_DIR"

# 如果本地没有镜像，尝试构建
if ! docker image inspect "$IMAGE" >/dev/null 2>&1; then
    echo "Image $IMAGE not found locally. Building..."
    # Dockerfile expects extensions/ to exist in build context
    mkdir -p extensions
    docker build -f "$WORK_DIR/configs/Dockerfile" -t "$IMAGE" "$WORK_DIR"
fi

# 停止并移除已存在的容器
if docker ps -aq -f name="^/${CONTAINER_NAME}$" | grep -q .; then
    echo "Removing existing container $CONTAINER_NAME..."
    docker rm -f "$CONTAINER_NAME" >/dev/null
fi

# 清理 Chromium 锁文件，防止启动异常
rm -f "$CONFIG_DIR/chromium/SingletonLock"
rm -f "$CONFIG_DIR/chromium/SingletonCookie"
rm -f "$CONFIG_DIR/chromium/SingletonSocket"

echo "Starting container $CONTAINER_NAME..."
docker run -d --name "$CONTAINER_NAME" \
  --network host \
  --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
  -e PUID="$PUID" \
  -e PGID="$PGID" \
  -e TZ="$TZ" \
  -e CUSTOM_PORT="$KASM_PORT" \
  -e CUSTOM_HTTPS_PORT="$KASM_HTTPS_PORT" \
  -e CHROMIUM_CDP_PORT="$CDP_PORT" \
  -e CHROMIUM_CDP_PROXY_PORT="$CDP_PROXY_PORT" \
  -e EXTENSIONS_DIR=/config/extensions \
  -v "$CONFIG_DIR:/config" \
  -v "$EXTENSIONS_DIR:/config/extensions:ro" \
  -v "$POLICIES_FILE:/etc/chromium/policies/managed/managed_policies.json:ro" \
  --shm-size="$SHM_SIZE" \
  --restart=unless-stopped \
  "$IMAGE"

echo "Container $CONTAINER_NAME started."

# 如果启用 OIDC，启动 OAuth2-Proxy
if [ "$AUTH_MODE" == "oidc" ]; then
    OAUTH2_PROXY_CONTAINER="${OAUTH2_PROXY_CONTAINER_NAME:-oauth2-proxy-remote-chromium}"
    OAUTH2_PROXY_ENV="${OAUTH2_PROXY_ENV_FILE:-$WORK_DIR/configs/oauth2-proxy.env}"

    if [ ! -f "$OAUTH2_PROXY_ENV" ]; then
        echo "ERROR: OIDC mode requested but $OAUTH2_PROXY_ENV not found."
        echo "Copy configs/oauth2-proxy.env.example and fill in your values."
        exit 1
    fi

    if docker ps -aq -f name="^/${OAUTH2_PROXY_CONTAINER}$" | grep -q .; then
        echo "Removing existing OAuth2-Proxy container..."
        docker rm -f "$OAUTH2_PROXY_CONTAINER" >/dev/null
    fi

    echo "Starting OAuth2-Proxy container $OAUTH2_PROXY_CONTAINER..."
    docker run -d --name "$OAUTH2_PROXY_CONTAINER" \
      --network host \
      --log-driver json-file --log-opt max-size=10m --log-opt max-file=3 \
      --env-file "$OAUTH2_PROXY_ENV" \
      --restart=unless-stopped \
      quay.io/oauth2-proxy/oauth2-proxy:latest

    echo "OAuth2-Proxy started."
fi

echo ""
echo "KasmVNC UI: http://localhost:$KASM_PORT/"
echo "CDP proxy:  http://localhost:$CDP_PROXY_PORT"
echo "Auth mode:  $AUTH_MODE"
echo ""
echo "Usage:"
echo "  export CDP_ENDPOINT=http://localhost:$CDP_PROXY_PORT"
echo ""
echo "  # OpenCLI:"
echo "  export OPENCLI_CDP_ENDPOINT=http://localhost:$CDP_PROXY_PORT"
echo "  opencli doctor"
echo ""
echo "  # Puppeteer:"
echo "  # browserWSEndpoint: 'ws://localhost:$CDP_PROXY_PORT'"

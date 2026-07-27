#!/bin/bash
# 下载 Chrome 扩展（默认 OpenCLI Browser Bridge）
set -euo pipefail

# 扩展源可以通过环境变量自定义
EXTENSION_NAME="${EXTENSION_NAME:-opencli-webstore}"
EXTENSION_URL="${EXTENSION_URL:-https://github.com/jackwener/opencli/releases/download/v1.8.6/opencli-extension.zip}"

WORK_DIR="${SERVER_BROWSER_WORK_DIR:-$HOME/remote-chromium}"
EXT_DIR="$WORK_DIR/extensions/$EXTENSION_NAME"

mkdir -p "$EXT_DIR"
cd "$EXT_DIR"

echo "Downloading extension: $EXTENSION_NAME..."
echo "Source: $EXTENSION_URL"

if curl -fsSL "$EXTENSION_URL" -o /tmp/extension.zip; then
    echo "Downloaded successfully"
else
    echo "Failed to download extension from $EXTENSION_URL"
    echo ""
    echo "You can manually download the extension and extract it to:"
    echo "  $EXT_DIR"
    echo ""
    echo "The directory must contain a manifest.json file."
    exit 1
fi

rm -rf "$EXT_DIR"/*
unzip -o /tmp/extension.zip -d "$EXT_DIR"
rm -f /tmp/extension.zip

echo ""
echo "Extension installed to: $EXT_DIR"
echo ""
echo "To load this extension, ensure it's referenced in:"
echo "  - configs/managed_policies.json (ExtensionInstallForcelist)"
echo "  - .env CHROME_EXTENSIONS_DIR (mount path)"

#!/bin/bash
# Expose Chromium CDP (localhost only) to 0.0.0.0 for external access
CDP_PORT="${1:-9222}"
PROXY_PORT="${2:-9224}"

echo "[socat-cdp] Forwarding 0.0.0.0:$PROXY_PORT -> 127.0.0.1:$CDP_PORT"
exec socat TCP-LISTEN:"$PROXY_PORT",fork,reuseaddr TCP:127.0.0.1:"$CDP_PORT"

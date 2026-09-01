#!/bin/bash
# Expose Chromium CDP (localhost only) to a proxy port.
# By default binds to 127.0.0.1 only — safe for local agent/CDP clients.
# Set CDP_PROXY_BIND=0.0.0.0 to expose externally (NOT recommended).
CDP_PORT="${1:-9222}"
PROXY_PORT="${2:-9224}"
BIND_ADDR="${CDP_PROXY_BIND:-127.0.0.1}"

echo "[socat-cdp] Forwarding ${BIND_ADDR}:${PROXY_PORT} -> 127.0.0.1:${CDP_PORT}"
exec socat TCP-LISTEN:"${PROXY_PORT}",fork,reuseaddr,bind="${BIND_ADDR}" TCP:127.0.0.1:"${CDP_PORT}"

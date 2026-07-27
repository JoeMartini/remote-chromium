# 反向代理配置指南

## 为什么需要反向代理

KasmVNC 默认使用 HTTP + WebSocket。直接暴露到公网不安全，因此建议通过 OpenResty/Nginx/Caddy 反代，并加上 TLS 和 Basic Auth。

## OpenResty 配置

### 方式 A：使用 apply-auth-mode.sh

```bash
# 编辑 .env 设置 AUTH_MODE 和域名
AUTH_MODE=basic
CHROME_DOMAIN=chrome.example.com
CHROME_HTTPS_PORT=8443

# 手动编辑 configs/openresty-chrome-basic.conf 中的证书路径和 htpasswd 路径
# 然后执行：
./scripts/apply-auth-mode.sh
```

### 方式 B：手动部署

1. 生成 Basic Auth 密码文件：

```bash
htpasswd -cb /path/to/.htpasswd your-user your-password
```

2. 编辑 `configs/openresty-chrome-basic.conf`，替换占位符：

- `CHROME_DOMAIN` → 你的域名
- `CHROME_HTTPS_PORT` → 对外端口（如 8443）
- `KASM_HTTP_PORT` → KasmVNC HTTP 端口（如 3800）
- `/path/to/fullchain.pem` 和 `/path/to/privkey.pem` → TLS 证书路径
- `/path/to/.htpasswd` → 密码文件路径

3. 复制到 OpenResty 配置目录并重载：

```bash
docker cp configs/openresty-chrome-basic.conf your-openresty:/usr/local/openresty/nginx/conf/conf.d/remote-chromium.conf
docker exec your-openresty nginx -t
docker exec your-openresty nginx -s reload
```

## Caddy 配置示例

```caddy
chrome.example.com {
    basicauth {
        your-user $2a$14$...
    }
    reverse_proxy localhost:3800
}
```

## 验证

```bash
curl -u your-user:your-password https://chrome.example.com:8443/
```

应返回 `200` 和 KasmVNC 的 HTML 页面。

## WebSocket 注意事项

KasmVNC 使用 WebSocket 传输画面和输入，反代必须正确处理 Upgrade 头：

```nginx
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_read_timeout 86400;
```

所有提供的 `.conf` 模板已包含上述配置。

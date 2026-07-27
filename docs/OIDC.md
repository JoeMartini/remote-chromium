# OIDC Authentication (validated with Keycloak)

通过 OAuth2-Proxy 将 Remote Chromium 接入标准 OIDC Provider。本文以 Keycloak 为例进行验证；任何兼容 OpenID Connect 的 Provider（Auth0、Authing、Dex、Authentik 等）配置思路相同。

## 架构

```
用户浏览器
    ↓ HTTPS
OpenResty (8443)
    ↓ HTTP
OAuth2-Proxy (4181)
    ↓ 未认证 → 302 → OIDC Provider
    ↓ 已认证 → HTTP
KasmVNC (3800)
```

## 前置条件

- 已运行一个标准 OIDC Provider（本文示例为 Keycloak）
- 已在 Provider 中创建 client
- （可选）已配置 role/group/email 限制

## 在 OIDC Provider 中创建 Client

通用要求：

| 字段 | 值 |
|---|---|
| Client ID | `remote-chromium`（可自定义） |
| Client authentication | ON / confidential client |
| Authentication flow | Authorization code / Standard flow |
| Valid redirect URIs | `https://chrome.example.com:8443/oauth2/callback` |
| Web origins | `https://chrome.example.com:8443` |

不同 Provider 的术语可能不同：
- Keycloak：在 realm 下创建 **client**
- Auth0：创建 **Application**
- Authing：创建 **应用 / Application**
- Azure AD：注册 **App registration**

创建后记录 **client secret**。

## 授权限制（可选）

OAuth2-Proxy 支持多种授权维度，不同 Provider 对应不同参数：

| Provider 类型 | 限制维度 | 示例参数 |
|---|---|---|
| Keycloak | realm role | `OAUTH2_PROXY_ALLOWED_ROLE=remote-chrome-access` |
| Generic OIDC | groups claim | `OAUTH2_PROXY_ALLOWED_GROUPS=chrome-users` |
| Any | email allowlist | `OAUTH2_PROXY_AUTHENTICATED_EMAILS_FILE=/path/to/emails.txt` |
| Any | allow all authenticated | 不设置以上参数 |

## OAuth2-Proxy 配置

复制模板：

```bash
cp configs/oauth2-proxy.env.example configs/oauth2-proxy.env
```

编辑 `configs/oauth2-proxy.env`：

```ini
# Generic OIDC provider (recommended)
OAUTH2_PROXY_PROVIDER=oidc

# Or use provider-specific preset, e.g.:
# OAUTH2_PROXY_PROVIDER=keycloak-oidc

OAUTH2_PROXY_CLIENT_ID=remote-chromium
OAUTH2_PROXY_CLIENT_SECRET=<client-secret>
OAUTH2_PROXY_OIDC_ISSUER_URL=https://auth.example.com:8443/realms/your-realm
OAUTH2_PROXY_REDIRECT_URL=https://chrome.example.com:8443/oauth2/callback
OAUTH2_PROXY_COOKIE_SECRET=<openssl rand -base64 32>
OAUTH2_PROXY_COOKIE_DOMAIN=.example.com
OAUTH2_PROXY_UPSTREAMS=http://127.0.0.1:3800
OAUTH2_PROXY_EMAIL_DOMAINS=*
OAUTH2_PROXY_HTTP_ADDRESS=0.0.0.0:4181

# Optional authorization restriction. Pick one that your Provider supports:
# OAUTH2_PROXY_ALLOWED_ROLE=remote-chrome-access       # Keycloak realm role
# OAUTH2_PROXY_ALLOWED_GROUPS=chrome-users              # Generic OIDC groups claim
# OAUTH2_PROXY_AUTHENTICATED_EMAILS_FILE=emails.txt     # Email allowlist

# Only enable this if your Provider uses a self-signed / untrusted certificate.
# In production, prefer adding the CA to the system trust store.
OAUTH2_PROXY_SSL_INSECURE_SKIP_VERIFY=true
```

> `OAUTH2_PROXY_OIDC_ISSUER_URL` 必须指向 Issuer 根目录，且该 URL 下可访问 `/.well-known/openid-configuration`。

## 启动 OIDC 模式

```bash
# 1. 编辑 .env，设置 AUTH_MODE=oidc
# 2. 编辑反代配置 configs/openresty-chrome-oidc.conf 中的域名和证书路径
# 3. 应用反代配置
./scripts/apply-auth-mode.sh

# 4. 启动容器（包含 Chromium + OAuth2-Proxy）
docker compose --profile oidc up -d
```

## 切换回 Basic Auth

```bash
AUTH_MODE=basic ./scripts/apply-auth-mode.sh
```

## 验证

1. 浏览器访问 `https://chrome.example.com:8443/`
2. 应看到 OAuth2-Proxy 的 "Sign in" 按钮
3. 点击后跳转 Provider 登录页
4. 登录后自动进入 KasmVNC 桌面

## 常见问题

### 登录后白屏

检查 OAuth2-Proxy 日志：

```bash
docker logs oauth2-proxy-remote-chromium
```

常见原因：
- OIDC Provider redirect URI 配置错误
- `OAUTH2_PROXY_COOKIE_DOMAIN` 与访问域名不匹配
- 授权限制参数（role/group/email）未正确分配给用户

### Provider 要求更新账户信息

确保用户已填写必要 profile 字段，或关闭 Provider 的必填校验。

### 502 Bad Gateway

- 检查 OAuth2-Proxy 是否运行
- 检查 OpenResty 是否指向 `http://127.0.0.1:4181/`
- **不要** 同时启用 OAuth2-Proxy 的 `--reverse-proxy=true`

### OIDC discovery 失败

确认 issuer URL 返回标准的 `/.well-known/openid-configuration` JSON。

```bash
curl https://auth.example.com:8443/realms/your-realm/.well-known/openid-configuration
```

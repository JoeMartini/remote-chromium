# 完整部署文档

## 1. 环境准备

- Linux 服务器（推荐 Ubuntu 22.04 / Rocky Linux 9）
- Docker 20.10+ 已安装
- 至少 2GB 空闲内存，4GB 推荐
- 开放一个 HTTPS 端口用于 KasmVNC 反代（如 8443）

## 2. 一键部署

```bash
curl -fsSL https://raw.githubusercontent.com/JoeMartini/remote-chromium/main/scripts/quickstart.sh | bash
cd ~/remote-chromium
```

或手动克隆：

```bash
git clone https://github.com/JoeMartini/remote-chromium.git
cd remote-chromium
cp examples/.env.example .env
```

## 3. 配置

编辑 `.env`：

```bash
vim .env
```

关键配置项：

| 变量 | 说明 | 默认值 |
|---|---|---|
| `KASM_HTTP_PORT` | KasmVNC HTTP 端口 | 3800 |
| `CHROME_CDP_PROXY_PORT` | CDP 代理端口 | 9224 |
| `AUTH_MODE` | 鉴权模式：basic / oidc | basic |
| `AUTH_MODE=basic` 时 | | |
| `CHROME_AUTH_USER` | Basic Auth 用户名 | your-user |
| `CHROME_AUTH_PASS` | Basic Auth 密码 | your-password |
| `AUTH_MODE=oidc` 时 | | |
| `KEYCLOAK_BASE_URL` | OIDC Provider 地址 | — |
| `KEYCLOAK_REALM` | OIDC Provider realm | — |
| `CHROME_DOMAIN` | 对外域名 | chrome.example.com |

## 4. 准备 Chrome 扩展（可选）

如果你使用 OpenCLI Bridge 扩展：

```bash
./scripts/install-extension.sh
```

或手动将扩展解压到 `./extensions/<name>/`，每个子目录需包含 `manifest.json`。

扩展 ID 需要与 `configs/managed_policies.json` 中配置的 ID 一致（如需强制安装）。

## 5. 启动

```bash
./scripts/start.sh
```

## 6. 配置反向代理

### Basic Auth

1. 生成密码文件：
```bash
htpasswd -cb /path/to/.htpasswd your-user your-password
```

2. 编辑 `configs/openresty-chrome-basic.conf`，替换占位符：
   - `CHROME_DOMAIN` → 你的域名
   - `CHROME_HTTPS_PORT` → 对外端口
   - `KASM_HTTP_PORT` → KasmVNC 端口
   - 证书路径和 htpasswd 路径

3. 部署配置：
```bash
AUTH_MODE=basic ./scripts/apply-auth-mode.sh
```

### OIDC

详见 [`docs/OIDC.md`](OIDC.md)。

## 7. 登录网站

1. 访问 `https://your-domain:8443/`
2. 通过 Basic Auth 或 OIDC 登录
3. 在 Chromium 中打开目标网站并登录
4. 登录态持久化到 `./config/chromium/`，重启容器后仍然有效

## 8. 使用 CDP 端点

### OpenCLI

```bash
export OPENCLI_CDP_ENDPOINT=http://localhost:9224
opencli doctor
opencli zhihu whoami
opencli xiaohongshu search "上海咖啡" --limit 5
```

### Puppeteer

```javascript
const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://localhost:9224'
});
```

### Playwright

```javascript
const browser = await chromium.connectOverCDP('http://localhost:9224');
```

## 9. 安全建议

- CDP 端口（9224）只监听 localhost，不要直接暴露到公网
- 反代必须加 Basic Auth 或更强的认证
- 定期备份 `./config/` 目录
- 修改 `.env` 中的默认账号密码

# Remote Chromium

在 headless Linux 服务器（ECS、VPS、NAS）上运行 Chromium 的开箱即用方案。

基于 [linuxserver/baseimage-kasmvnc](https://github.com/linuxserver/docker-baseimage-kasmvnc) 构建容器，提供：

- 🖥️ 远程 KasmVNC Web 桌面（浏览器即桌面）
- 🔌 CDP 端点暴露（任何支持 CDP 的工具都能接入）
- 🧩 Chrome 扩展自动加载（OpenCLI Bridge、广告拦截等）
- 💾 登录态与用户数据持久化
- 🔐 反向代理：Basic Auth 或 OIDC（Keycloak / Auth0 / Authing 等）

> **与 OpenCLI 的关系：** 本项目最初是 [OpenCLI](https://github.com/jackwener/opencli) 的 `server-browser/` 子目录，为无 GUI 服务器提供浏览器桥接。现已独立为一个通用的远程 Chromium 方案，OpenCLI 仍是主要用例之一，但不强制依赖。

## 一句话原理

```
服务器 = headless Linux
容器内 = KasmVNC + X11 + Chromium + 你选的扩展
CDP  →  socat 代理到宿主机端口
用户 →  HTTPS 反代访问 KasmVNC 桌面
```

## 适用场景

- 服务器没有 GUI，但需要浏览器自动化（CDP / Puppeteer / Playwright / OpenCLI）
- 想在一个长期运行的远程浏览器里登录微信、小红书、知乎、携程等网站
- 希望 CLI 工具能复用这些登录态
- 已有 OIDC 环境，希望复用 SSO

## 快速开始

```bash
# 一键部署
curl -fsSL https://raw.githubusercontent.com/JoeMartini/remote-chromium/main/scripts/quickstart.sh | bash

# 编辑配置
cd ~/remote-chromium
vim .env

# 启动
./scripts/start.sh
```

访问（域名和端口在 `.env` 中配置）：

```
https://your-domain:8443/
```

## 环境要求

- Linux 服务器（已测试 Ubuntu 22.04 / Rocky Linux 9）
- Docker 已安装并运行
- 可选：OpenResty / Nginx / Caddy 做反向代理
- OIDC 模式：运行中的 OIDC Provider

## 鉴权模式

### Basic Auth

OpenResty 层使用 `auth_basic` + `.htpasswd`，适合简单部署。

```bash
AUTH_MODE=basic
./scripts/apply-auth-mode.sh
```

### OIDC

通过 OAuth2-Proxy 接入标准 OIDC Provider（Keycloak、Auth0、Authing、Dex、Authentik 等）。

```bash
AUTH_MODE=oidc
./scripts/apply-auth-mode.sh
```

详见 [`docs/OIDC.md`](docs/OIDC.md)。

## 工作模式

### 1. 容器启动

- KasmVNC 监听容器内 `3800/3801`
- Chromium 监听 CDP `9222`（localhost only）
- `socat` 将 CDP 代理到宿主机 `9224`
- 任何 CDP 客户端通过 `http://localhost:9224` 连入

### 2. 用户登录

1. 访问反代地址（如 `https://your-domain:8443/`）
2. 通过 Basic Auth 或 OIDC 登录
3. 在 Chromium 中打开目标网站并登录
4. 登录态自动持久化到 `./config/chromium/`

### 3. CDP 客户端接入

**OpenCLI：**
```bash
export OPENCLI_CDP_ENDPOINT=http://localhost:9224
opencli doctor
opencli zhihu whoami
opencli xiaohongshu search "上海咖啡" --limit 5
```

**Puppeteer / Playwright：**
```javascript
const browser = await puppeteer.connect({
  browserWSEndpoint: 'ws://localhost:9224'
});
```

## 加载自定义扩展

将扩展解压到 `./extensions/<name>/`，在 `.env` 中配置：

```bash
# 多个扩展用冒号分隔
CHROME_EXTENSIONS_DIR=./extensions/opencli-webstore:./extensions/ublock
```

扩展 ID 需要与 `configs/managed_policies.json` 中的 `ExtensionInstallForcelist` 匹配（如果要强制安装）。

## 核心文件

| 文件 | 说明 |
|---|---|
| `scripts/quickstart.sh` | 一键拉取并启动 |
| `scripts/start.sh` | 容器启动脚本 |
| `scripts/stop.sh` | 容器停止脚本 |
| `scripts/install-extension.sh` | 下载扩展（默认 OpenCLI Bridge） |
| `scripts/apply-auth-mode.sh` | 切换 basic/oidc 鉴权模式 |
| `configs/Dockerfile` | 容器镜像构建文件 |
| `configs/autostart` | KasmVNC openbox 自动启动 Chromium |
| `configs/socat-cdp.sh` | 将 CDP 从 127.0.0.1 代理到 0.0.0.0 |
| `configs/managed_policies.json` | Chrome 策略：强制加载扩展 |
| `configs/openresty-chrome-basic.conf` | Basic Auth 反代配置 |
| `configs/openresty-chrome-oidc.conf` | OIDC 反代配置 |
| `configs/oauth2-proxy.env.example` | OAuth2-Proxy 环境变量模板 |
| `docker-compose.yml` | Docker Compose 一键启动 |
| `examples/.env.example` | 环境变量模板 |
| `docs/DEPLOYMENT.md` | 完整部署文档 |
| `docs/REVERSE_PROXY.md` | 反向代理配置指南 |
| `docs/OIDC.md` | OIDC 认证指南 |
| `docs/TROUBLESHOOTING.md` | 常见问题排查 |

## 目录结构

```
remote-chromium/
├── configs/
│   ├── Dockerfile
│   ├── autostart
│   ├── socat-cdp.sh
│   ├── managed_policies.json
│   ├── openresty-chrome-basic.conf
│   ├── openresty-chrome-oidc.conf
│   └── oauth2-proxy.env.example
├── scripts/
│   ├── quickstart.sh
│   ├── start.sh
│   ├── stop.sh
│   ├── install-extension.sh
│   └── apply-auth-mode.sh
├── examples/
│   └── .env.example
├── docs/
│   ├── DEPLOYMENT.md
│   ├── OIDC.md
│   ├── REVERSE_PROXY.md
│   └── TROUBLESHOOTING.md
├── docker-compose.yml
├── LICENSE
└── README.md
```

## 安全提示

- CDP 端口（9224）默认只监听 localhost，不要直接暴露到公网
- 反代务必加 Basic Auth / OIDC / TLS 客户端认证
- 修改 `.env` 中的默认账号密码
- 不要将真实 `.env` 或 `oauth2-proxy.env` 文件提交到 Git

## 致谢

- [linuxserver.io](https://www.linuxserver.io/) — baseimage-kasmvnc 基础镜像
- [OpenCLI](https://github.com/jackwener/opencli) — Browser Bridge 扩展与 CLI 工具
- [OAuth2-Proxy](https://oauth2-proxy.github.io/) — OIDC 认证代理

## 许可证

MIT

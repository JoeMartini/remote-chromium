# Agent / Skill 集成指南

Remote Chromium 提供标准的 CDP (Chrome DevTools Protocol) 端点，任何支持 CDP 的工具都可以接入。本文档说明如何从自动化代理（Hermes Agent、自定义脚本、Puppeteer/Playwright 等）连接并使用远程浏览器。

## 连接信息

容器启动后，CDP 端点暴露在宿主机：

```
http://localhost:9224
WebSocket: ws://localhost:9224
```

验证连接：

```bash
curl http://localhost:9224/json/version
```

应返回类似：

```json
{
  "Browser": "Chromium/1xx.0.xxxx.xx",
  "webSocketDebuggerUrl": "ws://localhost:9224"
}
```

## OpenCLI 集成

OpenCLI 是最直接的使用方式，通过 Browser Bridge 扩展与 Chromium 通信。

```bash
export OPENCLI_CDP_ENDPOINT=http://localhost:9224
opencli doctor                    # 验证连接
opencli zhihu whoami              # 知乎
opencli xiaohongshu search "咖啡" # 小红书
opencli ctrip hotel-search 327 --checkin 2026-07-15 --checkout 2026-07-16
```

## Hermes Agent 集成

### 方式 1：通过 OpenCLI 适配器

在 Hermes Agent 的 OpenCLI 会话中设置 CDP 端点：

```bash
# 在 agent 的 shell 环境中设置
export OPENCLI_CDP_ENDPOINT=http://localhost:9224
```

或在 `~/.bashrc` / `/etc/profile.d/` 中持久化：

```bash
echo 'export OPENCLI_CDP_ENDPOINT=http://localhost:9224' >> /etc/profile.d/opencli-cdp.sh
```

### 方式 2：通过 Shell 脚本调用 CDP

Agent 可以通过 curl 直接操作 CDP：

```bash
# 列出所有标签页
curl -s http://localhost:9224/json | jq '.[].url'

# 打开新标签页
curl -s http://localhost:9224/json/new?https://example.com

# 关闭标签页
curl -s -X DELETE http://localhost:9224/json/close/<targetId>
```

### 方式 3：通过 Puppeteer Node.js 脚本

```javascript
const puppeteer = require('puppeteer');

async function main() {
  const browser = await puppeteer.connect({
    browserWSEndpoint: 'ws://localhost:9224'
  });

  const page = await browser.newPage();
  await page.goto('https://example.com');
  const title = await page.title();
  console.log('Page title:', title);

  // 不要 close()，保持浏览器运行
  // await browser.close();
}

main();
```

### 方式 4：通过 Playwright Python 脚本

```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.connect_over_cdp('http://localhost:9224')
    context = browser.contexts[0] if browser.contexts else browser.new_context()
    page = context.new_page()
    page.goto('https://example.com')
    print(page.title())
    # 不要 close，保持会话
```

## 关键注意事项

### 1. 不要关闭浏览器

Agent 脚本使用 `connect` / `connect_over_cdp` 连接已有浏览器实例，**不要调用 `browser.close()`**，否则会终止容器内的 Chromium 进程。

### 2. 登录态共享

所有连接到同一 CDP 端点的客户端共享同一个 Chromium 实例和登录态。用户通过 KasmVNC 桌面登录的网站，Agent 脚本可以直接访问。

### 3. 并发限制

Chromium 是单进程实例，不适合高并发场景。如果 Agent 需要同时操作多个页面，使用多个标签页（tab）而非多个浏览器实例。

### 4. 超时处理

远程浏览器通过网络操作，响应可能比本地慢。建议：

- Puppeteer: `timeout: 60000`（60 秒）
- Playwright: `timeout=60000`
- curl: `--max-time 30`

### 5. 调试

查看浏览器状态：

```bash
# 所有打开的标签页
curl -s http://localhost:9224/json | jq '.[] | {title, url}'

# 浏览器版本
curl -s http://localhost:9224/json/version | jq .
```

查看容器日志：

```bash
docker logs remote-chromium --tail 50
```

## 健康检查脚本

```bash
#!/bin/bash
# healthcheck.sh — 检查 Remote Chromium 是否正常运行
CDP_ENDPOINT="${CDP_ENDPOINT:-http://localhost:9224}"

if curl -sf "$CDP_ENDPOINT/json/version" >/dev/null 2>&1; then
    echo "OK: Chromium is running"
    curl -s "$CDP_ENDPOINT/json/version" | jq -r '.Browser'
    exit 0
else
    echo "FAIL: Cannot connect to CDP at $CDP_ENDPOINT"
    exit 1
fi
```

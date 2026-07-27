# 常见问题排查

## 容器启动失败

检查日志：

```bash
docker logs remote-chromium
```

常见原因：
- 端口被占用：修改 `.env` 中的 `KASM_HTTP_PORT`/`KASM_HTTPS_PORT`
- 权限问题：确认 `PUID`/`PGID` 与宿主机用户一致
- 扩展目录不存在：确认 `extensions/` 下有包含 `manifest.json` 的子目录
- 共享内存不足：增大 `CHROME_SHM_SIZE`

## CDP 连接失败

1. 确认 CDP 代理可访问：

```bash
curl http://localhost:9224/json/version
```

2. 确认 Chromium 已启动：

```bash
docker exec remote-chromium ps aux | grep chromium
```

3. 检查 socat 是否在运行：

```bash
docker exec remote-chromium ps aux | grep socat
```

## 扩展未加载

1. 确认扩展目录挂载正确：

```bash
docker exec remote-chromium ls -la /config/extensions/
```

2. 确认每个扩展子目录包含 `manifest.json`：

```bash
docker exec remote-chromium find /config/extensions -name manifest.json
```

3. 如使用 `managed_policies.json` 强制安装，确认扩展 ID 匹配。

## 网站要求重新登录

登录态保存在 `./config/chromium/`。如果容器重建时未正确挂载该目录，登录态会丢失。

检查挂载：

```bash
docker inspect remote-chromium | grep -A5 '"Source"'
```

## 风控/验证码

- 部分网站会识别数据中心 IP，触发验证码
- 可尝试通过代理或住宅 IP 访问
- KasmVNC 内的浏览器与普通桌面浏览器行为一致，但仍可能被风控

## 性能问题

- 内存不足：增加服务器内存或减小 `CHROME_SHM_SIZE`
- 画面卡顿：调低 KasmVNC 画质，或检查网络延迟
- CPU 占用高：确认 `LIBGL_ALWAYS_SOFTWARE=1`（软件渲染），这是 headless 环境的正常行为

## KasmVNC 显示黑屏

1. 确认 Xvfb 已启动：
```bash
docker exec remote-chromium ps aux | grep Xvfb
```

2. 确认 openbox 窗口管理器在运行：
```bash
docker exec remote-chromium ps aux | grep openbox
```

3. 确认 Chromium 进程存在：
```bash
docker exec remote-chromium ps aux | grep chromium
```

## 端口映射冲突

本项目使用 `network_mode: host`，所有端口直接使用宿主机网络。如果端口被占用：

```bash
# 检查端口占用
ss -tlnp | grep -E '3800|3801|9222|9224'

# 修改 .env 中的端口配置
vim .env
```

# Remote Chromium
# 基于 linuxserver/baseimage-kasmvnc 构建，适用于 headless 服务器的 Chromium 容器。

FROM lscr.io/linuxserver/baseimage-kasmvnc:debianbookworm

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1

# 安装 Chromium、中文字体、扩展/调试所需工具
RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        chromium \
        fonts-wqy-zenhei fonts-wqy-microhei fonts-noto-cjk fonts-noto-color-emoji \
        libnss3 libgbm1 libasound2 libxss1 \
        curl ca-certificates locales \
        socat \
        xdotool xclip \
        perl; \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# KasmVNC web 客户端补丁（IME 中文输入修复）
# 移植自 WechatOnCloud 项目：
#   (1) 默认开启 IME 输入模式
#   (2) 修复 noVNC composition 事件导致的拼音中间态泄漏 + 退格风暴
#   成品中文文本由前端通过 xclip/xdotool 粘贴，绕开 VNC keysym 限制
COPY configs/patches/kasmvnc-ime-patch.sh configs/patches/ime-patch.pl /tmp/patches/
RUN chmod +x /tmp/patches/kasmvnc-ime-patch.sh && \
    /tmp/patches/kasmvnc-ime-patch.sh && \
    rm -rf /tmp/patches

# 精简 KasmVNC web UI：隐藏多余操作栏按钮，只保留 Clipboard / Fullscreen / Settings / Keys
COPY configs/patches/kasmvnc-ui-custom.css /usr/share/kasmvnc/www/dist/ui-custom.css
COPY configs/patches/kasmvnc-clipboard-init.js /usr/share/kasmvnc/www/dist/clipboard-init.js
# 注入自定义 CSS（精简 UI）和 JS（剪贴板/IME 自动初始化）到 vnc.html
RUN sed -i 's|</head>|<link rel="stylesheet" href="/dist/ui-custom.css">\n<script src="/dist/clipboard-init.js"></script></head>|' /usr/share/kasmvnc/www/vnc.html

# Chrome 扩展和管理策略
# 扩展在运行时通过 volume 挂载到 /config/extensions/（主渠道）
# 构建时也从 build context 的 extensions/ 复制到 /opt/extensions/ 作为 fallback
# 注意：build context 的 extensions/ 目录必须存在（仓库内有 .gitkeep 占位）
COPY extensions/ /opt/extensions/
COPY configs/managed_policies.json /etc/chromium/policies/managed/managed_policies.json

# KasmVNC openbox autostart：启动 Chromium + CDP + socat 代理
COPY configs/autostart /defaults/autostart
RUN chmod 755 /defaults/autostart

# socat 脚本：将容器内 localhost:9222 的 CDP 代理到 127.0.0.1:9224
COPY configs/socat-cdp.sh /opt/socat-cdp.sh
RUN chmod 755 /opt/socat-cdp.sh

# KasmVNC 默认端口 3000/3001；通过环境变量 CUSTOM_PORT / CUSTOM_HTTPS_PORT 可修改
EXPOSE 3000 3001

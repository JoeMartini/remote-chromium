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
        xdotool xclip; \
    sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen; \
    locale-gen; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Chrome 扩展和管理策略
# 构建时从 build context 的 extensions/ 目录复制
COPY extensions/ /opt/extensions/
COPY configs/managed_policies.json /etc/chromium/policies/managed/managed_policies.json

# KasmVNC openbox autostart：启动 Chromium + CDP + socat 代理
COPY configs/autostart /defaults/autostart
RUN chmod 755 /defaults/autostart

# socat 脚本：将容器内 localhost:9222 的 CDP 代理到 0.0.0.0:9224
COPY configs/socat-cdp.sh /opt/socat-cdp.sh
RUN chmod 755 /opt/socat-cdp.sh

# KasmVNC 默认端口 3000/3001；通过环境变量 CUSTOM_PORT / CUSTOM_HTTPS_PORT 可修改
EXPOSE 3000 3001

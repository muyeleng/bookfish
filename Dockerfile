# ==========================================
# 1. 使用官方 Debian 瘦身版 Node 镜像 (解决 glibc 兼容性与内存泄露)
# ==========================================
FROM node:20-slim

# 设置工作目录
WORKDIR /app

# 安装极其轻量的下载解压工具
RUN apt-get update && apt-get install -y wget unzip && rm -rf /var/lib/apt/lists/*

# ==========================================
# 2. 多架构自动匹配与官方源安全拉取
# ==========================================
# 逻辑：自动识别当前是 AMD 还是 ARM，拉取对应官方包，并在构建时重命名为伪装文件名
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "x86_64" ]; then \
        XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip" && \
        CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        XRAY_URL="https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-arm64-v8a.zip" && \
        CF_URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"; \
    else \
        echo "Unsupported architecture: $ARCH" && exit 1; \
    fi && \
    # 下载 Xray 并伪装为 sys_core
    wget -q -O xray.zip $XRAY_URL && \
    unzip -q xray.zip xray && \
    mv xray sys_core && \
    rm xray.zip && \
    chmod +x sys_core && \
    # 下载 Cloudflared 并伪装为 net_daemon
    wget -q -O net_daemon $CF_URL && \
    chmod +x net_daemon

# ==========================================
# 3. 注入业务代码 (零第三方依赖)
# ==========================================
# 把混淆后的网关代码和伪装页面拷进去。不需要 package.json，不需要 npm install！
COPY index.js index.html ./

# 暴露外层网关端口
EXPOSE 3000

# 容器启动命令
CMD ["node", "index.js"]

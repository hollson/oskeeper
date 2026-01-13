你需要一份在 Ubuntu 22.04 上用 Docker 快速部署 Headscale（私有 Tailscale 控制端）+ DERP（中继服务器）的完整配置和客户端接入步骤，我这就为你提供可直接复用的实操指南。

### 前置条件
1. 一台 Ubuntu 22.04 服务器（需公网 IP，推荐 1核2G 及以上）
2. 已安装 Docker 和 Docker Compose（下方会提供安装命令）
3. 一个域名（如 `headscale.yourdomain.com`），并将 A 记录解析到服务器公网 IP
4. 服务器开放端口：UDP 41641、TCP 80/443（用于 SSL 证书和 Headscale 通信）

---

## 第一步：安装 Docker 和 Docker Compose
先确保服务器有基础环境，执行以下命令：
```bash
# 更新系统包
sudo apt update && sudo apt upgrade -y

# 安装 Docker 依赖
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# 添加 Docker GPG 密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 添加 Docker 源
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装 Docker 和 Docker Compose
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# 把当前用户加入 docker 组（避免每次用 sudo）
sudo usermod -aG docker $USER
newgrp docker

# 验证安装
docker --version && docker compose version
```

## 第二步：编写 Docker Compose 配置文件
创建专属目录并编写配置，一键启动 Headscale + DERP：
```bash
# 创建工作目录
mkdir -p ~/headscale && cd ~/headscale

# 创建 docker-compose.yml 文件
cat > docker-compose.yml << EOF
version: "3.8"

services:
  headscale:
    image: headscale/headscale:latest
    container_name: headscale
    restart: unless-stopped
    volumes:
      - ./config:/etc/headscale
      - ./data:/var/lib/headscale
    ports:
      - "8080:8080"       # HTTP（用于 ACME 证书）
      - "41641:41641/udp" # Tailscale 通信端口
    environment:
      - TZ=Asia/Shanghai
    command: ["serve"]
    depends_on:
      - derper

  derper:
    image: fredliang/derper:latest
    container_name: derper
    restart: unless-stopped
    ports:
      - "3478:3478/udp"   # DERP 中继端口
      - "8443:8443/tcp"   # DERP HTTPS 端口
    environment:
      - DERP_DOMAIN=headscale.yourdomain.com  # 替换成你的域名
      - DERP_CERT_MODE=auto                   # 自动申请 SSL 证书
      - DERP_STUN=true                        # 启用 STUN
      - TZ=Asia/Shanghai
EOF

# 创建 Headscale 配置文件目录
mkdir -p ~/headscale/config

# 生成 Headscale 基础配置（替换域名）
cat > ~/headscale/config/config.yaml << EOF
server_url: https://headscale.yourdomain.com:8443  # 替换成你的域名
listen_addr: 0.0.0.0:8080
metrics_listen_addr: 0.0.0.0:9090
grpc_listen_addr: 0.0.0.0:50443
grpc_allow_insecure: false

private_key_path: /var/lib/headscale/private.key
noise:
  private_key_path: /var/lib/headscale/noise_private.key

ip_prefixes:
  - 100.64.0.0/10
  - fd7a:115c:a1e0::/48

db_path: /var/lib/headscale/db.sqlite
db_type: sqlite3

acme_url: https://acme-v02.api.letsencrypt.org/directory
acme_email: your-email@example.com  # 替换成你的邮箱（用于 SSL 证书）
tls_letsencrypt_hostname: headscale.yourdomain.com  # 替换成你的域名
tls_letsencrypt_cache_dir: /var/lib/headscale/cache
tls_letsencrypt_challenge_type: HTTP-01

derp:
  servers:
    - name: "my-derp"
      address: headscale.yourdomain.com  # 替换成你的域名
      port: 8443
      stun_port: 3478
      stun_only: false
      region_id: 999
      region_code: "custom"
      region_name: "Custom DERP Server"
  auto_update_enabled: false
  fallback_regions: []
EOF
```

### 关键配置修改
务必替换以下 3 处内容：
1. `DERP_DOMAIN=headscale.yourdomain.com` → 你的域名
2. `server_url: https://headscale.yourdomain.com:8443` → 你的域名
3. `acme_email: your-email@example.com` → 你的邮箱（用于申请 Let's Encrypt 证书）

## 第三步：启动服务
```bash
# 启动 Headscale + DERP
cd ~/headscale
docker compose up -d

# 查看启动状态（确保两个容器都是 Up 状态）
docker compose ps

# 查看日志（排查错误）
docker compose logs -f headscale
```

## 第四步：初始化 Headscale 并添加用户/节点
### 1. 进入 Headscale 容器，创建用户
```bash
# 进入容器
docker exec -it headscale headscale users create myfirstuser  # 创建名为 myfirstuser 的用户

# 查看已创建的用户
docker exec -it headscale headscale users list
```

### 2. 客户端接入（以 Linux 为例）
先在需要接入的设备上安装 Tailscale 客户端，再执行以下命令：
```bash
# 安装 Tailscale（Ubuntu/Debian）
curl -fsSL https://tailscale.com/install.sh | sh

# 连接到私有 Headscale 服务器（替换域名和用户名）
sudo tailscale up --login-server=https://headscale.yourdomain.com:8443 --accept-routes --accept-dns --user=myfirstuser
```

执行后会输出一个 URL，复制该 URL 到浏览器打开，会看到一串授权码（如 `abc123`）。

### 3. 在服务器上授权节点
```bash
# 替换成你的授权码
docker exec -it headscale headscale nodes register --user=myfirstuser --key=abc123
```

授权成功后，客户端会自动获取 Tailscale IP（如 100.64.0.1），此时设备已接入私有 Tailscale 网络。

## 其他系统客户端接入示例
### Windows/macOS 客户端
1. 安装官方 Tailscale 客户端
2. 打开命令行（Windows 用管理员 PowerShell，macOS 用终端）：
```bash
# Windows
tailscale up --login-server=https://headscale.yourdomain.com:8443 --user=myfirstuser

# macOS
sudo tailscale up --login-server=https://headscale.yourdomain.com:8443 --user=myfirstuser
```
3. 同样复制 URL 授权，再在服务器执行 `nodes register` 完成授权。

### 手机客户端（iOS/Android）
1. 安装 Tailscale 客户端
2. 进入设置 → 高级 → 自定义控制服务器，输入：`https://headscale.yourdomain.com:8443`
3. 返回主界面登录，复制授权码到服务器授权即可。

---

### 总结
1. **部署核心**：通过 Docker Compose 一键启动 Headscale（私有控制端）+ DERP（中继），只需替换域名和邮箱即可完成基础配置；
2. **接入流程**：客户端安装 Tailscale → 指定私有 Headscale 服务器地址 → 复制授权码 → 服务器端执行授权命令；
3. **关键端口**：需确保服务器开放 UDP 41641（节点通信）、TCP 8443（DERP/API）、TCP 80（SSL 证书验证），否则会导致证书申请失败或节点无法连接。

如果启动后遇到证书申请失败、节点无法上线等问题，可以先检查域名解析是否生效、端口是否开放，或通过 `docker compose logs -f headscale` 查看具体错误日志。
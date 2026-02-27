# Forgejo 14.0.2 最终版安装文档（Ubuntu 22.04）
## 核心信息
- 系统：Ubuntu 22.04 | 用户：shundong | IP：192.168.1.10
- 安装路径：/usr/local/bin/forgejo | 工作目录：~/.local/forgejo
- Web端口：18080 | SSH端口：10022 | 域名：hub.shundong.xyz | 数据库：SQLite3

## 一、调整说明
基于你补充的IP、用户名、Nginx域名信息，仅需微调**配置文件中的ROOT_URL**（适配域名访问），其余命令无需修改，以下是完整可执行文档：

## 二、完整安装命令
### 1. 创建工作目录
```bash
mkdir -p ~/.local/forgejo/{conf,data,logs,repositories,attachments,lfs}
```

### 2. 下载并安装指定版本二进制包
```bash
sudo wget -O /usr/local/bin/forgejo https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64
sudo chmod 755 /usr/local/bin/forgejo
```

### 3. 创建配置文件（适配Nginx域名+指定用户）
```bash
cat > ~/.local/forgejo/conf/app.ini << EOF
[DEFAULT]
APP_NAME = shundong Forgejo Hub
RUN_USER = shundong
RUN_MODE = prod

[server]
DOMAIN           = hub.shundong.xyz
HTTP_PORT        = 18080
SSH_PORT         = 10022
ROOT_URL         = https://hub.shundong.xyz/  # 适配Nginx域名访问（建议HTTPS）
DISABLE_SSH      = false
SSH_LISTEN_PORT  = 10022
HTTP_LISTEN_ADDR = 127.0.0.1  # 仅本地监听，通过Nginx反向代理对外提供服务

[database]
DB_TYPE  = sqlite3
PATH     = ~/.local/forgejo/data/forgejo.db

[repository]
ROOT = ~/.local/forgejo/repositories

[repository.upload]
FILE_MAX_SIZE = 1024
MAX_FILES = 20

[attachment]
PATH = ~/.local/forgejo/attachments
MAX_SIZE = 2048
MAX_FILES = 10

[lfs]
PATH = ~/.local/forgejo/lfs

[log]
MODE = file
LEVEL = info
ROOT_PATH = ~/.local/forgejo/logs
EOF
```

### 4. Nginx反向代理配置（新增，适配域名访问）
```bash
# 创建Nginx配置文件
sudo cat > /etc/nginx/sites-available/hub.shundong.xyz << EOF
server {
    listen 80;
    server_name hub.shundong.xyz;
    # 重定向到HTTPS（可选，建议配置SSL）
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name hub.shundong.xyz;

    # SSL证书配置（替换为你的证书路径）
    ssl_certificate /etc/nginx/ssl/hub.shundong.xyz.crt;
    ssl_certificate_key /etc/nginx/ssl/hub.shundong.xyz.key;

    # 反向代理Forgejo Web服务
    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # 静态资源缓存（优化访问速度）
    location ~ ^/(assets|img|css|js|fonts)/ {
        proxy_pass http://127.0.0.1:18080;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }
}
EOF

# 启用Nginx配置
sudo ln -s /etc/nginx/sites-available/hub.shundong.xyz /etc/nginx/sites-enabled/
# 检查Nginx配置并重启
sudo nginx -t
sudo systemctl restart nginx
```

### 5. 启动/停止/重启命令
```bash
# 前台启动（调试）
forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini

# 后台启动（生产）
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &

# 停止服务
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9

# 重启服务
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &
```

### 6. 初始化配置
1. 浏览器访问：`https://hub.shundong.xyz`（无需加端口）
2. 验证数据库（自动识别SQLite3）→ 创建管理员账号 → 点击「Install Forgejo」完成安装

### 7. 常用操作
```bash
# 查看日志
tail -f ~/.local/forgejo/logs/nohup.log

# 查看Forgejo进程
ps -ef | grep forgejo | grep -v grep

# 测试SSH端口
nc -zv 192.168.1.10 10022
```

### 总结
1. 核心调整：配置文件中`ROOT_URL`改为域名（适配Nginx）、`HTTP_LISTEN_ADDR`改为127.0.0.1（仅本地监听更安全）、指定`RUN_USER=shundong`；
2. 新增Nginx反向代理配置，实现域名直接访问（无需加端口）；
3. 所有启动/停止命令保持不变，仍无需systemd、无需创建独立用户组。

> 备注：若暂不配置SSL证书，可删除Nginx配置中的HTTPS部分，仅保留80端口反向代理即可。
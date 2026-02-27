# Forgejo 14.0.2 最终版安装文档（含管理员账号配置）
## 核心信息
- 系统：Ubuntu 22.04 | 用户：shundong | IP：192.168.1.10
- 安装路径：/usr/local/bin/forgejo | 工作目录：~/.local/forgejo
- Web端口：18080 | SSH端口：10022 | 域名：hub.shundong.xyz | 数据库：SQLite3
- 管理员账号：用户名 `admin`，密码 `123456`





## 一、核心调整
新增**命令行创建管理员账号**步骤，无需手动在Web页面配置，直接完成初始化，其余配置保持不变。

## 二、完整可执行命令
### 1. 创建工作目录
```bash
mkdir -p ~/.local/forgejo/{conf,data,logs,repositories,attachments,lfs}
```

### 2. 下载并安装指定版本二进制包
```bash
sudo wget -O /usr/local/bin/forgejo https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64
sudo chmod 755 /usr/local/bin/forgejo
```

### 3. 创建配置文件
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
ROOT_URL         = https://hub.shundong.xyz/
DISABLE_SSH      = false
SSH_LISTEN_PORT  = 10022
HTTP_LISTEN_ADDR = 127.0.0.1

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

### 4. Nginx反向代理配置
```bash
sudo cat > /etc/nginx/sites-available/hub.shundong.xyz << EOF
server {
    listen 80;
    server_name hub.shundong.xyz;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name hub.shundong.xyz;

    ssl_certificate /etc/nginx/ssl/hub.shundong.xyz.crt;
    ssl_certificate_key /etc/nginx/ssl/hub.shundong.xyz.key;

    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ ^/(assets|img|css|js|fonts)/ {
        proxy_pass http://127.0.0.1:18080;
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/hub.shundong.xyz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 5. 启动服务并创建管理员账号
```bash
# 后台启动Forgejo
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &

# 等待服务启动（约5秒）
sleep 5

# 命令行创建管理员账号（用户名admin，密码123456）
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user create \
  --username admin \
  --password 123456 \
  --email admin@shundong.xyz \
  --admin \
  --must-change-password=false
```

### 6. 常用操作命令
```bash
# 停止服务
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9

# 重启服务
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &

# 查看日志
tail -f ~/.local/forgejo/logs/nohup.log

# 验证管理员账号（可选）
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user list
```

## 三、访问验证
浏览器访问 `https://hub.shundong.xyz`，使用账号 `admin`、密码 `123456` 直接登录，无需Web初始化步骤。

### 总结
1. 新增命令行创建管理员账号（admin/123456），跳过Web初始化环节，直接完成部署；
2. 配置文件和Nginx反向代理适配域名访问，仅本地监听18080端口更安全；
3. 所有操作无需systemd、无需独立用户组，完全匹配你的安装要求。

> 注意：生产环境建议将管理员密码修改为更复杂的字符串，可执行 `forgejo admin user change-password --username admin` 命令修改。
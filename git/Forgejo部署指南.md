# Forgejo 14.0.2 最终版安装文档

[Forgejo](https://forgejo.org/) 是**轻量、开源、自托管**的 Git 代码托管平台，Gitea 社区分支，无商业锁、资源占用低，支持 Docker 一键部署。

## 核心信息
- 系统：Ubuntu 22.04 | 用户：shundong | IP：192.168.1.10
- 安装路径：/usr/local/bin/forgejo | 工作目录：~/.local/forgejo
- Web端口：18080 | SSH端口：10022 | 域名：hub.shundong.xyz | 数据库：SQLite3
- 管理员账号：用户名 `admin`，密码 `123456`

## 安装要求
- 使用二进制安装（简单快捷、对系统侵入性小，可随时安装或卸载）
- 不使用 systemd 服务
- 不创建 forgejo 独立用户和用户组，使用现有用户 shundong
- 系统已安装 git、ssh、wget、nc 等工具，无需重复安装

## 一、安装 Forgejo 二进制文件

### 1.1 下载并安装指定版本二进制包
```bash
# 创建工作目录
mkdir -p ~/.local/forgejo/{conf,data,logs,repositories,attachments,lfs,ssh}

# 下载 Forgejo 14.0.2 二进制文件
sudo wget -O /usr/local/bin/forgejo https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64

# 设置可执行权限
sudo chmod 755 /usr/local/bin/forgejo

# 验证安装
forgejo --version
```

### 1.2 验证二进制文件完整性（可选但推荐）
```bash
# 下载签名文件
wget https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64.asc

# 下载 Forgejo GPG 公钥
wget https://codeberg.org/forgejo/forgejo/raw/branch/forgejo/forgejo-keys.asc

# 导入公钥
gpg --import forgejo-keys.asc

# 验证签名
gpg --verify forgejo-14.0.2-linux-amd64.asc /usr/local/bin/forgejo
```

## 二、配置 Forgejo

### 2.1 创建配置文件
```bash
# 参考: https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini
cat > ~/.local/forgejo/conf/app.ini << 'EOF'
[DEFAULT]
APP_NAME = My Forgejo Hub
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
OFFLINE_MODE     = true
SSH_KEY_PATH     = ~/.local/forgejo/ssh
START_SSH_SERVER = true
LANDING_URL      = /

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW  = false
SHOW_REGISTRATION_BUTTON = false
ENABLE_NOTIFY_MAIL     = false

[database]
DB_TYPE  = sqlite3
PATH     = ~/.local/forgejo/data/forgejo.db
LOG_SQL  = false

[repository]
ROOT               = ~/.local/forgejo/repositories
DEFAULT_BRANCH     = main
ENABLE_PUSH_CREATE_USER   = true
ENABLE_PUSH_CREATE_ORG    = false

[repository.upload]
FILE_MAX_SIZE = 1024
MAX_FILES     = 20

[attachment]
PATH      = ~/.local/forgejo/attachments
MAX_SIZE  = 2048
MAX_FILES  = 10
ENABLED   = true

[lfs]
PATH     = ~/.local/forgejo/lfs
ENABLED  = true

[log]
MODE      = file
LEVEL     = info
ROOT_PATH = ~/.local/forgejo/logs
ENABLE_ACCESS_LOG = true

[security]
INSTALL_LOCK = true
SECRET_KEY    = CHANGE_ME_TO_RANDOM_STRING
INTERNAL_TOKEN = CHANGE_ME_TO_RANDOM_STRING

[picture]
DISABLE_GRAVATAR              = true
ENABLE_FEDERATED_AVATAR       = false

[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = false

[session]
PROVIDER = file
EOF
```

### 2.2 生成安全密钥
```bash
# 生成 SECRET_KEY
SECRET_KEY=$(openssl rand -hex 32)
# 生成 INTERNAL_TOKEN
INTERNAL_TOKEN=$(openssl rand -hex 32)

# 更新配置文件
sed -i "s/SECRET_KEY    = CHANGE_ME_TO_RANDOM_STRING/SECRET_KEY    = $SECRET_KEY/" ~/.local/forgejo/conf/app.ini
sed -i "s/INTERNAL_TOKEN = CHANGE_ME_TO_RANDOM_STRING/INTERNAL_TOKEN = $INTERNAL_TOKEN/" ~/.local/forgejo/conf/app.ini
```

## 三、配置 SSL 证书

### 3.1 生成自签名SSL证书（无域名环境）
```bash
# 创建SSL证书目录
sudo mkdir -p /etc/nginx/ssl

# 生成自签名证书（有效期365天）
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/hub.shundong.xyz.key \
  -out /etc/nginx/ssl/hub.shundong.xyz.crt \
  -subj "/C=CN/ST=State/L=City/O=Organization/CN=hub.shundong.xyz"

# 设置证书权限
sudo chmod 600 /etc/nginx/ssl/hub.shundong.xyz.key
sudo chmod 644 /etc/nginx/ssl/hub.shundong.xyz.crt

# 验证证书
sudo openssl x509 -in /etc/nginx/ssl/hub.shundong.xyz.crt -text -noout
```

### 3.2 配置本地 hosts 文件（测试环境）
```bash
# 在客户端机器上编辑 hosts 文件
# Windows: C:\Windows\System32\drivers\etc\hosts
# Linux/Mac: /etc/hosts

# 添加以下行（替换为实际服务器IP）
192.168.1.10 hub.shundong.xyz
```

## 四、配置 Nginx 反向代理

### 4.1 安装并配置 Nginx
```bash
# 安装 Nginx（如果未安装）
sudo apt update
sudo apt install nginx -y

# 启动 Nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

### 4.2 创建 Nginx 配置文件
```bash
sudo cat > /etc/nginx/conf.d/hub.shundong.xyz.conf << 'EOF'
# HTTP 重定向到 HTTPS
server {
    listen 80;
    server_name hub.shundong.xyz;
    return 301 https://$host$request_uri;
}

# HTTPS 配置
server {
    listen 443 ssl http2;
    server_name hub.shundong.xyz;

    # SSL证书配置
    ssl_certificate /etc/nginx/ssl/hub.shundong.xyz.crt;
    ssl_certificate_key /etc/nginx/ssl/hub.shundong.xyz.key;

    # SSL安全配置（推荐）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;

    # 安全头部
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 日志配置
    access_log /var/log/nginx/forgejo.access.log;
    error_log /var/log/nginx/forgejo.error.log;

    # 客户端上传大小限制
    client_max_body_size 1024M;

    # 代理配置
    location / {
        proxy_pass http://127.0.0.1:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-SSL on;
        
        # WebSocket支持
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 性能优化
        proxy_buffers 16 16k;
        proxy_buffer_size 32k;
        
        # 超时设置
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_redirect off;
    }
}
EOF
```

### 4.3 测试并重启 Nginx
```bash
# 测试 Nginx 配置
sudo nginx -t

# 重启 Nginx
sudo systemctl restart nginx

# 检查 Nginx 状态
sudo systemctl status nginx
```

## 五、启动 Forgejo 并创建管理员账号

### 5.1 启动 Forgejo 服务
```bash
# 后台启动Forgejo
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &

# 检查进程状态
ps -ef | grep forgejo

# 查看启动日志
tail -f ~/.local/forgejo/logs/nohup.log
```

### 5.2 停止 Forgejo 服务
```bash
# 查找并停止进程
pkill forgejo

# 或使用 kill 命令
# kill $(ps aux | grep '[f]orgejo web' | awk '{print $2}')
```

### 5.3 创建管理员账号
```bash
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

### 5.4 验证服务状态
```bash
# 检查 Forgejo 是否正常运行
ps -ef | grep forgejo

# 检查端口监听
netstat -tlnp | grep -E '18080|10022'

# 查看日志
tail -n 50 ~/.local/forgejo/logs/forgejo.log
```

## 六、SSH配置说明

Forgejo使用`~/.ssh/authorized_keys`管理Git SSH密钥，采用**共存模式**，不会影响系统现有SSH配置。

### 6.1 配置机制
- **共享authorized_keys**：Forgejo和系统SSH共用`~/.ssh/authorized_keys`
- **共存模式**：Forgejo添加的SSH密钥带有`command`前缀，用于Git操作；系统SSH密钥保持不变
- **互不干扰**：系统SSH登录和Forgejo Git操作可以同时使用

### 6.2 authorized_keys文件结构
```bash
# 系统SSH密钥（用于系统登录）
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host

# Forgejo SSH密钥（用于Git操作，带有command前缀）
command="/usr/local/bin/forgejo --config=/home/shundong/.local/forgejo/conf/app.ini serv key-1",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... forgejo-user@host
```

### 6.3 Git SSH使用方式
用户在Forgejo Web界面添加SSH公钥后，使用以下方式访问Git仓库：
```bash
# 克隆仓库
git clone ssh://git@hub.shundong.xyz:10022/username/repo.git

# 或使用简写（需在客户端~/.ssh/config中配置）
git clone git@hub.shundong.xyz:username/repo.git
```

### 6.4 配置SSH客户端简化访问
在客户端`~/.ssh/config`中添加：
```
Host hub.shundong.xyz
    HostName hub.shundong.xyz
    Port 10022
    User git
```
配置后可使用：`git clone git@hub.shundong.xyz:username/repo.git`

## 七、访问验证

浏览器访问 `https://hub.shundong.xyz`，使用账号 `admin`、密码 `123456` 直接登录，无需Web初始化步骤。

### 7.1 常见问题排查
```bash
# 检查 Forgejo 日志
tail -f ~/.local/forgejo/logs/forgejo.log

# 检查 Nginx 日志
tail -f /var/log/nginx/forgejo.error.log

# 检查端口监听
netstat -tlnp | grep -E '18080|10022|443'

# 检查防火墙
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10022/tcp
```

## 八、自签名证书使用说明

### 8.1 浏览器警告处理
由于使用自签名证书，首次访问 `https://hub.shundong.xyz` 时浏览器会显示安全警告：

**Chrome/Edge浏览器：**
1. 点击"高级"
2. 点击"继续前往 hub.shundong.xyz（不安全）"

**Firefox浏览器：**
1. 点击"高级"
2. 点击"接受风险并继续"

### 8.2 导入自签名证书到系统（可选）
如果希望浏览器信任该证书，可以导入到系统：

**Windows客户端：**
1. 双击 `/etc/nginx/ssl/hub.shundong.xyz.crt` 文件
2. 选择"安装证书"
3. 选择"本地计算机"
4. 选择"将所有证书放入下列存储" -> "受信任的根证书颁发机构"
5. 完成导入

**Linux客户端：**
```bash
sudo cp /etc/nginx/ssl/hub.shundong.xyz.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
```

### 8.3 Git操作信任自签名证书
```bash
# 临时信任（单次操作）
git -c http.sslVerify=false clone https://hub.shundong.xyz/username/repo.git

# 永久信任该域名
git config --global http.sslVerify false
# 或仅信任特定域名
git config --global http."https://hub.shundong.xyz".sslVerify false
```

## 九、常用管理命令

### 9.1 用户管理
```bash
# 修改管理员密码
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user change-password \
  --username admin --password new_password

# 创建普通用户
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user create \
  --username newuser --password password123 --email user@example.com

# 删除用户
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user delete \
  --username newuser
```

### 9.2 服务管理
```bash
# 启动服务
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &

# 停止服务
pkill forgejo

# 重启服务
pkill forgejo
sleep 2
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &
```

### 9.3 备份与恢复
```bash
# 备份数据库
cp ~/.local/forgejo/data/forgejo.db ~/.local/forgejo/data/forgejo.db.backup

# 备份仓库
tar -czf forgejo-repositories-backup.tar.gz ~/.local/forgejo/repositories

# 恢复数据库
cp ~/.local/forgejo/data/forgejo.db.backup ~/.local/forgejo/data/forgejo.db
```

## 十、总结

1. **安装方式**：使用二进制安装，简单快捷、对系统侵入性小，可随时安装或卸载
2. **服务管理**：不使用 systemd 服务，使用 nohup 后台运行，方便管理
3. **用户配置**：不创建 forgejo 独立用户和用户组，使用现有用户 shundong
4. **安全配置**：配置文件和Nginx反向代理适配域名访问，仅本地监听18080端口更安全
5. **SSH配置**：SSH采用共享模式，Forgejo和系统SSH共用`~/.ssh/authorized_keys`，互不干扰
6. **管理员账号**：命令行创建管理员账号（admin/123456），跳过Web初始化环节，直接完成部署
7. **证书配置**：使用自签名证书和hosts文件模拟域名环境，适合测试和开发场景

> 注意：生产环境建议将管理员密码修改为更复杂的字符串，可执行 `forgejo admin user change-password --username admin` 命令修改。

## 参考文档
- [Forgejo 官方文档](https://forgejo.org/docs/latest/)
- [Forgejo 二进制安装指南](https://forgejo.org/docs/latest/admin/installation/binary/)
- [Forgejo 配置示例](https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini)

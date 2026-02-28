# Forgejo 14.0.2 最终版安装文档



[Forgejo](https://forgejo.org/) 是**轻量、开源、自托管**的 Git 代码托管平台，Gitea 社区分支，无商业锁、资源占用低，支持 Docker 一键部署。



## 核心信息
- 系统：Ubuntu 22.04 | 用户：shundong | IP：192.168.1.10
- 安装路径：/usr/local/bin/forgejo | 工作目录：~/.local/forgejo
- Web端口：18080 | SSH端口：10022 | 域名：hub.shundong.xyz | 数据库：SQLite3
- 管理员账号：用户名 `admin`，密码 `123456`





## 一、核心调整
### 2. 下载并安装指定版本二进制包
```bash
mkdir -p ~/.local/forgejo/{conf,data,logs,repositories,attachments,lfs,ssh}

sudo wget -O /usr/local/bin/forgejo https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64
sudo chmod 755 /usr/local/bin/forgejo
```

### 3. 创建配置文件
```bash
# 参考: https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini
cat > ~/.local/forgejo/conf/app.ini << EOF
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
OFFLINE_MODE = true
SSH_KEY_PATH = ~/.local/forgejo/ssh
START_SSH_SERVER = true

[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = false

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

### 4. 生成自签名SSL证书（无域名环境）
```bash
# 创建SSL证书目录
sudo mkdir -p /etc/nginx/ssl

# 生成自签名证书（有效期365天）
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/nginx/ssl/hub.shundong.xyz.key \
  -out /etc/nginx/ssl/hub.shundong.xyz.crt \
  -subj "/C=CN/ST=State/L=City/O=Organization/CN=hub.shundong.xyz"

# 设置证书权限
sudo chmod 600 /etc/nginx/ssl/forgejo.key
sudo chmod 644 /etc/nginx/ssl/forgejo.crt

# 验证证书
sudo openssl x509 -in /etc/nginx/ssl/forgejo.crt -text -noout
```



### 6. Nginx反向代理配置
```bash
sudo cat > /etc/nginx/conf.d/forgejo.conf << EOF
# 完整模板，仅需要替换“192.168.X.X”和“git.shundong.xyz”即可
server {
    listen 80;
    server_name git.shundong.xyz;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name git.shundong.xyz;

    # SSL证书配置
    ssl_certificate /var/gitlab/gitlab.crt;
    ssl_certificate_key /var/gitlab/gitlab.key;

    # SSL安全配置（推荐）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # 安全头部
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 日志配置
    access_log /var/log/nginx/gitlab.access.log;
    error_log /var/log/nginx/gitlab.error.log;

    # 代理配置
    location / {
        proxy_pass http://192.168.X.X:9080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-SSL on;
        
        # WebSocket支持（GitLab需要）
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
EOF

sudo ln -s /etc/nginx/sites-available/hub.shundong.xyz /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### 7. 启动服务并创建管理员账号
```bash
# 后台启动Forgejo
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &
ps -ef|grep forgejo
pkill forgejo

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





## 三、SSH配置说明
Forgejo使用`~/.ssh/authorized_keys`管理Git SSH密钥，采用**共存模式**，不会影响系统现有SSH配置。

### 配置机制
- **共享authorized_keys**：Forgejo和系统SSH共用`~/.ssh/authorized_keys`
- **共存模式**：Forgejo添加的SSH密钥带有`command`前缀，用于Git操作；系统SSH密钥保持不变
- **互不干扰**：系统SSH登录和Forgejo Git操作可以同时使用

### authorized_keys文件结构
```bash
# 系统SSH密钥（用于系统登录）
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host

# Forgejo SSH密钥（用于Git操作，带有command前缀）
command="/usr/local/bin/forgejo --config=/home/shundong/.local/forgejo/conf/app.ini serv key-1",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... forgejo-user@host
```

### Git SSH使用方式
用户在Forgejo Web界面添加SSH公钥后，使用以下方式访问Git仓库：
```bash
# 克隆仓库
git clone ssh://git@hub.shundong.xyz:10022/username/repo.git

# 或使用简写（需在客户端~/.ssh/config中配置）
git clone git@hub.shundong.xyz:username/repo.git
```

### 可选：配置SSH客户端简化访问
在客户端`~/.ssh/config`中添加：
```
Host hub.shundong.xyz
    HostName hub.shundong.xyz
    Port 10022
    User git
```
配置后可使用：`git clone git@hub.shundong.xyz:username/repo.git`

## 四、访问验证
浏览器访问 `https://hub.shundong.xyz`，使用账号 `admin`、密码 `123456` 直接登录，无需Web初始化步骤。

### 总结
1. 新增命令行创建管理员账号（admin/123456），跳过Web初始化环节，直接完成部署；
2. 配置文件和Nginx反向代理适配域名访问，仅本地监听18080端口更安全；
3. SSH采用共享模式，Forgejo和系统SSH共用`~/.ssh/authorized_keys`，互不干扰；
4. 所有操作无需systemd、无需独立用户组，完全匹配你的安装要求；
5. 使用自签名证书和hosts文件模拟域名环境，适合测试和开发场景。

> 注意：生产环境建议将管理员密码修改为更复杂的字符串，可执行 `forgejo admin user change-password --username admin` 命令修改。

## 五、自签名证书使用说明

### 浏览器警告处理
由于使用自签名证书，首次访问 `https://hub.shundong.xyz` 时浏览器会显示安全警告：

**Chrome/Edge浏览器：**
1. 点击"高级"
2. 点击"继续前往 hub.shundong.xyz（不安全）"

**Firefox浏览器：**
1. 点击"高级"
2. 点击"接受风险并继续"

### 导入自签名证书到系统（可选）
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

### Git操作信任自签名证书
```bash
# 临时信任（单次操作）
git -c http.sslVerify=false clone https://hub.shundong.xyz/username/repo.git

# 永久信任该域名
git config --global http.sslVerify false
# 或仅信任特定域名
git config --global http."https://hub.shundong.xyz".sslVerify false
```
# Forgejo实操极简指南（安装+使用）
## 一、Forgejo简介
[Forgejo](https://forgejo.org/) 是**轻量、开源、自托管**的 Git 代码托管平台，Gitea 社区分支，无商业锁、资源占用低，支持 Docker 一键部署。



<br/>



## 二、Forgejo安装

```shell
系统信息：
- 系统：ubunru 22.4
- 用户：shundong
- IP：192.168.1.10

Forgejo安装信息：
- 版本：14.0.2
- 数据库：slqite3
- web端口:18080
- ssh端口:10022
- 公司/团队主体：shundong
- 安装路径：/usr/local/bin/forgejo
- 工作目录（数据、配置、日志等）：~/.local/forgejo
- Nginx域名：hub.shundong.xyz

Forgejo安装要求：
- 不使用systemd 
- 为了方便操作，无需创建forgejo独立用户和用户组
- 系统已安装了git，ssh，wget等，无需重复安装
```





Forgejo 每三个月发布一个稳定版本，每年发布一个长期支持 (LTS) 版本, 官网提供了详细的 [Forgejo安装教程](https://forgejo.org/docs/latest/admin/installation/)。

### 1. 创建目录
```bash
mkdir -p /srv/forgejo
cd /srv/forgejo

docker pull codeberg.org/forgejo/forgejo:14
```

### 2. 启动容器
```bash
docker run -d \
  --name forgejo \
  -p 9080:3000 \
  -p 9022:22 \
  -v $(pwd)/data:/data \
  -e USER_UID=1000 \
  -e USER_GID=1000 \
  --restart always \
  codeberg.org/forgejo/forgejo:latest
```

### 3. 访问初始化
浏览器打开：  
`http://服务器IP:3000`

首次直接点 **安装**（默认配置即可），注册第一个账号就是管理员。



<br/>



## 三、基础使用（实操）
### 1. 创建仓库
- 右上角 **+ → New Repository**
- 填仓库名 → 勾选是否公开 → **Create Repository**

### 2. 本地 Git 关联
```bash
git init
git add .
git commit -m "init"
git remote add origin http://IP:3000/用户名/仓库名.git
git push -u origin main
```

### 3. 克隆代码
```bash
git clone http://IP:3000/用户名/仓库名.git
```

### 4. 常用功能
- **Issues**：任务/Bug 管理
- **Pull Request**：代码合并
- **Release**：发布版本
- **组织/团队**：多成员权限管理

---

## 四、常用维护命令
```bash
# 启动
docker start forgejo

# 停止
docker stop forgejo

# 重启
docker restart forgejo

# 查看日志
docker logs -f forgejo
```

---







# 一、二进制安装


## 2. 下载二进制
```bash
# 下载二进制包
FORGEJO_VER="14.0.2"
wget https://codeberg.org/forgejo/forgejo/releases/download/v${FORGEJO_VER}/forgejo-${FORGEJO_VER}-linux-amd64

# 安装到系统目录
sudo mv forgejo-${FORGEJO_VER}-linux-amd64 /usr/local/bin/forgejo
chmod +x /usr/local/bin/forgejo

# 创建工作目录
mkdir -p ~/.local/forgejo
cd ~/.local/forgejo

# 启动程序
forgejo web
nohup forgejo web > forgejo.log 2>&1 &
http://你的IP:3000
```



https://codeberg.org/forgejo/forgejo/src/branch/forgejo/custom/conf/app.example.ini

```ini
; ########################### 全局配置 ###########################
APP_NAME = Forgejo: 自建代码托管平台
RUN_USER = forgejo       ; 运行 Forgejo 的系统用户（需提前创建）
RUN_MODE = prod          ; 运行模式：prod(生产)/dev(开发)

; ########################### 服务配置 ###########################
[server]
APP_DATA_PATH    = /var/lib/forgejo  ; 数据存储目录（需提前创建并授权）
DOMAIN           = git.example.com   ; 你的域名/服务器IP
HTTP_PORT        = 3000              ; HTTP 监听端口
ROOT_URL         = http://git.example.com:3000/  ; 外部访问的完整URL
DISABLE_SSH      = false             ; 启用SSH
SSH_PORT         = 9022                ; SSH端口（默认22，可修改）
SSH_LISTEN_PORT  = 9022                ; SSH监听端口
LFS_START_SERVER = true              ; 启用LFS（大文件存储）
OFFLINE_MODE     = false             ; 关闭离线模式（可加载外部资源）

; ########################### 数据库配置（SQLite，最简配置） ###########################
; 新手推荐使用SQLite（无需额外安装数据库），生产环境可替换为MySQL/PostgreSQL
[database]
DB_TYPE  = sqlite3
PATH     = /var/lib/forgejo/data/forgejo.db  ; SQLite数据库文件路径
LOG_SQL  = false                             ; 关闭SQL日志（生产环境建议关闭）

; ########################### MySQL 配置示例（替换SQLite用） ###########################
; [database]
; DB_TYPE  = mysql
; HOST     = 127.0.0.1:3306
; NAME     = forgejo
; USER     = forgejo
; PASSWD   = your_mysql_password
; CHARSET  = utf8mb4
; SSL_MODE = disable

; ########################### PostgreSQL 配置示例（替换SQLite用） ###########################
; [database]
; DB_TYPE  = postgres
; HOST     = 127.0.0.1:5432
; NAME     = forgejo
; USER     = forgejo
; PASSWD   = your_pg_password
; SSL_MODE = disable

; ########################### SSH 配置 ###########################
[ssh]
START_SERVER = true                   ; 启用内置SSH服务器
KEY_PATH     = /var/lib/forgejo/.ssh  ; SSH密钥存储目录

; ########################### 安全配置 ###########################
[security]
INSTALL_LOCK   = true                 ; 安装完成后锁定（防止重复安装）
SECRET_KEY     = your_secret_key      ; 随机密钥（可通过 forgejo generate secret SECRET_KEY 生成）
INTERNAL_TOKEN = your_internal_token  ; 内部令牌（可通过 forgejo generate secret INTERNAL_TOKEN 生成）

; ########################### 邮件配置（可选，用于通知/找回密码） ###########################
[mailer]
ENABLED       = false                 ; 先关闭，配置完成后改为true
FROM          = forgejo@example.com
PROTOCOL      = smtp
SMTP_ADDR     = smtp.example.com
SMTP_PORT     = 587
USER          = forgejo@example.com
PASSWD        = your_email_password
USE_TLS       = true
USE_SSL       = false

; ########################### 仓库配置 ###########################
[repository]
ROOT = /var/lib/forgejo/repositories  ; 代码仓库存储目录
DEFAULT_BRANCH = main                 ; 默认分支名

; ########################### 用户配置 ###########################
[user]
ALLOW_CREATE_ORGANIZATION = true      ; 允许用户创建组织
DEFAULT_KEEP_EMAIL_PRIVATE = true     ; 默认隐藏邮箱

; ########################### 日志配置 ###########################
[log]
MODE            = file                ; 日志输出方式：file(文件)/console(控制台)
LEVEL           = info                ; 日志级别：trace/debug/info/warn/error/critical
ROOT_PATH       = /var/log/forgejo    ; 日志存储目录

```

```shell
# 创建自定义配置目录
mkdir -p ~/.local/forgejo/conf

# 创建数据/日志/仓库目录（对应配置文件中的路径）
mkdir -p ~/.local/forgejo/{data,repositories,log,.ssh}

# 指定工作目录和配置文件启动
FORGEJO_SSH_AUTHORIZED_KEYS_PATH=~/.local/forgejo/ssh/authorized_keys_forgejo \
forgejo -w ~/.local/forgejo -c ~/.local/forgejo/conf/app.ini web --port 9080


# 创建 Forgejo 专用的 SSH 密钥文件
mkdir -p ~/.local/forgejo/ssh
touch ~/.local/forgejo/ssh/authorized_keys_forgejo
chmod 600 ~/.local/forgejo/ssh/authorized_keys_forgejo

FORGEJO_SSH_AUTHORIZED_KEYS_PATH=~/.local/forgejo/ssh/authorized_keys_forgejo \
forgejo admin user create \
  --username admin \
  --password "StrongPassword123!" \
  --email admin@example.com \
  --admin \
  -w ~/.local/forgejo -c ~/.local/forgejo/conf/app.ini
```





# 二、配置Nginx
新建文件：
```bash
vim /etc/nginx/conf.d/forgejo.conf
```

内容（把 `git.example.com` 换成你自己的域名）：
```nginx
server {
    listen 80;
    server_name git.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        client_max_body_size 500M;
    }
}
```

重启 Nginx：
```bash
nginx -t
systemctl restart nginx
```

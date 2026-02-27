# Forgejo 14.0.2 安装文档（Ubuntu 22.04）
## 核心信息
- 安装路径：/usr/local/bin/forgejo
- 工作目录：~/.local/forgejo
- Web端口：18080 | SSH端口：10022 | 域名：hub.shundong.xyz | 数据库：SQLite3 | 主体：shundong

## 一、创建工作目录结构
```bash
mkdir -p ~/.local/forgejo/{conf,data,logs,repositories,attachments,lfs}
```

## 二、下载并安装指定版本二进制包
```bash
# 下载Forgejo 14.0.2（amd64架构）
sudo wget -O /usr/local/bin/forgejo https://codeberg.org/forgejo/forgejo/releases/download/v14.0.2/forgejo-14.0.2-linux-amd64
# 添加可执行权限
sudo chmod 755 /usr/local/bin/forgejo
```

## 三、创建配置文件
```bash
cat > ~/.local/forgejo/conf/app.ini << EOF
[DEFAULT]
APP_NAME = shundong Forgejo Hub
RUN_USER = $(whoami)
RUN_MODE = prod

[server]
DOMAIN           = hub.shundong.xyz
HTTP_PORT        = 18080
SSH_PORT         = 10022
ROOT_URL         = http://hub.shundong.xyz:18080/
DISABLE_SSH      = false
SSH_LISTEN_PORT  = 10022

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

## 四、启动/停止命令
### 前台启动（调试）
```bash
forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini
```

### 后台启动（生产）
```bash
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &
```

### 停止服务
```bash
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9
```

### 重启服务
```bash
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs kill -9
nohup forgejo web --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini > ~/.local/forgejo/logs/nohup.log 2>&1 &
```

## 五、初始化配置
1. 浏览器访问：`http://hub.shundong.xyz:18080`
2. 验证数据库（自动识别SQLite3）→ 创建管理员账号 → 点击「Install Forgejo」完成安装

## 六、常用操作
```bash
# 查看日志
tail -f ~/.local/forgejo/logs/nohup.log

# 查看Forgejo进程
ps -ef | grep forgejo | grep -v grep

# 命令行创建管理员用户（示例）
forgejo --work-path ~/.local/forgejo --config ~/.local/forgejo/conf/app.ini admin user create --username admin --password your_password --email admin@shundong.xyz --admin
```

### 总结
1. 核心路径：二进制文件 `/usr/local/bin/forgejo`，工作目录 `~/.local/forgejo`；
2. 启动方式：前台用于调试，后台（nohup）用于生产，无systemd依赖；
3. 初始化：访问18080端口完成管理员创建即可使用，SSH端口10022已配置。
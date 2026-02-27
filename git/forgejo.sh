#!/bin/bash
set -euo pipefail  # 开启严格模式：未定义变量报错、管道失败则脚本退出

# ==================== 配置参数区（仅需修改此处）====================
# 系统/用户信息
SYSTEM_USER="shundong"
SERVER_IP="192.168.1.10"

# Forgejo核心配置
FORGEJO_VERSION="14.0.2"
FORGEJO_INSTALL_PATH="/usr/local/bin/forgejo"
FORGEJO_WORK_DIR="$HOME/.local/forgejo"
FORGEJO_WEB_PORT="18080"
FORGEJO_SSH_PORT="10022"
FORGEJO_DOMAIN="hub.shundong.xyz"
FORGEJO_DB_TYPE="sqlite3"
FORGEJO_APP_NAME="shundong Forgejo Hub"

# 管理员账号配置
ADMIN_USER="admin"
ADMIN_PWD="123456"
ADMIN_EMAIL="admin@shundong.xyz"

# Nginx SSL配置（按需修改证书路径）
SSL_CRT="/etc/nginx/ssl/hub.shundong.xyz.crt"
SSL_KEY="/etc/nginx/ssl/hub.shundong.xyz.key"

# ==================== 工具函数区 ====================
# 彩色输出函数
info() {
    echo -e "\033[34m[INFO] $1\033[0m"
}

success() {
    echo -e "\033[32m[SUCCESS] $1\033[0m"
}

error() {
    echo -e "\033[31m[ERROR] $1\033[0m"
    exit 1
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "必需命令 $1 未安装，请先安装后再执行脚本"
    fi
}

# ==================== 前置检查 ====================
info "开始执行Forgejo 14.0.2一键安装脚本..."
info "当前用户: $(whoami) | 目标系统: Ubuntu 22.04"

# 检查核心命令
info "检查系统必需命令..."
check_command "wget"
check_command "nginx"
check_command "git"
check_command "awk"

# 检查当前用户是否为指定用户
if [ "$(whoami)" != "${SYSTEM_USER}" ]; then
    error "当前用户不是 ${SYSTEM_USER}，请切换到该用户后执行脚本"
fi

# ==================== 安装流程 ====================
# 1. 创建工作目录
info "创建Forgejo工作目录结构..."
mkdir -p ${FORGEJO_WORK_DIR}/{conf,data,logs,repositories,attachments,lfs} || error "工作目录创建失败"
success "工作目录创建完成: ${FORGEJO_WORK_DIR}"

# 2. 下载并安装Forgejo二进制包（检测是否已存在）
info "检查Forgejo二进制包是否已存在..."
if [ -f "${FORGEJO_INSTALL_PATH}" ]; then
    # 验证版本（简单校验文件名）
    if ${FORGEJO_INSTALL_PATH} --version | grep -q "${FORGEJO_VERSION}"; then
        success "Forgejo ${FORGEJO_VERSION} 二进制包已存在，跳过下载"
    else
        error "当前二进制包版本不匹配，请删除 ${FORGEJO_INSTALL_PATH} 后重新执行"
    fi
else
    info "开始下载Forgejo ${FORGEJO_VERSION} 二进制包..."
    if ! sudo wget -q -O ${FORGEJO_INSTALL_PATH} https://codeberg.org/forgejo/forgejo/releases/download/v${FORGEJO_VERSION}/forgejo-${FORGEJO_VERSION}-linux-amd64; then
        error "二进制包下载失败，请检查网络或版本号是否正确"
    fi
    sudo chmod 755 ${FORGEJO_INSTALL_PATH} || error "添加可执行权限失败"
    success "Forgejo二进制包下载并安装完成: ${FORGEJO_INSTALL_PATH}"
fi

# 3. 生成配置文件
info "生成Forgejo配置文件..."
cat > ${FORGEJO_WORK_DIR}/conf/app.ini << EOF
[DEFAULT]
APP_NAME = ${FORGEJO_APP_NAME}
RUN_USER = ${SYSTEM_USER}
RUN_MODE = prod

[server]
DOMAIN           = ${FORGEJO_DOMAIN}
HTTP_PORT        = ${FORGEJO_WEB_PORT}
SSH_PORT         = ${FORGEJO_SSH_PORT}
ROOT_URL         = https://${FORGEJO_DOMAIN}/
DISABLE_SSH      = false
SSH_LISTEN_PORT  = ${FORGEJO_SSH_PORT}
HTTP_LISTEN_ADDR = 127.0.0.1

[database]
DB_TYPE  = ${FORGEJO_DB_TYPE}
PATH     = ${FORGEJO_WORK_DIR}/data/forgejo.db

[repository]
ROOT = ${FORGEJO_WORK_DIR}/repositories

[repository.upload]
FILE_MAX_SIZE = 1024
MAX_FILES = 20

[attachment]
PATH = ${FORGEJO_WORK_DIR}/attachments
MAX_SIZE = 2048
MAX_FILES = 10

[lfs]
PATH = ${FORGEJO_WORK_DIR}/lfs

[log]
MODE = file
LEVEL = info
ROOT_PATH = ${FORGEJO_WORK_DIR}/logs
EOF

if [ ! -f "${FORGEJO_WORK_DIR}/conf/app.ini" ]; then
    error "配置文件生成失败"
fi
success "配置文件生成完成: ${FORGEJO_WORK_DIR}/conf/app.ini"

# 4. 配置Nginx反向代理
info "配置Nginx反向代理..."
sudo cat > /etc/nginx/sites-available/${FORGEJO_DOMAIN} << EOF
server {
    listen 80;
    server_name ${FORGEJO_DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${FORGEJO_DOMAIN};

    ssl_certificate ${SSL_CRT};
    ssl_certificate_key ${SSL_KEY};

    location / {
        proxy_pass http://127.0.0.1:${FORGEJO_WEB_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location ~ ^/(assets|img|css|js|fonts)/ {
        proxy_pass http://127.0.0.1:${FORGEJO_WEB_PORT};
        expires 30d;
        add_header Cache-Control "public, max-age=2592000";
    }
}
EOF

# 启用配置并检查
sudo ln -sf /etc/nginx/sites-available/${FORGEJO_DOMAIN} /etc/nginx/sites-enabled/ || error "Nginx配置启用失败"
if ! sudo nginx -t; then
    error "Nginx配置语法错误，请检查SSL证书路径或配置内容"
fi
sudo systemctl restart nginx || error "Nginx重启失败"
success "Nginx反向代理配置完成并生效"

# 5. 启动Forgejo服务
info "启动Forgejo服务..."
# 先停止可能存在的旧进程
ps -ef | grep forgejo | grep -v grep | awk '{print $2}' | xargs -r kill -9 > /dev/null 2>&1
# 后台启动服务
nohup ${FORGEJO_INSTALL_PATH} web --work-path ${FORGEJO_WORK_DIR} --config ${FORGEJO_WORK_DIR}/conf/app.ini > ${FORGEJO_WORK_DIR}/logs/nohup.log 2>&1 &

# 等待服务启动并检查
info "等待服务初始化（5秒）..."
sleep 5
if ! ps -ef | grep forgejo | grep -v grep > /dev/null; then
    error "Forgejo服务启动失败，请查看日志: ${FORGEJO_WORK_DIR}/logs/nohup.log"
fi
success "Forgejo服务启动成功"

# 6. 创建管理员账号
info "创建管理员账号 ${ADMIN_USER}..."
if ! ${FORGEJO_INSTALL_PATH} --work-path ${FORGEJO_WORK_DIR} --config ${FORGEJO_WORK_DIR}/conf/app.ini admin user create \
  --username ${ADMIN_USER} \
  --password ${ADMIN_PWD} \
  --email ${ADMIN_EMAIL} \
  --admin \
  --must-change-password=false; then
    error "管理员账号创建失败，可能是服务未完全启动"
fi
success "管理员账号创建成功: 用户名=${ADMIN_USER} 密码=${ADMIN_PWD}"

# ==================== 安装完成 ====================
success "=================== 安装完成 ==================="
echo -e "\033[33m"
echo "📌 访问地址: https://${FORGEJO_DOMAIN}"
echo "👤 管理员账号: ${ADMIN_USER}"
echo "🔑 管理员密码: ${ADMIN_PWD}（生产环境建议立即修改）"
echo "📁 工作目录: ${FORGEJO_WORK_DIR}"
echo "📝 日志路径: ${FORGEJO_WORK_DIR}/logs/nohup.log"
echo "⚙️  常用操作:"
echo "   - 停止服务: ps -ef | grep forgejo | grep -v grep | awk '{print \$2}' | xargs kill -9"
echo "   - 重启服务: 停止服务后重新执行脚本，或运行: nohup ${FORGEJO_INSTALL_PATH} web --work-path ${FORGEJO_WORK_DIR} --config ${FORGEJO_WORK_DIR}/conf/app.ini > ${FORGEJO_WORK_DIR}/logs/nohup.log 2>&1 &"
echo -e "\033[0m"


# Gitlab操作指南
[Githlab](https://about.gitlab.com/)是一个基于Git的代码托管平台，提供了代码管理、版本控制、协作开发等功能。

## 一. 安装Gitlab

### 1.1 运行GitLab
```shell
# 拉取镜像
docker pull gitlab/gitlab-ce:latest

# 工作目录
sudo mkdir -p /var/gitlab/{config,logs,data}
sudo chmod -R 750 /var/gitlab

# 启动容器
sudo docker run --detach \
  --name gitlab \
  --publish 9043:443 \
  --publish 9080:80 \
  --publish 9022:22 \
  --restart always \
  --volume /var/gitlab/config:/etc/gitlab \
  --volume /var/gitlab/logs:/var/log/gitlab \
  --volume /var/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest

# 初始化需要耐心等待(十分钟内都正常)，可通过命令查看进度
docker logs -f gitlab
```

### 1.2 配置GitLab

- 为避免与默认**22**端口的冲突，须重新指定`gitlab_shell_ssh_port`端口
- **建议使用域名**，即使没有真实域名，也可通过主机hosts或路由器dns模拟
```shell
sudo vim /var/gitlab/config/gitlab.rb

# ******************************** gitlab配置 ***********************************
# 配置http协议
external_url 'http://git.mafool.com'

# 配置ssh协议(9022会作用在git地址上,如 ssh://git@git.github.com:9022/awesome.git)
gitlab_rails['gitlab_ssh_host'] = 'git.mafool.com'
gitlab_rails['gitlab_shell_ssh_port'] = 9022
gitlab_rails['time_zone'] = 'Asia/Shanghai'
# *******************************************************************************
```
- 重新加载GitLab配置

```bash
sudo docker restart gitlab
```

### 1.3 配置Nginx

- **创建nginx配置**

```bash
sudo vim /etc/nginx/conf.d/gitlab.conf
```

```nginx
# 完整模板，仅需要替换“192.168.X.X”和“git.example.com”即可
server {
    listen 80;
    server_name git.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name git.example.com;

    # SSL证书配置
    ssl_certificate /var/gitlab/ssl.crt;
    ssl_certificate_key /var/gitlab/ssl.key;
    # 注意：.csr文件是证书请求文件，不需要在Nginx中配置

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
        # 根据您的实际需求选择代理到哪个端口
        # 通常是HTTP服务代理到9080，HTTPS服务代理到9043
        # 这里假设9080是HTTP服务
        proxy_pass http://192.168.X.X:9080;
        
        # 如果9043是HTTPS服务，则使用：
        # proxy_pass https://192.168.X.X:9043;
        # 注意：如果使用HTTPS代理，可能需要添加 proxy_ssl_* 配置

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

    # 可选：GitLab Webhook的特殊处理（如果需要）
    # location ~ ^/[^/]+\/[-a-zA-Z0-9_]+\/hooks {
    #     proxy_pass http://192.168.X.X:9080;
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #     proxy_set_header X-Forwarded-Proto $scheme;
    # }

    # 可选：静态文件缓存设置（如果适用）
    # location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    #     expires 1y;
    #     add_header Cache-Control "public, no-transform";
    # }
}
```
- **替换IP和域名**
```bash
# 替换IP和域名，如：
sudo sed -i 's/192.168.X.X/192.168.1.100/g' /etc/nginx/conf.d/gitlab.conf
sudo sed -i 's/git.example.com/git.mafool.com/g' /etc/nginx/conf.d/gitlab.conf
```
- **创建自签名证书**
```bash
sudo mkdir -p /var/gitlab
sudo openssl req -x509 -nodes -days 730 -newkey rsa:4096 \
  -keyout /var/gitlab/ssl.key -out /var/gitlab/ssl.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=GitLab/OU=IT/CN=git.mafool.com" -sha256
sudo chmod 600 /var/gitlab/ssl.key
sudo chmod 644 /var/gitlab/ssl.crt
```
- **重启Nginx**
```bash
sudo nginx -t
sudo nginx -s reload
```

###  1.4 初始登录

- 访问 http://git.mafool.com 

- 使用管理员账号登录，用户名是`root`，密码通过如下命令获取，**建议登录后立即修改密码**。

```bash
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```



<br/>



## 二. 配置CICD

### 2.1 安装Runner

GitLab Runner是执行CI/CD任务的代理程序，负责运行构建、测试和部署作业。

```shell
# 拉取Runner镜像
docker pull gitlab/gitlab-runner:latest

# 创建工作目录
sudo mkdir -p /data/etc/gitlab-runner
sudo chmod -R 750 /data/etc/gitlab-runner

# 启动Runner容器
docker run \
  --detach \
  --name gitlab-runner \
  --restart always \
  --volume /data/etc/gitlab-runner:/etc/gitlab-runner \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

# 查看Runner状态
docker logs -f gitlab-runner
```

### 2.2 注册Runner

注册Runner使其能够与GitLab服务器通信并接收任务。

```shell
# 进入gitlab-runner容器
docker exec -it gitlab-runner bash

# 查看gitlab-runner版本
gitlab-runner -v

# 注册Runner
gitlab-runner register
```

注册过程中需要输入以下信息：

```
Enter the GitLab instance URL (for example, https://gitlab.com/):
http://git.mafool.com

Enter the registration token:
[从GitLab获取的注册令牌]

Enter a description for the runner:
[输入Runner描述，如：docker-runner]

Enter tags for the runner (comma-separated):
[输入标签，如：docker,build]

Enter optional maintenance note for the runner:
[输入维护说明，可留空]

Registering runner... succeeded

Enter an executor: docker, shell, ssh, virtualbox, docker+machine, docker-ssh, parallels, custom, kubernetes:
docker

Enter the default Docker image (for example, alpine:latest):
alpine:latest

Runner registered successfully. Feel free to start it, but if it's running already the config should be automatically reloaded!
```

**获取注册令牌：**
1. 登录GitLab
2. 进入项目或群组设置
3. 选择 **Settings** → **CI/CD** → **Runners**
4. 点击 **New project runner** 或 **New group runner**
5. 复制生成的注册令牌

### 2.3 配置Runner

编辑Runner配置文件以优化性能和功能。

```shell
# 编辑配置文件
sudo vim /data/etc/gitlab-runner/config.toml
```

```toml
concurrent = 4
check_interval = 0

[session_server]
  session_timeout = 1800

[[runners]]
  name = "docker-runner"
  url = "http://git.mafool.com"
  token = "glrt-xxxxxxxxxxxx"
  executor = "docker"
  [runners.custom_build_dir]
  [runners.cache]
    [runners.cache.s3]
    [runners.cache.gcs]
    [runners.cache.azure]
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    network_mtu = 0
```

**重启Runner使配置生效：**

```shell
docker restart gitlab-runner
```

### 2.4 创建CI/CD配置

在项目根目录创建 `.gitlab-ci.yml` 文件定义CI/CD流水线。

```yaml
# .gitlab-ci.yml 示例
stages:
  - build
  - test
  - deploy

variables:
  DOCKER_IMAGE_NAME: myapp
  DOCKER_TAG: $CI_COMMIT_SHORT_SHA

# 构建阶段
build:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t $DOCKER_IMAGE_NAME:$DOCKER_TAG .
    - docker tag $DOCKER_IMAGE_NAME:$DOCKER_TAG $DOCKER_IMAGE_NAME:latest
  only:
    - main
    - develop

# 测试阶段
test:
  stage: test
  image: python:3.9
  script:
    - pip install -r requirements.txt
    - python -m pytest tests/
  only:
    - main
    - develop
    - merge_requests

# 部署阶段
deploy:
  stage: deploy
  image: docker:latest
  services:
    - docker:dind
  script:
    - echo "Deploying to production"
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker push $DOCKER_IMAGE_NAME:$DOCKER_TAG
  only:
    - main
  when: manual
```

### 2.5 配置Runner变量

在GitLab中配置环境变量，用于CI/CD流程。

**项目级别变量：**
1. 进入项目 **Settings** → **CI/CD** → **Variables**
2. 点击 **Add variable**
3. 输入变量名和值，选择保护状态和掩码状态

**常用变量示例：**
- `CI_REGISTRY_USER`: Docker镜像仓库用户名
- `CI_REGISTRY_PASSWORD`: Docker镜像仓库密码
- `SSH_PRIVATE_KEY`: 部署服务器的SSH私钥
- `DEPLOY_HOST`: 部署服务器地址

### 2.6 查看CI/CD日志

```shell
# 查看Runner日志
docker logs -f gitlab-runner

# 查看特定作业的日志
# 在GitLab界面：CI/CD → Pipelines → 选择Pipeline → 选择Job → 查看日志
```



<br/>



## 三. 高级功能

### 3.1 配置邮箱服务

配置GitLab的邮件服务，用于发送通知、密码重置等邮件。

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

**使用SMTP服务（以QQ邮箱为例）：**

```ruby
# ******************************** 邮箱配置 ***********************************
# 启用邮箱服务
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "your_email@qq.com"
gitlab_rails['smtp_password'] = "your_smtp_password"
gitlab_rails['smtp_domain'] = "qq.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

# 发件人配置
gitlab_rails['gitlab_email_from'] = 'your_email@qq.com'
gitlab_rails['gitlab_email_display_name'] = 'GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'your_email@qq.com'
# *******************************************************************************
```

**使用SMTP服务（以163邮箱为例）：**

```ruby
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.163.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "your_email@163.com"
gitlab_rails['smtp_password'] = "your_smtp_password"
gitlab_rails['smtp_domain'] = "163.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['smtp_openssl_verify_mode'] = 'peer'

gitlab_rails['gitlab_email_from'] = 'your_email@163.com'
gitlab_rails['gitlab_email_display_name'] = 'GitLab'
gitlab_rails['gitlab_email_reply_to'] = 'your_email@163.com'
```

**应用配置：**

```shell
# 重新配置GitLab
docker exec -it gitlab gitlab-ctl reconfigure

# 重启GitLab
docker restart gitlab

# 查看邮件配置状态
docker exec -it gitlab gitlab-rake gitlab:env:info | grep -i smtp
```

**测试邮件发送：**

```shell
# 进入GitLab容器
docker exec -it gitlab bash

# 发送测试邮件
gitlab-rails console
```

在控制台中执行：

```ruby
Notify.test_email('recipient@example.com', 'Test Subject', 'Test Message').deliver_now
```

### 3.2 备份与恢复

定期备份GitLab数据，确保数据安全。

**配置自动备份：**

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

```ruby
# ******************************** 备份配置 ***********************************
# 备份保留时间（秒），默认604800秒（7天）
gitlab_rails['backup_keep_time'] = 604800

# 备份存储路径（默认/var/opt/gitlab/backups）
gitlab_rails['backup_path'] = '/var/opt/gitlab/backups'

# 备份文件名包含时间戳
gitlab_rails['backup_upload_connection'] = {
  'provider' => 'Local',
  'local_root' => '/var/opt/gitlab/backups'
}
# *******************************************************************************
```

**手动备份：**

```shell
# 执行备份
docker exec -it gitlab gitlab-backup create

# 查看备份文件
docker exec -it gitlab ls -lh /var/opt/gitlab/backups/

# 复制备份文件到宿主机
docker cp gitlab:/var/opt/gitlab/backups/ /var/gitlab/backups/
```

**设置定时备份：**

```shell
# 创建备份脚本
sudo vim /usr/local/bin/gitlab-backup.sh
```

```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/var/gitlab/backups"
LOG_FILE="/var/log/gitlab-backup.log"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting GitLab backup..." >> $LOG_FILE

# 执行备份
docker exec -t gitlab gitlab-backup create BACKUP="gitlab_backup_$DATE" CRON=1 >> $LOG_FILE 2>&1

# 复制备份文件
docker cp gitlab:/var/opt/gitlab/backups/ $BACKUP_DIR/ >> $LOG_FILE 2>&1

# 清理旧备份（保留最近7天）
find $BACKUP_DIR -name "*.tar" -mtime +7 -delete >> $LOG_FILE 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed." >> $LOG_FILE
```

```shell
# 添加执行权限
sudo chmod +x /usr/local/bin/gitlab-backup.sh

# 创建日志目录
sudo mkdir -p /var/log
sudo touch /var/log/gitlab-backup.log
sudo chmod 644 /var/log/gitlab-backup.log

# 添加到crontab（每天凌晨2点执行）
sudo crontab -e
```

添加以下内容：

```
0 2 * * * /usr/local/bin/gitlab-backup.sh
```

**恢复备份：**

```shell
# 停止相关服务
docker exec -it gitlab gitlab-ctl stop unicorn
docker exec -it gitlab gitlab-ctl stop sidekiq

# 查看备份文件
docker exec -it gitlab ls -lh /var/opt/gitlab/backups/

# 恢复备份（注意：不要包含.tar扩展名）
docker exec -it gitlab gitlab-backup restore BACKUP=1712345678_2024_04_05_12.0.0

# 重新启动服务
docker exec -it gitlab gitlab-ctl restart

# 检查服务状态
docker exec -it gitlab gitlab-ctl status
```

**注意事项：**
- 恢复备份前需要停止GitLab服务
- 备份文件名不包含.tar扩展名
- 恢复后需要重新配置应用设置

### 3.3 配置LDAP认证

集成LDAP/AD实现统一身份认证。

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

```ruby
# ******************************** LDAP配置 ***********************************
gitlab_rails['ldap_enabled'] = true
gitlab_rails['ldap_servers'] = YAML.load <<-'EOS'
  main: # 'main' is the GitLab 'provider ID' of this LDAP server
    label: 'LDAP'
    host: 'ldap.example.com'
    port: 389
    uid: 'sAMAccountName'
    bind_dn: 'CN=gitlab,OU=Users,DC=example,DC=com'
    password: 'your_password'
    encryption: 'plain' # "start_tls" or "simple_tls" or "plain"
    verify_certificates: true
    active_directory: true
    allow_username_or_email_login: true
    lowercase_usernames: false
    block_auto_created_users: false
    base: 'DC=example,DC=com'
    user_filter: ''
    attributes:
      username: ['sAMAccountName']
      email: ['mail']
      name: 'cn'
      first_name: 'givenName'
      last_name: 'sn'
EOS
# *******************************************************************************
```

**应用配置：**

```shell
# 重新配置GitLab
docker exec -it gitlab gitlab-ctl reconfigure

# 重启GitLab
docker restart gitlab

# 测试LDAP连接
docker exec -it gitlab gitlab-rake gitlab:ldap:check
```

### 3.4 配置HTTPS

使用Let's Encrypt免费SSL证书或自签名证书。

**使用Let's Encrypt证书：**

```shell
# 安装certbot
sudo apt-get update
sudo apt-get install certbot

# 申请证书
sudo certbot certonly --standalone -d git.mafool.com

# 证书位置
# /etc/letsencrypt/live/git.mafool.com/fullchain.pem
# /etc/letsencrypt/live/git.mafool.com/privkey.pem
```

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

```ruby
# ******************************** HTTPS配置 ***********************************
external_url 'https://git.mafool.com'

# SSL证书配置
nginx['ssl_certificate'] = "/etc/letsencrypt/live/git.mafool.com/fullchain.pem"
nginx['ssl_certificate_key'] = "/etc/letsencrypt/live/git.mafool.com/privkey.pem"

# 重定向HTTP到HTTPS
nginx['redirect_http_to_https'] = true
# *******************************************************************************
```

**挂载证书目录：**

```shell
# 停止GitLab容器
docker stop gitlab

# 重新启动容器，挂载证书目录
docker run --detach \
  --name gitlab \
  --publish 9043:443 \
  --publish 9080:80 \
  --publish 9022:22 \
  --restart always \
  --volume /var/gitlab/config:/etc/gitlab \
  --volume /var/gitlab/logs:/var/log/gitlab \
  --volume /var/gitlab/data:/var/opt/gitlab \
  --volume /etc/letsencrypt:/etc/letsencrypt:ro \
  gitlab/gitlab-ce:latest
```

**应用配置：**

```shell
# 重新配置GitLab
docker exec -it gitlab gitlab-ctl reconfigure

# 重启GitLab
docker restart gitlab
```

### 3.5 性能优化

优化GitLab性能以提升用户体验。

**调整内存配置：**

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

```ruby
# ******************************** 性能优化 ***********************************
# PostgreSQL配置
postgresql['shared_buffers'] = "256MB"
postgresql['max_worker_processes'] = 8

# Redis配置
redis['maxclients'] = 10000

# Unicorn配置（GitLab 14.x及以下版本）
# unicorn['worker_processes'] = 4

# Puma配置（GitLab 15.x及以上版本）
puma['worker_processes'] = 2
puma['min_threads'] = 4
puma['max_threads'] = 16
puma['per_worker_max_memory_mb'] = 1024

# Sidekiq配置
sidekiq['max_concurrency'] = 25

# Gitaly配置
gitaly['configuration'] = {
  concurrency: [
    {
      'rpc' => "/gitaly.SmartHTTPService/PostReceivePack",
      'max_per_repo' => 3
    },
    {
      'rpc' => "/gitaly.SSHService/SSHReceivePack",
      'max_per_repo' => 3
    }
  ]
}
# *******************************************************************************
```

**启用页面缓存：**

```ruby
# 启用页面缓存
gitlab_rails['pages_access_control'] = false
gitlab_rails['pages_nginx']['proxy_cache'] = true
```

**应用配置：**

```shell
# 重新配置GitLab
docker exec -it gitlab gitlab-ctl reconfigure

# 重启GitLab
docker restart gitlab
```

### 3.6 监控与日志

配置GitLab监控和日志管理。

**查看GitLab日志：**

```shell
# 查看所有服务日志
docker exec -it gitlab gitlab-ctl tail

# 查看特定服务日志
docker exec -it gitlab gitlab-ctl tail nginx
docker exec -it gitlab gitlab-ctl tail gitlab-rails
docker exec -it gitlab gitlab-ctl tail sidekiq

# 查看容器日志
docker logs -f gitlab
```

**配置日志轮转：**

```shell
# 编辑GitLab配置文件
sudo vim /var/gitlab/config/gitlab.rb
```

```ruby
# ******************************** 日志配置 ***********************************
# 日志轮转配置
logging['logrotate_frequency'] = "daily"
logging['logrotate_rotate'] = 30
logging['logrotate_size'] = "200M"
logging['logrotate_compress'] = "compress"
logging['logrotate_method'] = "copytruncate"
logging['logrotate_delaycompress'] = "delaycompress"
# *******************************************************************************
```

**启用Prometheus监控：**

```ruby
# 启用Prometheus
prometheus['enable'] = true
prometheus['monitor_kubernetes'] = false
prometheus['listen_address'] = 'localhost:9090'
```

**应用配置：**

```shell
# 重新配置GitLab
docker exec -it gitlab gitlab-ctl reconfigure
```





## 参考链接

https://github.com/bravist/gitlab-ci-docker
https://blog.csdn.net/weixin_39246554/article/details/130749706
https://zhuanlan.zhihu.com/p/652503159










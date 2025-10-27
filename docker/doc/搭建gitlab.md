


### **一、Docker容器化部署（推荐，简单高效）**
Docker部署无需复杂的环境配置，适合快速搭建和管理。

#### 1. 安装Docker和Docker Compose

如果尚未安装Docker，先执行以下命令：
```bash
# 更新包索引
sudo apt update

# 安装依赖
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# 添加Docker官方GPG密钥
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# 添加Docker源
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 安装Docker
sudo apt update
sudo apt install -y docker-ce

# 启动Docker并设置开机自启
sudo systemctl start docker
sudo systemctl enable docker

# 安装Docker Compose（可选，用于管理容器）
sudo apt install -y docker-compose
```


#### 2. 拉取GitLab镜像并启动
推荐使用**GitLab社区版（CE）**，命令如下：
```bash
# 创建存储GitLab数据的目录（确保权限）
sudo mkdir -p /srv/gitlab/config /srv/gitlab/logs /srv/gitlab/data
sudo chmod -R 777 /srv/gitlab  # 简化权限，生产环境可按需调整

# 启动GitLab容器（使用host网络，避免端口映射问题）
sudo docker run --detach \
  --hostname gitlab.example.com \  # 替换为你的域名或服务器IP
  --publish 443:443 --publish 80:80 --publish 22:22 \  # 映射端口（HTTP/HTTPS/SSH）
  --name gitlab \
  --restart always \  # 容器退出时自动重启
  --volume /srv/gitlab/config:/etc/gitlab \
  --volume /srv/gitlab/logs:/var/log/gitlab \
  --volume /srv/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

- 替换`gitlab.example.com`为你的服务器IP或域名（如`192.168.1.100`）。
- 首次启动需要几分钟初始化，可通过`docker logs -f gitlab`查看进度。


#### 3. 访问GitLab并初始化
- 打开浏览器，访问服务器IP或域名（如`http://192.168.1.100`）。
- 首次登录需获取初始管理员密码：
  ```bash
  sudo docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
  ```
- 登录用户名：`root`，输入上述密码，登录后建议立即修改密码。


### **二、传统包管理安装（适合生产环境，可控性高）**
以Ubuntu 20.04为例，通过官方包安装。

#### 1. 安装依赖
```bash
sudo apt update
sudo apt install -y curl openssh-server ca-certificates tzdata perl
```


#### 2. 添加GitLab源并安装
```bash
# 下载GitLab安装脚本（社区版）
curl -sS https://packages.gitlab.com/install/repositories/gitlab/gitlab-ce/script.deb.sh | sudo bash

# 安装GitLab（替换为你的域名/IP）
sudo EXTERNAL_URL="http://gitlab.example.com" apt install -y gitlab-ce
```

- `EXTERNAL_URL`需填写实际访问的地址（HTTP或HTTPS），如`http://192.168.1.100`。


#### 3. 配置与启动
```bash
# 重新配置GitLab（修改配置后需执行）
sudo gitlab-ctl reconfigure

# 启动GitLab服务
sudo gitlab-ctl start
```

- 查看状态：`sudo gitlab-ctl status`
- 停止服务：`sudo gitlab-ctl stop`


#### 4. 访问与初始化
- 浏览器访问`EXTERNAL_URL`设置的地址。
- 初始密码位置：`sudo cat /etc/gitlab/initial_root_password`（24小时后自动删除）。
- 登录后修改密码，创建项目或用户。


### **三、后续配置建议**
1. **HTTPS配置**：  
   编辑配置文件（Docker方式：`/srv/gitlab/config/gitlab.rb`；传统方式：`/etc/gitlab/gitlab.rb`），设置SSL证书路径：
   ```ruby
   external_url 'https://gitlab.example.com'
   nginx['ssl_certificate'] = '/path/to/cert.pem'
   nginx['ssl_certificate_key'] = '/path/to/key.pem'
   ```
   重新配置：`sudo gitlab-ctl reconfigure`（传统方式）或`docker restart gitlab`（Docker方式）。

2. **资源要求**：  
   GitLab对资源有一定要求，建议至少2GB内存（生产环境推荐4GB以上），否则可能启动失败。

3. **备份与恢复**：  
   - 备份：`sudo gitlab-ctl backup-create`（传统方式）或`docker exec gitlab gitlab-ctl backup-create`（Docker方式）。
   - 备份文件默认存储在`/var/opt/gitlab/backups`（传统）或`/srv/gitlab/data/backups`（Docker）。


通过以上步骤，你可以成功搭建GitLab服务，用于代码托管、CI/CD等功能。如果是生产环境，建议进一步配置防火墙、定期备份和监控。
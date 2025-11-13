# Ubuntu Docker GitLab 搭建教程（共享主机22端口）
## 一、前置准备
- 系统：Ubuntu
- 已安装：Docker、Nginx（并配置 `git.shundong.xyz` 站点）
- 主机已开启 `sshd` 服务（默认22端口）

## 二、步骤1：部署GitLab容器
### 1. 创建挂载目录
```bash
sudo mkdir -p /var/gitlab/{config,logs,data}
sudo chmod -R 777 /var/gitlab  # 简化权限（生产可按需收紧）
```

### 2. 启动GitLab容器
```bash
sudo docker run --detach \
  --hostname git.shundong.xyz \
  --publish 9043:443 \
  --publish 9080:80 \
  --publish 9022:22 \
  --name gitlab \
  --restart always \
  --volume /var/gitlab/config:/etc/gitlab \
  --volume /var/gitlab/logs:/var/log/gitlab \
  --volume /var/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest
```

## 三、步骤2：配置22端口共享（核心）
### 1. 创建宿主机git用户（与容器一致）
```bash
sudo groupadd -g 998 git
sudo useradd -m -u 998 -g git -s /bin/sh -d /home/git git
```

### 2. 修复git用户家目录权限
```bash
sudo chown -R git:git /home/git
sudo chmod 700 /home/git
```

### 3. 配置git用户SSH免密转发
```bash
# 切换到git用户
sudo su - git

# 生成SSH密钥（一路回车）
ssh-keygen

# 复制GitLab授权文件并配置免密
mkdir -p ~/.ssh
cp /var/gitlab/data/.ssh/authorized_keys ~/.ssh/
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# 修复权限
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*

# 测试容器免密连接（成功则进入容器命令行）
ssh -i ~/.ssh/id_rsa -p 9022 -o StrictHostKeyChecking=no git@127.0.0.1

# 退出git用户和容器
exit && exit
```

### 4. 创建SSH转发脚本
```bash
# 创建脚本目录
sudo mkdir -p /opt/gitlab/embedded/service/gitlab-shell/bin

# 编写转发脚本
sudo cat > /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell << 'EOF'
#!/bin/sh
ssh -i /home/git/.ssh/id_rsa -p 9022 -o StrictHostKeyChecking=no git@127.0.0.1 "SSH_ORIGINAL_COMMAND=\"$SSH_ORIGINAL_COMMAND\" $0 $@"
EOF

# 添加执行权限
sudo chmod +x /opt/gitlab/embedded/service/gitlab-shell/bin/gitlab-shell
```

### 5. 重启GitLab容器（挂载SSH目录）
```bash
sudo docker stop gitlab && sudo docker rm gitlab

sudo docker run --detach \
  --hostname git.shundong.xyz \
  --publish 9043:443 \
  --publish 9080:80 \
  --publish 9022:22 \
  --name gitlab \
  --restart always \
  --volume /var/gitlab/config:/etc/gitlab \
  --volume /var/gitlab/logs:/var/log/gitlab \
  --volume /var/gitlab/data:/var/opt/gitlab \
  --volume /home/git/.ssh:/var/opt/gitlab/.ssh \
  gitlab/gitlab-ce:latest
```

### 6. 配置GitLab隐藏9022端口
```bash
# 编辑GitLab配置
sudo docker exec -it gitlab vim /etc/gitlab/gitlab.rb
```
添加/修改以下配置：
```ruby
gitlab_rails['gitlab_ssh_host'] = 'git.shundong.xyz'
# gitlab_rails['gitlab_shell_ssh_port'] = 9022  # 注释此行
external_url 'http://git.shundong.xyz'
```
重载配置并重启：
```bash
sudo docker exec -it gitlab gitlab-ctl reconfigure
sudo docker exec -it gitlab gitlab-ctl restart
```

## 四、验证效果
1. 测试SSH连接：
```bash
ssh -T git@git.shundong.xyz  # 预期输出：Welcome to GitLab, @xxx!
```
2. 克隆仓库（无9022端口）：
```bash
git clone git@git.shundong.xyz:dev/demo.git
```

## 关键说明
- 核心逻辑：宿主机22端口接收请求，通过SSH转发到容器9022端口
- 权限要求：`/home/git/.ssh` 目录700权限，内部文件600权限
- 日志排查：`/var/log/auth.log`（SSH日志）、`docker logs gitlab`（GitLab日志）



https://blog.zzsqwq.cn/posts/docker-gitlab-ssh/
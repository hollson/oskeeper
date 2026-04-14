在 Ubuntu 系统中安装 Docker 主要有两种方式：**官方一键安装脚本**（推荐新手）和**手动配置源安装**（更灵活）。以下是详细步骤：

### 一、前置准备：卸载旧版本（如有）
如果之前安装过 Docker 旧版本，先卸载：
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

### 二、方法1：官方一键安装脚本
执行官方提供的自动安装脚本：
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```
脚本会自动配置源、安装依赖并完成 Docker 安装。

### 三、方法2：手动配置源安装
#### 1. 更新系统包并安装依赖
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

#### 2. 添加 Docker 官方 GPG 密钥
```bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

#### 3. 添加 Docker 官方源
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 4. 安装 Docker Engine
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 四、验证安装
```bash
sudo docker --version          # 查看 Docker 版本
sudo docker run hello-world    # 运行测试容器，验证是否正常
```

### 五、可选：配置非 root 用户使用 Docker（避免每次 sudo）
```bash
sudo usermod -aG docker $USER  # 将当前用户加入 docker 组
newgrp docker                  # 刷新组权限（无需重启）
```
之后重新登录终端即可直接使用 `docker` 命令。

### 六、启动/开机自启 Docker
```bash
sudo systemctl start docker    # 启动 Docker 服务
sudo systemctl enable docker   # 设置开机自启
```

### 卸载 Docker（如需）
```bash
sudo apt-get purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
sudo rm -rf /var/lib/docker    # 删除镜像、容器等数据
sudo rm -rf /var/lib/containerd
```

### 注意事项
- Ubuntu 版本要求：推荐 20.04/22.04 LTS 版本（其他版本需确认兼容性）。
- 网络问题：若访问官方源缓慢，可替换为国内镜像源（如阿里云、清华源）。

安装完成后即可使用 Docker 运行容器、构建镜像等操作。
# Tailscale虚拟私有网络指南

[TOC]

## 🌎 一. Tailscale介绍

**[Tailscale](https://tailscale.com/download)** 是一款基于 **WireGuard** 协议的零配置虚拟私有网络(VPN)工具，能让多台设备在互联网上形成一个加密的私有网络。

**核心优势：**

- ⚡️ **零配置**：基于 WireGuard 协议，安装后即可自动建立安全连接
- 🔐 **安全加密**：所有流量通过端到端加密隧道传输
- 🌐 **跨平台支持**：支持 Windows、macOS、Linux、Android、iOS 等多种设备
- 🏠 **私有网络**：设备获得 100.x.x.x 私有 IP，如同在同一个局域网
- 🚀 **智能路由**：自动选择最优路径（UDP 直连或 DERP 中继）



**适用场景：**

- 访问内网服务（如数据库、Web 服务）
- 远程办公访问公司资源
- 服务器管理与运维
- 安全访问家庭网络设备



<br/>



## 🎀 二. 安装配置

### 2.1 安装Tailscale

#### 2.1.1 Ubuntu/Debian

```bash
# 安装命令
curl -fsSL https://tailscale.com/install.sh | sh

# 启动并加入网络（执行后复制链接到浏览器打开,使用(Google、GitHub等账号登录)
sudo tailscale up
```

#### 2.1.2 Windows/macOS

- 从 [Tailscale 官网](https://tailscale.com/download) 下载安装客户端, 登录并选择账号。

### 2.2 配置AuthKey

#### 2.2.1 生成AuthKey

- 登录 [Tailscale 控制台](https://login.tailscale.com/admin) ，进入 **Settings** → **Keys**。
- 点击 **Generate one-off key**（一次性密钥）或 **Generate auth key**（可重复使用）。
- 按需配置密钥参数：
  - **Expiry**：设置密钥有效期。
  - **Reusable :** 使用此密钥对多个设备进行身份验证。
  - **Ephemeral**："临时节点"，离线后自动从网络中移除。
  - **Tags**：给设备添加标签（用于权限控制，如 `tag:server`）。
- 生成后，立即复制密钥。

#### 2.2.2 加入网络

```bash
# 方式一：使用up命令（推荐）
sudo tailscale up --authkey=tskey-auth-xxxxxx-yyyyyy

# 方式二：使用login命令
sudo tailscale login --authkey=tskey-auth-xxxxxx-yyyyyy
```

#### 2.2.3 配置验证

   ```bash
   # 控制台的Machines页面，会出现该设备的名称和状态（在线/离线）
   tailscale ip
   ```

   

<br/>



## 📙 三. 基本命令

### 3.1 常用命令

**查看设备状态**：

```bash
tailscale ip				# 获取设备私有IP
tailscale status			# 查看设备状态
tailscale status --header	# 带表头查看状态
tailscale status --json		# 查看详细状态
tailscale netcheck			# 查看网络拓扑

sudo tailscale down			# 断开连接
sudo tailscale up			# 重新连接
sudo tailscale logout		# 退出登录
```

### 3.2 高级命令

#### 3.2.1 **多账号管理**

```shell
# 查看账号列表
tailscale switch --list
ID    Tailnet        Account
f694  ts-office      ev.tailef1.ts.net			# 办公Tailnet网络
d8f5  ts-shongsheng  shongsheng@gmail.com*		# 个人Tailnet网络

# 切换到指定网络（tailnet）
tailscale switch ts-shongsheng

# 通过ID或Tailnet名移除账号
sudo tailscale switch remove f694
```

**SSH登录主机**

```bash
# ssh <user>@<device>.tailnode.net
ssh ubuntu@100.117.181.64
```

**文件传输**：

```bash
# 发送文件到其他设备
# tailscale file cp file.txt <user>@<device>.tailnode.net:~
tailscale file cp file.txt ubuntu@100.117.100.XX:~

# 接收来自其他设备的文件
# tailscale file cp <user>@<device>.tailnode.net:~/file.txt ./
tailscale file cp ubuntu@100.117.100.XX:/var/log/log.txt ./
```

**端口转发**：

```bash
# 将本地端口转发到 Tailscale 网络中的其他设备
tailscale serve tcp:3000 tcp://100.x.x.x:3000

# 验证配置
tailscale serve status
```



<br/>



## 🛠️ 四. 场景实例

### 4.1 跨内网互通
**场景**：办公电脑A与家庭电脑B均处于内网环境，无独立公网IPv4地址，两台设备均部署Tailscale并加入同一Tailscale网络，需实现跨内网互通。

**操作**：

- 两台设备分别安装并登录同一Tailscale账号，加入同一Tailscale网络。

- 执行 `tailscale ip` 获取各自Tailscale IP（100.x.x.x段）。

- 直接使用Tailscale IP进行SSH、RDP、文件共享等访问，无需端口映射与公网IP。

- 网络优先P2P穿透，失败时自动通过DERP中继，默认即可互通。




### 4.2 Web安全隔离

**场景**：某个Web 应用，主站使用外网访问，Admin管理后台使用 Tailscale内网访问（隔离外网），Nginx建议配置如：

```nginx
server {
    listen 80;
    server_name example.com;

    # Web主站(外网访问)
    location / {
        root html;
        index index.html index.htm;
    }

    # Admin平台(内网访问)
    location ^~ /admin {
        #root D:/wwwroot;  			# root是路径拼接  
        alias D:/wwwroot/admin;		# alias是路径替换
        index index.html index.htm;
        
        allow 127.0.0.1;            # localhost
        allow 172.16.0.0/12;        # 172内网段 (172.16.0.0 - 172.31.255.255)
        allow 192.168.0.0/16;       # 192内网段 (192.168.0.0 - 192.168.255.255)
        allow 100.64.0.0/10;        # 运营商级NAT保留地址段(100.64.0.0 - 100.127.255.255)
        deny all; 
    }
}
```

### 4.3 端口内网隔离

**场景 :**  某个公网主机，**9108端口 ** 仅允许Tailscale的其他主机访问

**操作 :**  在服务器中设置防火墙，禁止 9108 端口被"非 Tailscale 网络"访问（以 Ubuntu 的 UFW 为例）：

```bash
# 仅允许Tailscale访问 9108 端口
sudo ufw allow in from 100.64.0.0/10 to any port 9108

# 禁止其他所有来源访问 9108 端口
sudo ufw deny 9108
```



<br/>




## 🏆 五. 安全实践

### 5.1 访问控制

> 在 Tailscale 控制台的 ACL 设置中，可以精确控制哪些设备可以访问哪些服务。

- 登录 Tailscale 控制台

- 进入**Settings → ACL Policies**

- 编辑或粘贴上述ACL策略

- 点击 Save 保存配置

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:server"],
      "dst": ["tag:database:5432,3306"]
    }
  ]
}
```


### 5.2 标签管理

为不同类型的设备分配标签，便于统一管理（需要在Auth Key中预设）：
- `tag:server` - 服务器类设备
- `tag:database` - 数据库类设备
- `tag:admin` - 管理员设备
- `tag:employee` - 员工设备

**设置标签的Auth Key**：

```bash
# 创建带标签的Auth Key
#!/bin/bash

# 首次认证入网 + 宣告单标签（需密钥）
sudo tailscale up --authkey=tskey-xxx --advertise-tags=tag:server

# 重置所有配置 + 重新宣告单标签（无密钥，配置异常时用）
sudo tailscale up --reset --advertise-tags=tag:server

# 已有认证下，宣告多个标签（仅改标签，无重置/认证）
sudo tailscale up --advertise-tags=tag:server,tag:prod

# 查看节点状态（包含Tag信息）
tailscale status

# 移除Tag
sudo tailscale up --advertise-tags= "" --reset
```

### 5.3 安全清单

- 定期检查已授权设备（控制台 Machines 页面）

- 生产服务器使用一次性Auth Key登录

- 为敏感服务设置ACL访问策略

- 定期轮换Auth Key（建议每90天）

- 启用2FA保护账户安全

- 关闭不必要的服务端口暴露



<br/>



## 参考连接

- https://tailscale.com


可以用虚拟机（作为服务端）和宿主机模拟 Tailscale 的使用场景，通过这种方式能直观理解 Tailscale 如何让不同“网络环境”的设备形成私有网络。以下是具体操作步骤：


### **前提条件**  
- 宿主机（如你的电脑，Windows/macOS/Linux 均可）。  
- 一台虚拟机（如通过 VirtualBox、VMware 搭建，系统推荐 Linux 或 Windows，作为“服务端”）。  
- 宿主机和虚拟机需能分别访问互联网（确保能下载 Tailscale 并联网登录）。  


### **模拟步骤**  

#### **1. 虚拟机（服务端）配置**  
假设虚拟机系统为 Ubuntu（其他系统类似）：  
- **安装 Tailscale**：  
  登录虚拟机，执行安装命令：  
  ```bash
  curl -fsSL https://tailscale.com/install.sh | sh
  ```
- **启动并登录**：  
  ```bash
  sudo tailscale up
  ```
  复制输出的登录链接，在宿主机浏览器打开，用你的 Tailscale 账号（如 Google、GitHub）登录。  
- **记录虚拟机的 Tailscale 私有 IP**：  
  执行 `tailscale ip`，得到类似 `100.123.45.67` 的 IP（记为 `VM_IP`）。  


#### **2. 宿主机配置**  
- **安装 Tailscale**：  
  从 [Tailscale 下载页](https://tailscale.com/download) 下载宿主机对应版本的客户端（如 Windows 版）并安装。  
- **登录同一账号**：  
  打开 Tailscale 客户端，用 **与虚拟机相同的账号** 登录（确保加入同一私有网络）。  
- **查看宿主机的 Tailscale 私有 IP**：  
  在客户端界面或执行 `tailscale ip`（Linux/macOS），得到类似 `100.76.54.32` 的 IP（记为 `Host_IP`）。  


#### **3. 验证设备互通**  
此时虚拟机和宿主机已通过 Tailscale 加入同一私有网络，可通过以下方式验证：  

- **宿主机访问虚拟机**：  
  在宿主机的终端（或命令提示符）中 ping 虚拟机的 Tailscale IP：  
  ```bash
  # Windows 命令提示符
  ping 100.123.45.67
  
  # Linux/macOS 终端
  ping 100.123.45.67
  ```
  若能 ping 通，说明基础连接成功。  

- **在虚拟机部署一个测试服务**（模拟你的 8080 端口 Web 服务）：  
  例如用 Python 快速启动一个简单的 HTTP 服务（端口 8080）：  
  ```bash
  # 虚拟机中执行（需安装 Python）
  python3 -m http.server 8080
  ```

- **宿主机访问虚拟机的 8080 端口**：  
  在宿主机浏览器中输入 `http://100.123.45.67:8080`，若能看到 Python 服务的文件列表，说明通过 Tailscale 成功访问虚拟机的“内网服务”。  


#### **4. 模拟“端口不开放公网”的场景（可选）**  
若想更贴近真实场景（虚拟机的 8080 端口不允许“公网”访问，但允许 Tailscale 访问）：  
- 在虚拟机中设置防火墙，禁止 8080 端口被“非 Tailscale 网络”访问（以 Ubuntu 的 UFW 为例）：  
  ```bash
  # 允许 Tailscale 网段（100.64.0.0/10）访问 8080 端口
  sudo ufw allow in from 100.64.0.0/10 to any port 8080
  
  # 禁止其他所有来源访问 8080 端口
  sudo ufw deny 8080
  ```
- 此时，宿主机若通过虚拟机的“本地 IP”（如虚拟机的内网 IP 192.168.56.101）访问 `192.168.56.101:8080` 会被拒绝，但通过 Tailscale IP `100.123.45.67:8080` 仍可正常访问，完美模拟“公网端口封闭但 Tailscale 可访问”的效果。  


### **原理说明**  
虚拟机和宿主机在物理上可能处于同一局域网（如虚拟机用“桥接模式”或“NAT 模式”），但通过 Tailscale 后，二者被分配了独立的私有 IP（100.xxx 网段），通信走 Tailscale 加密隧道，与物理网络隔离。这种方式和真实场景中“公网服务器与本地设备通过 Tailscale 互联”的原理完全一致，只是将“公网”换成了“物理局域网”作为底层网络环境。

通过这个模拟，你可以清晰看到 Tailscale 如何忽略底层网络（公网/内网），让设备形成独立的私有通信网络。



**nginx**

```shell
location / {
    # 允许 3 类来源：虚拟机自身、Tailscale 网段（所有 Tailscale 设备）
    allow 127.0.0.1;                # 保留虚拟机本地访问
    allow 100.64.0.0/10;            # 允许所有 Tailscale 网络设备访问（推荐，灵活）
    # 若想更严格，可只允许宿主机的 Tailscale IP，格式：allow 宿主机_TS_IP;
    
    deny all;                       # 拒绝其他所有来源
    try_files $uri $uri/ =404;
}
```


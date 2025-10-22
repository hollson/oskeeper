# WireGuard虚拟专用网络



## WireGuard简介

**WireGuard**是一种现代、简洁、高效的开源虚拟专用层VPN协议，旨在提供比传统VPN协议（如OpenVPN、IPsec）更简单的实现、更强的安全性和更好的性能。



<br/>

WireGuard的核心代码托管在[**GitHub**](https://github.com/WireGuard)，主要项目包括：

- **内核实现**：[wireguard-linux](https://github.com/WireGuard/wireguard-linux)（Linux内核集成的WireGuard模块）
- **用户工具**：[wireguard-tools](https://github.com/WireGuard/wireguard-tools)（用于配置和管理WireGuard接口的命令行工具，如`wg`和`wg-quick`）

_WireGuard已被合并到Linux内核主线（自Linux5.6版本起），成为官方支持的VPN协议。_



<br/>




## WireGuard实操
### 1.示例场景
下面以**两台Linux主机（A和B）通过内核原生WireGuard搭建点对点VPN**为例，演示具体操作。假设：

- 主机A（客户端）：内网IP`192.168.1.100`，需访问主机B的服务。

- 主机B（服务端）：有公网IP`203.0.113.5`，需开放UDP51820端口（WireGuard默认端口）。



### 2.核心步骤

**(1). 两台主机均安装 WireGuard 工具** 

- Linux 内核 ≥ 5.6 已内置 WireGuard 内核模块，只需安装用户态配置工具： 

```bash
# Ubuntu/Debian
sudo apt update && sudo apt install wireguard-tools -y

# CentOS/RHEL（需启用 EPEL）
sudo dnf install wireguard-tools -y
```



**(2). 生成密钥对（每台主机单独执行）** 

- WireGuard 依赖公钥/私钥认证，两台主机需各自生成密钥对，并交换公钥。 

```bash
# 生成私钥（自动创建 /etc/wireguard 目录，权限 600 确保安全）
sudo mkdir -p /etc/wireguard && sudo chmod 700 /etc/wireguard
sudo wg genkey | sudo tee /etc/wireguard/private.key && sudo chmod 600 /etc/wireguard/private.key

# 从私钥生成公钥（记录公钥，后续需复制到对方主机）
sudo cat /etc/wireguard/private.key | sudo wg pubkey | sudo tee /etc/wireguard/public.key
```

执行后，会在 `/etc/wireguard/` 下生成： 
- `private.key`：本机私钥（保密，不可泄露）。 
- `public.key`：本机公钥（需提供给对方主机）。 



**(3). 配置 WireGuard 接口（分别配置主机 A 和 B）** 

> 创建配置文件 `wg0.conf`（`wg0` 是接口名称，可自定义），格式如下： 


- **主机 B（服务端，有公网 IP）配置** 
```bash
sudo nano /etc/wireguard/wg0.conf
```

填入以下内容（替换占位符）：
```ini
[Interface]
PrivateKey = 主机B的私钥（从 /etc/wireguard/private.key 复制）
Address = 10.0.0.1/24  # 服务端在 VPN 中的私有 IP（自定义网段，如 10.0.0.0/24）
ListenPort = 51820     # 监听端口（UDP，需在防火墙开放）

# 允许主机 A 接入（客户端配置）
[Peer]
PublicKey = 主机A的公钥（从主机A的 /etc/wireguard/public.key 复制）
AllowedIPs = 10.0.0.2/32  # 允许主机 A 使用的 VPN IP（需与主机A的 Address 一致）
```


- **主机 A（客户端）配置** 
```bash
sudo nano /etc/wireguard/wg0.conf
```

填入以下内容（替换占位符）： 
```ini
[Interface]
PrivateKey = 主机A的私钥（从 /etc/wireguard/private.key 复制）
Address = 10.0.0.2/24  # 客户端在 VPN 中的私有 IP（与服务端 AllowedIPs 对应）

# 连接到主机 B（服务端）
[Peer]
PublicKey = 主机B的公钥（从主机B的 /etc/wireguard/public.key 复制）
Endpoint = 203.0.113.5:51820  # 服务端公网 IP:端口
AllowedIPs = 10.0.0.1/32      # 允许访问服务端的 VPN IP（按需扩展，如 10.0.0.0/24 允许整个网段）
PersistentKeepalive = 25      # 保持连接（NAT 环境下必备，每 25 秒发一次心跳）
```



**(4). 配置防火墙** 

- **主机 B（服务端）**：需开放 UDP 51820 端口，并允许 VPN 网段通信（以 UFW 为例）：
  
  ```bash
  sudo ufw allow 51820/udp
  sudo ufw allow in on wg0  # 允许 VPN 接口的入站流量
  sudo ufw reload
  ```
  
- **主机 A（客户端）**：若有防火墙，同样允许 VPN 接口通信：
  ```bash
  sudo ufw allow in on wg0
  sudo ufw reload
  ```



**(5). 启动 WireGuard 并测试**

**启动接口（两台主机均执行）** 

```bash
# 启动 wg0 接口
sudo wg-quick up wg0

# 查看接口状态（确认已连接）
sudo wg
```

成功连接后，`sudo wg` 会显示对方的公钥、IP 等信息，例如主机 A 会显示：
```
interface: wg0
  public key: 主机A的公钥
  private key: (hidden)
  listening port: 随机端口

peer: 主机B的公钥
  endpoint: 203.0.113.5:51820
  allowed ips: 10.0.0.1/32
  latest handshake: 5 seconds ago
  transfer: 128 B received, 128 B sent
```



**测试通信**

- 主机 A  ping 主机 B 的 VPN IP：
  ```bash
  ping 10.0.0.1
  ```

- 主机 B  ping 主机 A 的 VPN IP：
  ```bash
  ping 10.0.0.2
  ```

若能 ping 通，说明 VPN 隧道已成功建立，可直接通过 `10.0.0.x` 访问对方的服务（如 SSH、Web 服务等）。  



**(6). 配置开机自启（可选）**

```bash
# 启用开机自启
sudo systemctl enable wg-quick@wg0

# 停止接口（如需）
sudo wg-quick down wg0
```

<br/>



### 3. 核心原理
通过内核原生的 WireGuard 模块，两台主机建立了加密的 UDP 隧道，所有通过 `10.0.0.x` 网段的流量会被加密后传输。相比传统 VPN，WireGuard 配置更简洁，且因内核级实现，性能更优。

如果需要多台设备互联，只需在每台设备的 `wg0.conf` 中添加其他设备的 `[Peer]` 配置（公钥 + 允许的 IP）即可。
## Tailscale是什么？
**[Tailscale](https://tailscale.com/download)** 是一款基于**WireGuard**协议的零配置虚拟私有网络(VPN)工具，能让多台设备在互联网上形成一个加密的私有网络。



<br/>



## 安装Tailscale

https://tailscale.com/download



<br/>




## 场景需求
你有一台公网服务器，部署了Web服务（端口8080），但8080端口不允许公网直接访问（例如被防火墙拦截）。通过Tailscale可将你的本地设备（如电脑）与服务器加入同一私有网络，再通过服务器的Tailscale私有IP访问8080端口。



<br/>




## 操作步骤

**1.在公网服务器上安装Tailscale**
以常见的Linux服务器（如Ubuntu/Debian）为例，其他系统（Windows/macOS）可参考[Tailscale官方文档](https://tailscale.com/kb/1037/install)。

- 登录服务器，执行安装命令：

```bash
curl-fsSLhttps://tailscale.com/install.sh|sh
```
- 启动Tailscale并登录：

```bash
sudotailscaleup
```
执行后会输出一个登录链接，复制链接到本地浏览器打开，使用Google、GitHub等账号登录（需记住登录的账号，后续本地设备用同一账号）。

- 登录成功后，服务器会加入Tailscale网络，记录服务器的**Tailscale私有IP**（可通过以下命令查看）：

```bash
tailscaleip
#输出类似：100.xxx.xxx.xxx（这是服务器在私有网络中的IP）
```

**2.在本地设备（如电脑）上安装Tailscale**
根据你的本地设备系统（Windows/macOS/Linux），从[Tailscale下载页](https://tailscale.com/download)安装客户端。

- 安装后打开Tailscale，用**与服务器相同的账号**登录（确保在同一Tailscale网络中）。

- 登录成功后，本地设备会自动加入私有网络，可在Tailscale客户端界面看到服务器的设备名称和对应的私有IP（即步骤1中记录的`100.xxx.xxx.xxx`）。

**3.访问服务器的8080端口**
在本地设备的浏览器或终端中，直接通过服务器的Tailscale私有IP+8080端口访问：

- 浏览器访问：`http://100.xxx.xxx.xxx:8080`
- 终端测试（可选）：`curlhttp://100.xxx.xxx.xxx:8080`

此时访问走的是Tailscale加密隧道，无需经过公网8080端口，因此可绕过公网端口限制。



<br/>














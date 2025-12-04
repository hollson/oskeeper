以下是一个在Ubuntu系统上安装V2Ray服务端和客户端的精简实操教程：

### 服务端安装与配置（Ubuntu Server）

1. **下载安装包**
   访问 [V2Ray官方GitHub](https://github.com/v2fly/v2ray-core/releases/latest)，下载适用于Linux的压缩包（如`v2ray-linux-64.zip`）。

2. **安装依赖**

   ```bash
   bashsudo apt update
   sudo apt install -y unzip
   ```

3. **解压并安装**

   ```bash
   bashunzip v2ray-linux-64.zip -d /usr/local/v2ray
   sudo chmod +x /usr/local/v2ray/*
   ```

4. **生成配置文件**
   使用以下命令生成默认配置文件（或手动创建`/usr/local/v2ray/config.json`）：

   ```bash
   bash
   
   /usr/local/v2ray/v2ray config generate
   ```

   **修改配置**：编辑`config.json`，确保包含以下关键字段（示例为VMess协议）：

   ```json
   json{
     "inbounds": [{
       "port": 10086,
       "protocol": "vmess",
       "settings": {
         "clients": [{
           "id": "你的UUID（通过`uuidgen`命令生成）",
           "alterId": 64
         }]
       }
     }],
     "outbounds": [{
       "protocol": "freedom",
       "settings": {}
     }]
   }
   ```

5. **设置开机自启**
   创建Systemd服务文件：

   ```bash
   bashsudo tee /etc/systemd/system/v2ray.service <<EOF
   [Unit]
   Description=V2Ray Service
   After=network.target
   
   [Service]
   Type=simple
   User=nobody
   ExecStart=/usr/local/v2ray/v2ray run -c /usr/local/v2ray/config.json
   Restart=on-failure
   
   [Install]
   WantedBy=multi-user.target
   EOF
   ```

   启用并启动服务：

   ```bash
   bashsudo systemctl enable v2ray
   sudo systemctl start v2ray
   ```

6. **防火墙放行端口**

   ```bash
   bashsudo ufw allow 10086/tcp
   sudo ufw reload
   ```

### 客户端安装与配置（Ubuntu Desktop）

1. **安装客户端工具**
   推荐使用`Qv2ray`（图形化界面）或`v2ray-core`命令行工具。以`v2ray-core`为例：

   ```bash
   bashsudo apt update
   sudo apt install -y unzip
   wget https://github.com/v2fly/v2ray-core/releases/latest/download/v2ray-linux-64.zip
   unzip v2ray-linux-64.zip -d ~/v2ray-client
   chmod +x ~/v2ray-client/*
   ```

2. **配置客户端**
   创建`~/v2ray-client/config.json`，内容与服务端`config.json`中的`inbounds`部分对应（修改`port`和`id`）：

   ```json
   json{
     "outbounds": [{
       "protocol": "vmess",
       "settings": {
         "vnext": [{
           "address": "服务端IP地址",
           "port": 10086,
           "users": [{
             "id": "服务端配置的UUID",
             "alterId": 64
           }]
         }]
       }
     }]
   }
   ```

3. **启动客户端**

   ```bash
   bash
   
   ~/v2ray-client/v2ray run -c ~/v2ray-client/config.json
   ```

   **后台运行**：使用`screen`或`tmux`保持会话，或配置Systemd服务（类似服务端步骤）。

### 验证连接

- 服务端检查日志

  ：

  ```bash
  bash
  
  sudo journalctl -u v2ray -f
  ```

- **客户端测试**：访问一个网站（如`https://www.google.com`），确认流量是否通过代理。

### 注意事项

- **安全性**：建议使用TLS加密（如配合Nginx反向代理）或WebSocket传输，避免直接暴露VMess端口。
- **性能优化**：多用户场景可调整`alterId`和`workers`参数。
- **更新维护**：定期检查GitHub更新版本，替换二进制文件即可升级。
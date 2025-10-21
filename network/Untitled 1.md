Tailscale 的 `auth-key`（认证密钥）是一种无需手动登录即可让设备加入 Tailscale 网络的凭证，适用于服务器、嵌入式设备等无图形界面的场景，或需要批量/自动化添加设备的场景。以下是具体用法：


### **一、什么是 auth-key？**  
`auth-key` 是由 Tailscale 控制台生成的一次性或可重复使用的密钥，设备通过该密钥启动 Tailscale 时，无需打开浏览器登录，即可自动加入对应的 Tailscale 网络（tailnet）。  
- 适合场景：服务器初始化脚本、Docker 容器、CI/CD 自动化部署等。  


### **二、生成 auth-key**  
1. 登录 [Tailscale 控制台](https://login.tailscale.com/admin)（用你的账号）。  
2. 左侧导航栏进入 **Settings** → **Auth keys**。  
3. 点击 **Generate one-off key**（一次性密钥，用完即失效）或 **Generate reusable key**（可重复使用，适合批量添加）。  
4. 按需配置密钥参数：  
   - **Expiry**：设置密钥有效期（如 1 小时、7 天）。  
   - **Ephemeral**：勾选后，设备为“临时节点”，离线后自动从网络中移除（适合临时设备）。  
   - **Tags**：给设备添加标签（用于权限控制，如 `tag:server`）。  
5. 生成后，**立即复制密钥**（只显示一次，刷新页面后无法再查看）。  


### **三、使用 auth-key 让设备加入网络**  
在需要加入 Tailscale 网络的设备上（如服务器、虚拟机），执行以下步骤：  


#### **1. 安装 Tailscale（若未安装）**  
以 Linux 为例：  
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```


#### **2. 用 auth-key 启动并加入网络**  
执行 `tailscale up` 时，通过 `--authkey` 参数指定密钥：  
```bash
sudo tailscale up --authkey=tskey-auth-xxxxxx-yyyyyyyyyyyyyyyyyyyyyyyy
```

- 替换 `tskey-auth-xxxxxx-...` 为你生成的实际 auth-key。  
- 执行后，设备会自动完成认证，无需手动登录，直接加入你的 Tailscale 网络。  


#### **3. 验证是否成功**  
- 查看设备的 Tailscale IP：  
  ```bash
  tailscale ip
  ```
- 在 Tailscale 控制台的 **Machines** 页面，会出现该设备的名称和状态（在线/离线）。  


### **四、常见用法场景**  
1. **自动化部署脚本**：在服务器初始化脚本中嵌入 `tailscale up --authkey=...`，让服务器启动后自动加入 Tailscale 网络。  
   示例（Bash 脚本）：  
   ```bash
   # 安装 Tailscale
   curl -fsSL https://tailscale.com/install.sh | sh
   # 用 auth-key 加入网络
   sudo tailscale up --authkey=tskey-auth-xxxxxx-yyyyyyyy
   ```

2. **Docker 容器**：在 Dockerfile 或启动命令中使用 auth-key，让容器内的 Tailscale 自动联网。  
   示例（`docker run` 命令）：  
   ```bash
   docker run -it --rm --privileged \
     -v /var/run/tailscale:/var/run/tailscale \
     tailscale/tailscale \
     sh -c "tailscale up --authkey=tskey-auth-xxxxxx-yyyyyyyy && tailscale ip"
   ```

3. **临时设备访问**：生成一次性密钥，给临时设备使用，避免长期授权风险。  


### **五、注意事项**  
- **密钥安全性**：auth-key 等同于登录凭证，不可泄露给未授权人员，否则可能导致陌生设备加入你的网络。  
- **有效期**：过期的密钥无法使用，需重新生成。  
- **权限控制**：若需限制设备的访问范围，可通过控制台的 **Access Controls**（访问控制列表）结合设备标签（Tags）配置规则。  

通过 auth-key，你可以高效、自动化地管理设备加入 Tailscale 网络，尤其适合大规模部署或无交互场景。
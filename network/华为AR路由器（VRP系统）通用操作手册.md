### 一、华为AR路由器操作系统
华为AR系列路由器运行 **VRP (Versatile Routing Platform)**，是华为自研的通用网络操作系统，类似电脑的Windows，用于管理路由器、交换机等设备。
- **核心特点**：命令行（CLI）+ Web界面管理；分级权限；支持IPv4/IPv6、路由、安全、VPN等功能。
- **版本**：常见 **V200R00x**（老款）、**V300R00x**（新款）。

---

### 二、VRP基础：视图模式（必懂）
VRP采用**分层视图**，不同视图权限不同，提示符不同：

| 视图 | 提示符 | 权限 | 进入/退出 |
|---|---|---|---|
| 用户视图 | `<Huawei>` | 查看、ping、保存 | 登录默认；`quit`退出 |
| 系统视图 | `[Huawei]` | 全局配置（改名、用户、域名） | `system-view`进入；`quit`返回用户视图 |
| 接口视图 | `[Huawei-G0/0/1]` | 配置IP、开关接口 | `interface 接口名`进入；`quit`返回系统视图 |
| VTY视图 | `[Huawei-ui-vty0]` | 配置Telnet/SSH | `user-interface vty 0`进入 |

**常用快捷键**：
- `?`：帮助（如`dis?`查看display相关命令）
- `Tab`：自动补全命令
- `Ctrl+Z`：直接退到用户视图
- `display`（简写`dis`）：查看配置/状态

---

### 三、首次登录（SSH+Web，你已在用）
#### 1. SSH登录（解决老设备算法不兼容）
```bash
# 电脑CMD/PowerShell执行（强制旧算法）
ssh -o KexAlgorithms=diffie-hellman-group14-sha1 shihongsheng@1.1.1.1
```
- 输入密码 → 进入用户视图`<Huawei>` → `system-view`进入系统视图。

#### 2. Web登录（浏览器）
- 地址：`https://1.1.1.1`（默认HTTPS）
- 账号密码同SSH，适合图形化配置。

---

### 四、常用操作命令（极简，够用）
#### 1. 系统基础（必用）
```bash
# 查看版本
display version

# 查看当前配置（简写dis cur）
display current-configuration

# 保存配置（修改后必做！）
save

# 重启设备（谨慎！）
reboot

# 改设备名（系统视图下）
sysname shundong
```

#### 2. 域名映射（你刚配置的）
```bash
# 系统视图下：内网域名→IP
ip host dev.shundong.com 192.168.101.251
ip host fs.shundong.com 192.168.101.251
ip host git.shundong.com 192.168.101.251
ip host api.shundong.com 192.168.101.251
save
```

#### 3. 接口配置（IP+开关）
```bash
# 进入接口G0/0/1（WAN口）
interface GigabitEthernet 0/0/1

# 配置IP+掩码
ip address 192.168.1.1 255.255.255.0

# 启用接口（默认关闭）
undo shutdown

# 退出接口视图
quit
```

#### 4. SSH配置（允许登录）
```bash
# 系统视图下
ssh server enable
user-interface vty 0 4
authentication-mode aaa
protocol inbound ssh
quit

# 创建用户（shihongsheng，密码自定义）
aaa
local-user shihongsheng password irreversible-cipher 你的密码
local-user shihongsheng service-type ssh
local-user shihongsheng privilege level 15
quit
save
```

#### 5. 查看与测试
```bash
# 查看接口IP状态
display ip interface brief

# 测试连通性
ping 192.168.1.1
ping dev.shundong.com

# 查看域名映射
display ip host
```

---

### 五、操作流程总结（新手照着做）
1. **登录**：SSH（带算法参数）或Web → 输入账号密码。
2. **进系统视图**：`<Huawei>` → `system-view` → `[Huawei]`。
3. **配置**：域名映射/接口IP/SSH → 完成后`save`保存。
4. **验证**：`display`查看配置 → `ping`测试连通性。

---

### 六、常见问题
- **SSH报错“no matching key exchange”**：用开头带`-o KexAlgorithms=...`的SSH命令。
- **配置重启后丢失**：修改后必须执行`save`。
- **域名不生效**：`display ip host`检查映射；内网设备DNS设为路由器IP（1.1.1.1）

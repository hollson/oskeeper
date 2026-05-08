# Proxyman入门指南
Proxyman 是 macOS 平台原生高性能抓包工具，支持 HTTP/HTTPS、WebSocket 抓包，界面简洁、SSL 解密一键配置，适配电脑、手机、模拟器等多场景，核心优势是**无需复杂命令、可视化操作、自动适配 Apple Silicon**。


## 一、安装配置
### 1. 下载安装
- 官网下载：https://proxyman.io/，安装后首次启动需安装辅助工具（Install Proxy Helper Tool），授权管理员权限。


### 2. 安装根证书
HTTPS 抓包必须安装并信任 Proxyman 根证书，否则无法解密数据：
1. 顶部菜单栏 → Certificate → Install Certificate on this Mac。

2. 按提示操作，选择“Automatic（自动安装并信任）”，一键完成配置。

3. 验证：重启 Proxyman，访问任意 HTTPS 网站，请求列表无“SSL Error”即成功。

### 3. 界面核心区域
- 左侧：请求域名/应用筛选、SSL 代理开关、断点规则列表。
- 顶部：请求类型过滤（HTTP/HTTPS/WebSocket）、搜索框、抓包开关。
- 中间：请求列表（显示方法、域名、状态码、响应时间）。
- 底部：请求详情（Headers/Query/Request Body）、响应详情（Response Body/JSON 格式化）。


## 二、场景演示
## 1：电脑端（浏览器/桌面应用）抓包
### 1. 开启系统代理
- 方式1（一键开启）：Proxyman 启动后默认提示“Enable System Proxy”，点击确认，自动配置 macOS 系统代理（127.0.0.1:9090，默认端口9090）。
- 方式2（手动配置）：顶部 Proxy → Proxy Settings → 勾选“Override macOS Proxy”，端口保持9090，保存即可。


### 2. 开始抓包
1. 开启抓包开关（顶部绿色按钮）。

2. 打开浏览器（Chrome/Safari）或桌面应用，操作目标页面/功能，请求实时显示在列表中。
3. 筛选技巧：
    - 按域名筛选：点击左侧域名，仅显示对应请求。
    - 按类型筛选：顶部勾选 HTTPS/WebSocket，过滤无关请求。
    - 搜索关键词：顶部搜索框输入接口路径/参数，快速定位目标请求。


### 3. 停止抓包
- 关闭顶部绿色抓包开关，或取消“Override macOS Proxy”，恢复系统网络。

## 三、场景2：iOS 设备（真机/模拟器）抓包
### 1. 前提条件
- 电脑与 iOS 设备连接**同一 Wi-Fi**（关键！）。
- 查看电脑 IP：Proxyman 顶部 Proxy → Proxy Settings，记录本机 IP（如192.168.1.100），端口默认9090。

### 2. iOS 真机配置（iPhone/iPad）
1. 配置代理：iOS 设备 → 设置 → Wi-Fi → 点击当前 Wi-Fi 右侧“i” → 配置代理 → 手动，输入：
    - 服务器：电脑 IP（如192.168.1.100）
    - 端口：9090
    - 关闭“验证”，保存。


2. 安装根证书：
    - iOS 浏览器（Safari）访问 http://proxy.man/ssl，自动下载 Proxyman 根证书。
    - iOS 15+：设置 → 通用 → VPN与设备管理 → 找到 Proxyman 证书 → 信任。


3. 开启 SSL 代理：Proxyman 左侧右键目标域名 → Enable SSL Proxying，解密 HTTPS 数据。


4. 开始抓包：iOS 设备打开目标 App，操作功能，请求同步显示在 Proxyman 列表中。

### 3. iOS 模拟器抓包（零配置）
- 优势：无需手动配置代理、安装证书，Proxyman 自动适配。
- 操作：顶部 Certificate → Install Certificate on iOS → Simulators → 点击“Start Capture”，启动模拟器即可抓包。


## 四、场景3：Android 设备（真机/模拟器）抓包
### 1. Android 真机配置（Android 7+）
1. 同网+代理：电脑与 Android 设备同一 Wi-Fi，Wi-Fi 设置 → 修改网络 → 高级选项 → 代理 → 手动，输入电脑 IP+9090 端口，保存。


2. 安装根证书：浏览器访问 http://proxy.man/ssl，下载证书，设置 → 安全 → 更多安全设置 → 加密与凭据 → 安装证书 → 选择下载的证书，命名后安装。

3. 关键：Android 10+ 系统限制，默认不信任用户证书，**仅调试可用**：
    - 开发版 App：配置 network_security_config.xml，允许信任用户证书。
    - 正式版 App：需 root 设备，将证书移入系统证书库（/system/etc/security/cacerts/），否则无法抓包 HTTPS 请求。

### 2. Android 模拟器抓包
- 操作：顶部 Certificate → Install Certificate on Android → Emulators → 按提示运行自动脚本，一键配置代理+证书，启动模拟器即可抓包。

## 五、场景4：WebSocket 抓包（实时消息/推送）
1. 开启抓包：同电脑/手机抓包步骤，确保 SSL 代理已开启目标域名。
2. 筛选 WebSocket：顶部过滤栏勾选“WebSocket”，列表仅显示 WebSocket 连接请求。
3. 查看详情：选中 WebSocket 请求，底部切换到“WebSocket”标签，实时显示收发的消息数据（文本/JSON 格式化）。


## 六、高频实用技巧（提升效率）
### 1. 断点调试（修改请求/响应）
1. 开启断点：顶部 Tools → Breakpoints → 勾选“Enable Breakpoints”。

2. 添加规则：点击“+”，设置触发条件（如域名/路径/方法），保存。
3. 拦截修改：触发请求时自动暂停，底部可修改 Request Body/Response Body，点击“Continue”发送修改后数据。

### 2. 本地映射（Mock 数据）
- 场景：接口未开发完成，本地模拟响应数据。
- 操作：选中请求 → 右键 → Map Local → 选择本地 JSON 文件，自动替换响应内容，App 直接读取本地数据。

### 3. 过滤系统请求（减少干扰）
- 问题：抓包时大量系统进程请求（如 iCloud、系统更新）干扰。
- 解决：左侧筛选栏勾选“Hide System Traffic”，仅显示用户应用请求。

## 七、常见问题排查
1. 抓不到请求：
    - 电脑与设备是否同一 Wi-Fi，IP/端口是否正确。
    - 根证书是否安装并信任，SSL 代理是否开启目标域名。
    - 关闭 VPN/防火墙，避免拦截代理连接。
2. HTTPS 显示“SSL Error”：
    - 重新安装根证书，确保“信任”权限生效。
    - 目标 App 开启 SSL Pinning（证书锁定），需绕过（仅调试）。
3. 手机网络异常：
    - 抓包完成后，关闭 Proxyman 或取消代理，恢复正常网络。

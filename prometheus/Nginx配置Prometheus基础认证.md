### 配置Prometheus基础认证
#### 一、核心前置（已完成）
- Nginx已安装并运行
- Prometheus内网地址：`127.0.0.1:9090`
- 服务器有root权限

#### 二、步骤1：生成认证密码文件（1分钟搞定）
```bash
# 安装htpasswd工具（Rocky/Ubuntu通用）
## Rocky
yum install -y httpd-tools
## Ubuntu
apt install -y apache2-utils

# 创建密码文件（创建admin用户，执行后输入密码）
mkdir -p /etc/nginx/conf.d/auth
htpasswd -c /etc/nginx/conf.d/auth/prom.htpasswd admin

# 权限加固（仅Nginx可读）
chmod 640 /etc/nginx/conf.d/auth/prom.htpasswd
chown nginx:nginx /etc/nginx/conf.d/auth/prom.htpasswd
```

#### 三、步骤2：编写Nginx认证配置（核心）
```bash
# 创建Prometheus专属配置文件
vim /etc/nginx/conf.d/prometheus.conf
```
写入以下精简配置（替换`your_domain/ip`为实际域名/服务器IP）：
```nginx
server {
    listen 80;
    server_name your_domain/ip;  # 如192.168.1.100或prom.example.com

    # 基础认证核心
    auth_basic "Prometheus Auth";
    auth_basic_user_file /etc/nginx/conf.d/auth/prom.htpasswd;

    # 反向代理到Prometheus
    location / {
        proxy_pass http://127.0.0.1:9090;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_read_timeout 300s;  # 适配长查询
    }

    # 可选：IP白名单（仅允许指定IP访问，更安全）
    allow 192.168.1.0/24;  # 你的内网网段
    deny all;
}
```

#### 四、步骤3：验证+重启Nginx（关键）
```bash
# 检查配置语法（必做，避免报错）
nginx -t

# 重启Nginx生效
systemctl restart nginx
```

#### 五、步骤4：验证认证效果（快速测试）
```bash
# 正确认证（返回200）
curl -u admin:你的密码 http://your_domain/ip/api/v1/query?query=up

# 无认证（返回401）
curl -I http://your_domain/ip
```

#### 六、Python应用适配（核心对接）
```python
from prometheus_api_client import PrometheusConnect

# 对接带认证的Prometheus
prom = PrometheusConnect(
    url="http://your_domain/ip",  # Nginx地址
    auth=("admin", "你的密码"),   # 认证信息
    disable_ssl=False
)

# 测试查询
print(prom.custom_query("up"))
```

#### 七、生产必加：HTTPS配置（精简版）
```bash
# 安装certbot申请免费证书（Rocky/Ubuntu通用）
## Rocky
yum install -y certbot python3-certbot-nginx
## Ubuntu
apt install -y certbot python3-certbot-nginx

# 自动配置HTTPS（替换域名）
certbot --nginx -d prom.example.com
```
执行后自动修改Nginx配置，强制HTTP跳转HTTPS，无需手动改配置。

### 总结
1. **核心操作**：生成密码文件 → 写Nginx认证配置 → 重启验证 → 适配Python应用；
2. **关键安全点**：基础认证+IP白名单+HTTPS，三步搞定Prometheus访问安全；
3. **验证标准**：无密码访问返回401，带密码返回200，Python应用可正常查询数据。
# Nginx双集群高可用方案


# 一、架构说明（最优生产方案）
## 1.1 环境信息
| 名称 | 地址 | 用途 |
|---|---|---|
| 对外域名 | example.com | 前端 React 访问 |
| 对外 API 域名 | api.example.com | 后端 FastAPI 访问 |
| React 节点 | 172.16.1.10:8080、172.16.1.11:8080 | 前端 Web 服务 |
| FastAPI 节点 | 172.16.2.1:5000、172.16.2.2:5000 | 后端 API 服 |

## 1.2 标准生产架构图
```
用户浏览器
      ↓
example.com (HTTPS 443)
      ↓
Nginx 负载均衡
      ↓
┌─────────────────┐
│ React 集群      │
│ 172.16.1.10:8080│
│ 172.16.1.11:8080│
└─────────────────┘
      ↓ 【前端调用后端】
api.example.com (HTTPS 443)
      ↓
Nginx 负载均衡
      ↓
┌─────────────────┐
│ FastAPI 集群    │
│ 172.16.2.1:5000 │
│ 172.16.2.2:5000 │
└─────────────────┘
```

## 1.3 关键架构说明（非常重要）
1. **前端 React（s1/s2）不直接调用后端 FastAPI 节点**
2. **前端统一通过域名 api.example.com 访问后端**
3. **api.example.com 由 Nginx 做负载均衡 + 故障转移**
4. 好处：
   - 前端代码**无需区分环境、无需硬编码 IP**
   - 后端扩容、缩容、切换**前端完全无感知**
   - 单台 API 挂掉，Nginx 自动切换，前端不报错
   - 符合生产环境**高可用、解耦、安全标准**

---

# 2. 生产级 Nginx 完整配置
文件路径：`/etc/nginx/conf.d/example.com.conf`

```nginx
# ------------------------------
# 1. 前端 React 集群
# ------------------------------
upstream react_backend {
    server 172.16.1.10:8080 max_fails=3 fail_timeout=30s;
    server 172.16.1.11:8080 max_fails=3 fail_timeout=30s;
    keepalive 64;
}

# ------------------------------
# 2. 后端 FastAPI 集群
# ------------------------------
upstream fastapi_backend {
    server 172.16.2.1:5000 max_fails=3 fail_timeout=30s;
    server 172.16.2.2:5000 max_fails=3 fail_timeout=30s;
    keepalive 64;
}

# ------------------------------
# 前端 React 80 → 443 跳转
# ------------------------------
server {
    listen 80;
    server_name example.com;
    return 301 https://$host$request_uri;
}

# ------------------------------
# 前端 React HTTPS 代理
# ------------------------------
server {
    listen 443 ssl;
    server_name example.com;

    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://react_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 30s;
    }
}

# ------------------------------
# 后端 FastAPI 80 → 443 跳转
# ------------------------------
server {
    listen 80;
    server_name api.example.com;
    return 301 https://$host$request_uri;
}

# ------------------------------
# 后端 FastAPI HTTPS 代理
# ------------------------------
server {
    listen 443 ssl;
    server_name api.example.com;

    ssl_certificate /etc/nginx/ssl/example.com.crt;
    ssl_certificate_key /etc/nginx/ssl/example.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        proxy_pass http://fastapi_backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_connect_timeout 5s;
        proxy_send_timeout 10s;
        proxy_read_timeout 30s;
    }
}
```

---

# 3. 前端 React 正确配置（生产标准）
## 前端 .env 配置
```env
# 正确：统一走 Nginx 负载域名
REACT_APP_API_URL=https://api.example.com

# 错误（禁止）：硬编码后端IP
# REACT_APP_API_URL=http://172.16.2.1:5000
```

## 说明
前端 s1、s2 **都使用同一个 api.example.com**
→ 由 Nginx 负责负载均衡、故障转移、健康检查
→ 前端**永远不需要修改配置**

---

# 4. 高可用能力说明
1. **React 高可用**
   - 任一节点宕机 → 自动切换到另一节点
   - 用户访问 example.com 完全无感

2. **FastAPI 高可用**
   - 任一 API 节点宕机 → Nginx 自动剔除
   - 前端请求自动转发到健康节点
   - 无 502/504 错误

3. **故障转移规则**
   ```
   max_fails=3     # 3次请求失败判定宕机
   fail_timeout=30s # 30秒内隔离故障节点
   ```

---

# 5. 标准操作流程（生产可直接执行）
```bash
# 1. 编辑配置
vim /etc/nginx/conf.d/example.com.conf

# 2. 检查语法
nginx -t

# 3. 平滑加载（不中断业务）
nginx -s reload

# 4. 验证服务
curl https://example.com
curl https://api.example.com
```

---

# 6. 生产最佳实践
1. **前后端必须使用域名访问，禁止硬编码 IP**
2. 前端 React 统一走 `api.example.com` 调用后端
3. 前后端使用独立 upstream，互不干扰
4. 单节点宕机 → 自动切换 → 业务无损
5. 证书使用泛域名证书 `*.example.com` 最佳

---

# 7. 总结（最优生产架构）
✅ **前端 + 后端双集群高可用**
✅ **Nginx 自动负载均衡 + 故障转移**
✅ **前端不硬编码 IP，环境统一**
✅ **单节点宕机用户完全无感知**
✅ **生产标准、可直接上线**
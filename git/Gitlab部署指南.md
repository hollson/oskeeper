

# 搭建Gitlab服务





## 1. 运行GitLab
```shell
# 拉取镜像
docker pull gitlab/gitlab-ce:latest

# 工作目录
sudo mkdir -p /var/gitlab/{config,logs,data}
sudo chmod -R 750 /var/gitlab

# 启动容器
sudo docker run --detach \
  --name gitlab \
  --publish 9043:443 \
  --publish 9080:80 \
  --publish 9022:22 \
  --restart always \
  --volume /var/gitlab/config:/etc/gitlab \
  --volume /var/gitlab/logs:/var/log/gitlab \
  --volume /var/gitlab/data:/var/opt/gitlab \
  gitlab/gitlab-ce:latest

# 初始化需要耐心等待(十分钟内都正常)，可通过命令查看进度
docker logs -f gitlab
```

## 2. 配置GitLab
- 由于`22端口已经被宿主机占用`，所以我们必须另指定一个端口(`9022`)映射到gitlab上。
```shell
sudo vim /var/gitlab/config/gitlab.rb
# ************************gitlab配置************************
# 配置http协议
external_url 'http://git.shundong.xyz'

# 配置ssh协议
gitlab_rails['gitlab_ssh_host'] = 'git.shundong.xyz'
gitlab_rails['gitlab_shell_ssh_port'] = 9022
gitlab_rails['time_zone'] = 'Asia/Shanghai'
# *************************************************************
```
重新加载GitLab配置
```bash
sudo docker restart gitlab
```


## 3. 配置Nginx[可选]

```bash
sudo vim /etc/nginx/conf.d/gitlab.conf
```

```nginx
server {
    listen 80;
    server_name git.shundong.xyz;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name git.shundong.xyz;

    # SSL证书配置
    ssl_certificate /var/gitlab/gitlab.crt;
    ssl_certificate_key /var/gitlab/gitlab.key;
    # 注意：.csr文件是证书请求文件，不需要在Nginx中配置

    # SSL安全配置（推荐）
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384';
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    ssl_session_tickets off;
    ssl_stapling on;
    ssl_stapling_verify on;
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;

    # 安全头部
    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # 日志配置
    access_log /var/log/nginx/gitlab.access.log;
    error_log /var/log/nginx/gitlab.error.log;

    # 代理配置
    location / {
        # 根据您的实际需求选择代理到哪个端口
        # 通常是HTTP服务代理到9080，HTTPS服务代理到9043
        # 这里假设9080是HTTP服务
        proxy_pass http://192.168.X.X:9080;
        
        # 如果9043是HTTPS服务，则使用：
        # proxy_pass https://192.168.X.X:9043;
        # 注意：如果使用HTTPS代理，可能需要添加 proxy_ssl_* 配置

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-SSL on;
        
        # WebSocket支持（GitLab需要）
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        # 性能优化
        proxy_buffers 16 16k;
        proxy_buffer_size 32k;
        
        # 超时设置
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;
        proxy_redirect off;
    }

    # 可选：GitLab Webhook的特殊处理（如果需要）
    # location ~ ^/[^/]+\/[-a-zA-Z0-9_]+\/hooks {
    #     proxy_pass http://192.168.X.X:9080;
    #     proxy_set_header Host $host;
    #     proxy_set_header X-Real-IP $remote_addr;
    #     proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    #     proxy_set_header X-Forwarded-Proto $scheme;
    # }

    # 可选：静态文件缓存设置（如果适用）
    # location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
    #     expires 1y;
    #     add_header Cache-Control "public, no-transform";
    # }
}
```

```bash
# 替换192.168.X.X为自己的IP，如：
sudo sed -i 's/192.168.X.X/192.168.101.251/g' /etc/nginx/conf.d/gitlab.conf

# 自签名证书
sudo mkdir -p /var/gitlab
sudo openssl req -x509 -nodes -days 730 -newkey rsa:4096 \
  -keyout /var/gitlab/gitlab.key -out /var/gitlab/gitlab.crt \
  -subj "/C=CN/ST=Beijing/L=Beijing/O=GitLab/OU=IT/CN=git.shundong.xyz" -sha256
sudo chmod 600 /var/gitlab/gitlab.key
sudo chmod 644 /var/gitlab/gitlab.crt

# 重启Nginx
sudo nginx -t
sudo nginx -s reload
```





##  4. 登录GitLab

- 访问 http://git.shundong.xyz 

- 使用管理员账号登录，用户名是`root`，密码通过如下命令获取，**建议登录后立即修改密码**。

```bash
docker exec -it gitlab grep 'Password:' /etc/gitlab/initial_root_password
```



<br/>







## 备份还原



## 配置邮件







## CICD



## 安装Runner
```shell
docker pull gitlab/gitlab-runner:latest

mkdir -p /data/etc/gitlab-runner
```
```shell
docker run \
--detach \
--name gitlab-runner \
--restart always \
--volume /data/etc/gitlab-runner:/etc/gitlab-runner \
--volume /var/run/docker.sock:/var/run/docker.sock \
gitlab/gitlab-runner:latest
```

```shell
# 进入gitlab-runner容器
docker exec -it gitlab-runner bash

# 查看gitlab-runner版本
gitlab-runner -v

# 注册
gitlab-runner register
```


> **Gitlab官网：**  [https://about.gitlab.com/](https://about.gitlab.com/)
> **Gitlab安装：**   [https://gitlab.cn/install/](https://gitlab.cn/install/)




> 参考：
> [推荐]https://blog.csdn.net/michael_base/article/details/77966647
> https://blog.csdn.net/u014258541/article/details/79224492/
>
> https://blog.csdn.net/cen50958/article/details/93352349
>
> [CI/CD服务]：https://github.com/bravist/gitlab-ci-docker
>
> https://blog.csdn.net/sunyuhua_keyboard/article/details/124901471
>
> https://blog.csdn.net/jiangxiaoyi_07/article/details/131644370


https://blog.csdn.net/weixin_39246554/article/details/130749706

https://zhuanlan.zhihu.com/p/652503159






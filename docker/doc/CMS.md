# SSCMS操作手册

## 一. 安装CMS
>  Docker安装过程参考[官方文档](https://sscms.com/docs/v7/getting-started/)。



## 二. 安装记录

### 2.1 塑久

#### 2.1.1 安装网站

```shell
docker run -d \
    --name sujiu \
    -p 8001:80 \
    --restart=always \
    -v "$(pwd)"/wwwroot/sujiu:/app/wwwroot \
    -e SSCMS_SECURITY_KEY=e2a3d303-ac9b-41ff-9154-930710af0845 \
    -e SSCMS_DATABASE_TYPE=SQLite \
    sscms/core:latest
```

#### 2.1.2 配置网站

>  http://35.92.37.23:8001/ss-admin/install

#### 2.1.3 访问网站

> 帐号： hollson/Log4net

http://35.92.37.23:8001/ss-admin/

http://35.92.37.23:8001/index.html

http://su9.mafool.com/index.html

http://sujiu.mafool.com/index.html





### 2.2 GRC.UHPC

```shell
docker run -d \
    --name grcuhpc \
    -p 8002:80 \
    --restart=always \
    -v "$(pwd)"/wwwroot/grcuhpc:/app/wwwroot \
    -e SSCMS_SECURITY_KEY=e2a3d303-ac9b-41ff-9154-930710af0845 \
    -e SSCMS_DATABASE_TYPE=SQLite \
    sscms/core:latest
```

#### 2.1.2 配置网站

>  http://35.92.37.23:8002/ss-admin/install

#### 2.1.3 访问网站

> 帐号： hollson/Log4net

http://35.92.37.23:8002/ss-admin/

http://35.92.37.23:8002/index.html

http://grcuhpc.com/index.html

http://www.grcuhpc.com/index.html





## 三. 配置域名

```shell
vim /www/server/panel/vhost/nginx/sujiu.conf
```

```nginx
server {
    listen 80;
    server_name su9.mafool.com sujiu.mafool.com s9floor.com;

    root /root/wwwroot/sujiu;
    index index.html;

    location / {
        proxy_pass         http://localhost:8001;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /var/www/html;
    }

    access_log /var/log/nginx/access_su9.log;
    error_log /var/log/nginx/error_su9.log;
}
```

```shell
vim /www/server/panel/vhost/nginx/grcuhpc.conf
```

```nginx
server {
    listen 80;
    server_name grcuhpc.com www.grcuhpc.com;

    root /root/wwwroot/grcuhpc;
    index index.html;

    location / {
        proxy_pass         http://localhost:8002;
        proxy_http_version 1.1;
        proxy_set_header   Upgrade $http_upgrade;
        proxy_set_header   Connection keep-alive;
        proxy_set_header   Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /var/www/html;
    }

    access_log /var/log/nginx/access_grcuhpc.log;
    error_log /var/log/nginx/error_grcuhpc.log;
}
```

```shell
nginx -s reload
```



## 四. 备份网站

- 备份镜像
- 备份网站



## 五. 问题记录

### 5.1 重新建站

进入`wwwroot`所在目录，执行只`docker run...`, 启动容器后自动挂载站点内容，无需再次安装网站。







## 相关链接

https://sscms.com/docs/v7/

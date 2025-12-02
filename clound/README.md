

## 文件共享/云存储

  ## Nextcloud

[**Nextcloud**](https://nextcloud.com) 是 [开源](https://github.com/nextcloud) 的私有云服务。用户可以把文件、协作、聊天和日历都放在自己可控的服务器上，支持浏览器、桌面和Android/iOS访问。



**特点：**

- 开源、自托管的私有云平台，数据由你掌控。  
- 文件同步与共享（版本、回收站、密码/过期链接）。  
- 在线协作（可接入 Collabora/ONLYOFFICE，多人实时编辑）。  
- 即时消息与音视频会议（Nextcloud Talk）。  
- 日历/联系人/邮件同步（CalDAV/CardDAV/IMAP）。  
- 客户端：Web、桌面（Windows/macOS/Linux）、移动（Android/iOS）。  
- 安全与认证：LDAP/SSO、2FA、服务器端加密，可选端到端加密。  
- 可扩展：应用商店、WebDAV/REST API、挂载外部存储（S3/SMB等）。  
- 部署灵活：单机/Docker/Snap/Kubernetes，支持高可用与对象存储。  
- 适用场景：需要数据主权与企业级协作的个人、团队或组织。



**安装服务：**

```shell
$ mkdir -p /var/nextcloud

$ docker run -d \
  -p 8084:80 \
  -e NEXTCLOUD_ADMIN_USER=admin \
  -e NEXTCLOUD_ADMIN_PASSWORD=123456 \
  -v /var/nextcloud/html:/var/www/html \
  -v /var/nextcloud/config:/var/www/html/config \
  -v /var/nextcloud/data:/var/www/html/data \
  -v /var/nextcloud/custom_apps:/var/www/html/custom_apps \
  nextcloud:apache
```



**安装客户端**

_参考官方资料：https://nextcloud.com/install/#install-clients_





## Cloudreve

```shell
docker pull sj26/mailcatcher

# SMTP服务端口（应用发送邮件至此）
# Web界面端口（浏览器访问查看邮件）
docker run -d \
  --name mailcatcher \
  -p 1025:1025 \
  -p 1080:1080 \
  sj26/mailcatcher

# MAILCATCHER_SMTP_IP: 允许外部访问SMTP服务
# MAILCATCHER_HTTP_IP: 允许外部访问Web界面
# smtp-port: 覆盖默认SMTP端口
# http-port: 覆盖默认HTTP端口
# 2525: 自定义SMTP端口
# 8080: 自定义HTTP端口
docker run -d --name mailcatcher\
  -e MAILCATCHER_SMTP_IP=0.0.0.0 \
  -e MAILCATCHER_HTTP_IP=0.0.0.0 \
  -p 2525:2525 \
  -p 8080:8080 \
  sj26/mailcatcher \
  --smtp-port 2525 \
  --http-port 8080 \
  --ip 0.0.0.0

docker rm -f mailcatcher





docker run --name=mailcatcher -d \
-p 1025:1025 \
-p 1080:1080 \
dockage/mailcatcher
```

```shell
echo "Test email body" | swaks --to hollson@qq.com --from sender@example.com --server 127.0.0.1 --port 1025
```



```shell

# 启动SMTP
mailer_smtp_enable=true
# 使用基础SMTP配置，无需自定义
mailer_use_custom_configs=false
#自定义发件邮箱，无需真实
mailer_address_from=hoppscotch@example.com
# 替换为你的Docker桥接IP+1025端口
mailer_smtp_url=smtp://172.17.0.1:1025

```





```shell
# SMTP邮件认证配置
docker run --name=mailcatcher -d \
-p 1025:1025 \
-p 1080:1080 \
dockage/mailcatcher

# 发送测试邮件
echo "hello" | swaks --to receiver@gmail.com --from sender@gmail.com --server 127.0.0.1 --port 1025

# 验证Mailcatcher，访问http://172.17.0.1:1080，能打开邮件管理界面即成功。
```


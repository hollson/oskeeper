# Hoppscotch实操指南

本文通过**All-In-One（AIO）容器**方式[快速部署Hoppscotch社区版](https://docs.hoppscotch.io/documentation/self-host/community-edition/install-and-build) ，将前端、后端、管理后台等服务集成在一个Docker容器中，简化部署流程。



## 一. 准备工作

### 1.1 安装数据库

- **Hoppscotch** 仅支持**Postgres**数据库, 以下是[Docker](https://docs.docker.com/engine/install/ubuntu/)安装postgreSQL的过程，**若已安装则可忽略**。

```shell
# 创建挂载目录
mkdir -p ${HOME}/.local/postgres

# 安装PGSQL(注意：配置数据库账号)
docker run --name mypostgres \
  -e POSTGRES_PASSWORD=123456 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -p 5432:5432 \
  -v ${HOME}/.local/postgres:/var/lib/postgresql \
  --restart always \
  -d postgres:latest \
  -c listen_addresses='*'

# 验证(查看容器和数据库版本)
docker ps -a
docker exec -it mypostgres psql -U postgres -c "SELECT version();"

# docker rm -f mypostgre
```

### 1.2 安装SMTP

```shell
# SMTP邮件认证配置
docker run --name=mailcatcher -d \
-p 1025:1025 \
-p 1080:1080 \
dockage/mailcatcher

# 简单邮件测试
swaks --from a@gmail.com --to b@gmail.com --server 127.0.0.1 --port 1025 --body "Hello"

# 完整参数测试
swaks --from a@gmail.com \
      --to b@gmail.com \
      --server 127.0.0.1:1025 \
      --header "Subject: Hoppscotch_Auth" \
      --header "X-Mailer: CustomMailer_v1.0" \
      --header "Message-Id: <$(date +%s)@gmail.com>" \
      --body "Welcome to join the Hoppscotch."
```

_访问 http://172.17.0.1:1080 能打开邮件管理界面即成功。_



<br/>




## 二. 安装Hoppscotch

### 2.1 配置文件

```shell
# 创建安装目录
mkdir -p ${HOME}/.local/hoppscotch && cd ${HOME}/.local/hoppscotch

# 创建.env文件，并添加以下内容（根据实际需求修改） 
vim .env 
```

```ini
#-----------------------Backend Config------------------------------#
# Prisma配置(DATABASE_URL=postgresql://username:password@url:5432/dbname)
DATABASE_URL=postgresql://postgres:123456@192.168.X.XX:5432/hoppscotch 

#【可选】AIO容器(All-In-One单容器)下暴露的端口，默认是3000
HOPP_AIO_ALTERNATE_PORT=8080

# 存储在数据库中的敏感数据加密密钥(32位随机字符)
DATA_ENCRYPTION_KEY=abcdefghijklmnopqrstuvwxyz123456

# 白名单来源
# 指定允许与你的Hoppscotch实例进行跨域通信的地址列表
# 若要支持桌面端，必须包含 app://localhost_3200 或对应 bundle 服务器的地址
WHITELISTED_ORIGINS=http://localhost:3170,http://localhost:3000,http://localhost:3100,app://localhost_3200,app://hoppscotch

#-----------------------Frontend Config------------------------------#
# 基础URL
VITE_BASE_URL=http://localhost:3000
VITE_SHORTCODE_BASE_URL=http://localhost:3000
VITE_ADMIN_URL=http://localhost:3100

# 后端URL
VITE_BACKEND_GQL_URL=http://localhost:3170/graphql
VITE_BACKEND_WS_URL=wss://localhost:3170/graphql
VITE_BACKEND_API_URL=http://localhost:3170/v1

# 服务条款和隐私政策链接（可选）
# VITE_APP_TOS_LINK=https://docs.hoppscotch.io/support/terms
# VITE_APP_PRIVACY_POLICY_LINK=https://docs.hoppscotch.io/support/privacy

# 设置为true以启用基于子路径的访问，如：
# 启用后（true）：AIO 容器的服务会自动映射到子路径（前端 /、管理端 /admin、后端 /backend）
# http://localhost:8080
# http://localhost:8080/admin
# http://localhost:8080/frontend
# 注意：需配置反向代理（如Nginx）将子路径请求转发至容器。
ENABLE_SUBPATH_BASED_ACCESS=true
```

**实例：**

```shell
# 实验
#-----------------------Backend Config------------------------------#
DATABASE_URL=postgresql://postgres:123456@192.168.3.31:5432/hoppscotch
DATA_ENCRYPTION_KEY=J7vQx2nY8pLkR3mZ9sT4wE6fG1hJ5oD2

WHITELISTED_ORIGINS=http://localhost:3170,http://localhost:3000,http://localhost:3100,http://192.168.3.31:3100,http://192.168.3.31:3000,app://localhost_3200,app://hoppscotch

#-----------------------Frontend Config------------------------------#
# Base URLs
VITE_BASE_URL=http://192.168.3.31:3000
VITE_SHORTCODE_BASE_URL=http://192.168.3.31:3000
VITE_ADMIN_URL=http://192.168.3.31:3100

# Backend URLs
VITE_BACKEND_GQL_URL=http://192.168.3.31:3170/graphql
VITE_BACKEND_WS_URL=ws://192.168.3.31:3170/graphql
VITE_BACKEND_API_URL=http://192.168.3.31:3170/v1

# Set to `true` for subpath based access
ENABLE_SUBPATH_BASED_ACCESS=false
```





### 2.2迁移数据库

创建hoppscotch数据库，并使用hoppscotch镜像初始化表结构。

```shell
# 创建数据库
docker exec -it mypostgres psql -U postgres -c "CREATE DATABASE hoppscotch;"
docker exec -it mypostgres psql -U postgres -c "\l"

# 拉取hoppscotch的AIO镜像，即将frontend、admin和backend三个镜像打包在一起的集合镜像
docker pull hoppscotch/hoppscotch

# 使用hoppscotch镜像初始化表结构
docker run --rm --env-file .env hoppscotch/hoppscotch npx prisma migrate deploy
```





### 2.2 启动容器

```shell
# 前端、管理员、后端
docker run -d --name hoppscotch -p 3000:3000 -p 3100:3100 -p 3170:3170 --env-file .env --restart unless-stopped hoppscotch/hoppscotch

docker rm -f hoppscotch
```



### 2.3 系统初始化



1. **在初始化页面填写 SMTP 配置**：回到 `http://192.168.3.31:3100/onboarding` 的认证配置页，按以下参数填写（适配本地 SMTP）：

   | 配置项        | 填写内容             | 说明                                   |
   | ------------- | -------------------- | -------------------------------------- |
   | Address From  | `shundong@gmail.com` |                                        |
   | SMTP Host     | 192.168.3.31         | 本地 SMTP 服务的IP                     |
   | SMTP Port     | 1025                 | MailHog 默认 SMTP 端口（无需 SSL）     |
   | SMTP User     | `admin@gmail.com`    | 自定义局域网邮箱（无需真实存在）       |
   | SMTP Password | 123456               | 无需真实认证，填任意值即可             |
   | 加密方式      | 选择 “无”（或 None） | 本地 SMTP 不支持 SSL/TLS，避免配置错误 |
   
   



1. 重启 Hoppscotch 容器，访问 `http://192.168.3.31:3100/onboarding?step=2`，选择 **邮件登录**。
2. 输入任意邮箱（如 `test@example.com`），点击发送验证邮件。
3. 访问 `http://172.17.0.1:1080`，在 Mailcatcher 界面中找到新邮件，点击链接即可完成认证。



## 客户端配置


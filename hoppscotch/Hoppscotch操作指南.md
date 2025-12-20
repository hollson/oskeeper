# Hoppscotch操作指南

## 引言

本文旨在指导用户通过**All-In-One（AIO）容器**方式快速部署Hoppscotch社区版，适用于生产环境。AIO容器将前端、后端、管理后台等服务集成在一个Docker容器中，简化部署流程。



## 准备工作

- **安装Postgres数据库：**(hoppscotch仅支持postgres数据库，若已安装则可忽略）

```shell
# 创建挂载目录
$ mkdir -p $HOME/.local/postgres

# 拉取镜像
$ docker pull postgres

# 安装PGSQL
$ docker run --name mypostgres \
  -e POSTGRES_PASSWORD=123456 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_DB=postgres \
  -e POSTGRES_HOST_AUTH_METHOD=md5 \
  -e POSTGRES_INITDB_ARGS="--data-checksums" \
  -p 5432:5432 \
  -v $HOME/.local/postgres:/var/lib/postgresql \
  --restart always \
  -d postgres:latest \
  -c listen_addresses='*'

# 验证
docker ps -a
docker exec -it mypostgres psql -U postgres -c "SELECT version();"
docker exec -it mypostgres psql -U postgres -c "\l"
# docker rm -f mypostgres
```

- **创建hoppscotch数据库并初始化**

```shell
# 创建数据库
docker exec -it mypostgres psql -U postgres -c "CREATE DATABASE hoppscotch;"
docker exec -it mypostgres psql -U postgres -c "\l"

# 使用hoppscotch/hoppscotch镜像初始化表结构
docker run --rm --env-file .env hoppscotch/hoppscotch npx prisma migrate deploy
```




## 一、环境配置

### 1. 创建环境变量文件

在项目根目录下创建`.env`文件，并添加以下内容（根据实际需求修改）：

```ini
#-----------------------Backend Config------------------------------#
# Prisma配置
# DATABASE_URL=postgresql://username:password@url:5432/dbname  # 替换为您的Postgres数据库URL
DATABASE_URL=postgresql://postgres:123456@192.168.3.31:5432/hoppscotch 

# (可选) 默认情况下，AIO容器在子路径访问模式下将端点暴露在80端口。如需指定不同端口，请使用此设置。
HOPP_AIO_ALTERNATE_PORT=80

# 存储在数据库中的敏感数据加密密钥(32位随机字符)
DATA_ENCRYPTION_KEY=J7vQx2nY8pLkR3mZ9sT4wE6fG1hJ5oD2

# 白名单来源，控制哪些来源可以通过跨源通信与应用程序交互
# - localhost端口（3170, 3000, 3100）：应用、后端、开发服务器和服务
# - app://localhost_3200: 包服务器来源标识符
# 注意：这里的3200指的是提供包的包服务器端口，而不是应用运行的端口。应用本身使用`app://`协议和动态包名，如`app://{bundle-name}/`
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

# 设置为true以启用基于子路径的访问
ENABLE_SUBPATH_BASED_ACCESS=false
```

### 2. 关键变量说明

- `DATABASE_URL`：Postgres数据库连接地址（需提前部署数据库）。
- `DATA_ENCRYPTION_KEY`：32位随机字符串，用于加密敏感数据。
- `WHITELISTED_ORIGINS`：允许与Hoppscotch交互的域名（如前端、管理后台）。



<br/>



## 二、部署AIO容器

### 1. 拉取AIO容器

```bash
docker pull hoppscotch/hoppscotch:community-aio
```

### 2. 启动容器

```bash
bashdocker run -d \
  --name hoppscotch-aio \
  -p 8080:80 \  # 默认暴露80端口，可修改为其他端口（如8080:80）
  -v $(pwd)/.env:/app/.env \  # 挂载环境变量文件
  --restart unless-stopped \
  hoppscotch/hoppscotch:community-aio
```

### 3. 验证部署

- 打开浏览器访问 `http://localhost:8080`（或自定义端口）。
- 管理后台地址：`http://localhost:8080/admin`（需在`.env`中配置`ENABLE_SUBPATH_BASED_ACCESS=true`）。

------

## 三、高级配置

### 1. 修改端口

若默认端口`80`被占用，通过`HOPP_AIO_ALTERNATE_PORT`指定其他端口：

```ini
ini# .env文件中添加
HOPP_AIO_ALTERNATE_PORT=8080
```

启动时映射端口：

```bash
docker run -p 8080:8080 ...  # 保持宿主机与容器端口一致
```

### 2. 启用子路径访问

在`.env`中设置：

```ini
ENABLE_SUBPATH_BASED_ACCESS=true
```

访问路径示例：

- 前端：`http://localhost:8080/frontend`
- 管理后台：`http://localhost:8080/admin`

> **注意**：需配置反向代理（如Nginx）将子路径请求转发至容器。







https://docs.hoppscotch.io/documentation/self-host/community-edition/install-and-build

```shell
docker pull hoppscotch/hoppscotch

# 前端、后端、管理员
docker run -d --name hoppscotch -p 3000:3000 -p 3170:3170 -p 3100:3100 --env-file .env --restart unless-stopped hoppscotch/hoppscotch


npx prisma migrate deploy
 

docker run -d --name hoppscotch-frontend -p 3000:3000 --env-file .env --restart unless-stopped hoppscotch/hoppscotch-frontend
docker run -d --name hoppscotch-backend -p 3170:3170 --env-file .env --restart unless-stopped hoppscotch/hoppscotch-backend
docker run -d --name hoppscotch-admin -p 3100:3100 --env-file .env --restart unless-stopped hoppscotch/hoppscotch-admin
```






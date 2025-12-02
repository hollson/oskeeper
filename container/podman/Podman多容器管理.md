# Podman Compose 多容器管理



## 一、Podman Compose是什么？

Podman Compose是 **Docker Compose 的无守护进程替代方案**，基于Python开发，通过调用Podman命令管理多容器应用。

**核心特性：**

- **兼容 Docker Compose YAML**：直接复用 `docker-compose.yml` 配置，无需修改。
- **无根运行**：支持普通用户操作，无需 `sudo`（需提前配置子 UID/GID）。
- **安全轻量**：无后台守护进程，减少攻击面，资源占用更低。
- **Pod 集成**：可将多容器封装为 Kubernetes Pod（需手动配置）。



<br/>



## 二、安装Podman Compose

- **Fedora/RHEL/CentOS**

    ```bash
    sudo dnf install -y podman-compose
    ```
    
- **其他 Linux/macOS**

    ```bash
    pip3 install --user podman-compose
    ```
    
- **验证安装**：

    ```bash
    podman-compose --version  # 输出如：podman-compose version 1.0.6
    ```



<br/>



## 三、核心配置

Podman Compose 完全兼容 Docker Compose 的 YAML 语法，以下为 **Web 服务 + PostgreSQL** 典型配置：

```yaml
# docker-compose.yml
version: '3.8'  # 必选，Compose 版本
services:
  web:  # 服务名（容器名前缀）
    image: nginx:latest  # 镜像（可替换为 Buildah 构建的自定义镜像）
    ports:
      - "8080:80"  # 端口映射（宿主机:容器）
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:Z  # 挂载配置文件（:Z 表示 SELinux 权限）
    depends_on:  # 依赖顺序（先启动 db）
      - db
    networks:
      - app-net

  db:
    image: postgres:16
    environment:  # 环境变量（数据库配置）
      POSTGRES_DB: myapp
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass123
    volumes:
      - pgdata:/var/lib/postgresql/data  # 命名卷（数据持久化）
    networks:
      - app-net

volumes:  # 定义命名卷
  pgdata:

networks:  # 定义自定义网络（服务间通信）
  app-net:
```



<br/>



## 四、核心命令

**1. 启动应用**

```bash
podman-compose up -d  # 后台运行（detached）
```

- 自动创建网络 `app-net` 和卷 `pgdata`，按依赖顺序启动容器。

**2. 查看状态**

```bash
podman-compose ps  # 列出当前项目的容器状态
# 输出示例：
#        Name                      Command               Service   Status   Ports
# -----------------------------------------------------------------------------------
# myapp_web_1   /docker-entrypoint.sh nginx -g ...   web       Running  0.0.0.0:8080->80/tcp
# myapp_db_1    docker-entrypoint.sh postgres         db        Running  5432/tcp
```

**3. 查看实时日志**

```bash
podman-compose logs -f web  # -f：实时跟踪（follow），指定服务名
```

**4. 停止并清理**

```bash
podman-compose down  # 停止容器，保留卷和网络
podman-compose down -v  # 谨慎！删除卷（数据丢失）
```

**5. 进入容器终端**

```bash
podman-compose exec web /bin/bash  # 进入 web 服务容器
```



<br/>



## 五、实战案例

Buildah 构建镜像 + Podman Compose 编排

- 步骤1：用 Buildah 构建自定义 Nginx 镜像

```bash
# 创建基于 Fedora 的工作容器
ctr=$(buildah from fedora:latest)
# 安装 Nginx 并配置
buildah run $ctr -- dnf install -y nginx
buildah run $ctr -- echo "Hello from Podman Compose!" > /usr/share/nginx/html/index.html
buildah config --port 80 --cmd "/usr/sbin/nginx -g 'daemon off;'" $ctr
# 提交为镜像
buildah commit $ctr my-nginx:latest
```

- 步骤2：编写 `docker-compose.yml`

```yaml
version: '3.8'
services:
  web:
    image: my-nginx:latest  # 使用 Buildah 构建的镜像
    ports:
      - "80:80"
    depends_on:
      - redis
  redis:
    image: redis:7-alpine
```

- 步骤3：启动并验证

```bash
podman-compose up -d
curl http://localhost  # 应返回 "Hello from Podman Compose!"
```



<br/>



## 六、注意事项

1. **与 Podman Pod 的区别**：

    - **Podman Compose**：管理 **独立服务**（如 Web、DB、缓存），每个容器独立网络。
    - **Podman Pod**：管理 **紧密耦合的服务组**（如应用 + 日志代理），共享网络和存储。

2. **无根模式配置**：

    - 普通用户需分配子 UID/GID（需 root 执行）：

        ```bash
        sudo usermod --add-subuids 100000-165535 --add-subgids 100000-165535 $USER
        ```
    
3. **网络与存储**：

    - 自定义网络（如 `app-net`）确保服务间通过服务名通信（如 `web` 可直接访问 `db:5432`）。
    - 命名卷（如 `pgdata`）持久化数据，避免容器删除后数据丢失。
    
    

<br/>



## 总结

Podman Compose 以 **无守护进程 + 无根运行** 为核心优势，通过兼容 Docker Compose 的 YAML 配置，实现多容器应用的标准化编排。结合 Buildah 可构建自定义镜像，形成“构建-编排-运行”的全流程无 Docker 依赖方案。
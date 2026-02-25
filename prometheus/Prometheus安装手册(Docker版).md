# Docker部署 Prometheus

## 一、快速启动

```bash
# 拉取官方镜像
docker pull prom/prometheus

# 启动容器（默认配置）
docker run --name prometheus -d -p 9090:9090 prom/prometheus
```

_验证：访问 `http://localhost:9090`，查看 `Status → Targets` 中 `prometheus` 状态是否为 `UP`_



<br/>



## 二、自定义配置与持久化

### 2.1 创建配置文件

1. 新建目录用于存放配置文件：`$HOME/.local/prometheus/config`
2. 创建 `prometheus.yml` 文件：

  ```yaml
  global:
    scrape_interval: 15s
  scrape_configs:
    - job_name: 'prometheus'
      static_configs:
        - targets: ['localhost:9090']
    # 方式一：静态配置（适合少量固定目标）
    - job_name: 'node-exporter'
      static_configs:
        - targets: ['host.docker.internal:9100']
    # 方式二：文件服务发现（适合动态目标，推荐）
    # - job_name: 'node-exporter'
    #   file_sd_configs:
    #     - files:
    #         - '/etc/prometheus/node-exporter.json'
    #       refresh_interval: 30s
  ```

### 2.2 创建服务发现文件（可选）

如使用文件服务发现，创建 `node-exporter.json` 文件：

```json
[
  {
    "targets": ["host.docker.internal:9100"],
    "labels": {
      "env": "local",
      "os": "linux",
      "job": "node-exporter"
    }
  },
  {
    "targets": ["192.168.1.10:9100"],
    "labels": {
      "env": "prod",
      "os": "linux",
      "job": "node-exporter"
    }
  },
  {
    "targets": ["192.168.1.20:9182"],
    "labels": {
      "env": "prod",
      "os": "windows",
      "job": "windows-exporter"
    }
  }
]
```

添加新的 node-exporter 时，只需编辑此文件，Prometheus 会自动发现，无需重启。

### 2.3 启动容器（完整配置）

```bash
docker run -d -p 9090:9090 \
  -v $HOME/.local/prometheus/data:/prometheus \
  -v $HOME/.local/prometheus/config:/etc/prometheus \
  --name prometheus prom/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/prometheus
```

- `-v $HOME/.local/prometheus/data:/prometheus`：映射宿主机目录实现持久化存储
- `-v $HOME/.local/prometheus/config:/etc/prometheus`：映射配置文件
- `--config.file`：指定配置文件路径
- `--storage.tsdb.path`：指定数据存储路径

### 2.4 验证配置生效

访问 `http://localhost:9090/targets`，检查监控目标状态是否为 `UP`（需提前安装对应的 Exporter 并运行）



<br/>



## 三、使用Docker Compose

### 3.1 创建 docker-compose.yml 文件

在项目目录下创建 `docker-compose.yml` 文件：

```yaml
version: '3'
services:
  prometheus:
    image: prom/prometheus
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - $HOME/.local/prometheus/config/prometheus.yml:/etc/prometheus/prometheus.yml
      - $HOME/.local/prometheus/data:/prometheus
    command:
      - --config.file=/etc/prometheus/prometheus.yml
      - --storage.tsdb.path=/prometheus
    restart: always
```

### 3.2 启动服务

```bash
docker-compose up -d
```

### 3.3 管理服务

- 停止：`docker-compose down`
- 查看日志：`docker-compose logs prometheus`

<br/>

## 四、Linux安装node-exporter

### 4.1 二进制包安装（推荐）

```bash
# 下载最新版本
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz

# 解压
tar xvfz node_exporter-1.8.2.linux-amd64.tar.gz

# 移动到系统目录
sudo mv node_exporter-1.8.2.linux-amd64/node_exporter /usr/local/bin/

# 验证安装
node_exporter --version
```

### 4.2 启动服务

```bash
# 直接启动（前台运行）
node_exporter

# 后台运行
nohup node_exporter > /dev/null 2>&1 &

# 或使用 systemd（推荐，开机自启）
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# 创建用户
sudo useradd -rs /bin/false node_exporter

# 启动并设置开机自启
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter
```

### 4.3 验证安装

访问 `http://localhost:9100/metrics`，若能看到指标数据，则表示安装成功。

### 4.4 其他安装方式

**包管理器安装**

```bash
# Debian/Ubuntu
sudo apt-get install prometheus-node-exporter

# CentOS/RHEL
sudo yum install node_exporter
```

**Docker 安装**

```bash
docker run -d \
  --name node-exporter \
  -p 9100:9100 \
  --restart always \
  prom/node-exporter
```

<br/>

## 五、常见问题

### 5.1 端口冲突

若 9090 端口被占用，修改 `-p 9090:9090` 为其他端口（如 `-p 9091:9090`），并同步更新配置文件中的监听地址。

### 5.2 配置错误

若容器启动后立即退出，通过 `docker logs prometheus` 查看错误日志，检查 `prometheus.yml` 语法是否正确（YAML 格式需严格对齐）。

### 5.3 无法访问主机服务

容器内无法直接访问主机服务时，使用 `host.docker.internal` 替代 `localhost`（Docker Desktop 支持该功能，Linux 需使用 `--network host` 或其他方式）。

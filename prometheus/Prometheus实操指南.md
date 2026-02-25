# Windows部署 Prometheus

## 一、环境准备

### 1.1 系统要求

- Windows 10/11 或 Windows Server 2016 及以上
- 至少 2 核 CPU、4GB 内存（生产环境建议更高配置）
- 确保 9090 端口未被占用

### 1.2 下载 Prometheus

- 访问 [Prometheus官方下载页面](https://prometheus.io/download/)

- 下载最新版本的 Windows 二进制压缩包（如 `prometheus-2.53.3.windows-amd64.zip`）



<br/>



## 二、安装服务

### 2.1 安装Prometheus

创建目录，如: `C:\Prometheus\`，将下载的压缩包解压到该目录，即可完整安装。

### 2.2 配置Prometheus

**方式一：使用默认配置（快速启动）**

Prometheus 自带默认配置，默认配置已包含监控自身的设置，可直接跳过配置步骤进入启动环节。

**方式二：自定义配置**

1. 打开 `prometheus.yml` 文件
2. 配置监控目标：

  ```yaml
global:
  scrape_interval: 15s  # 数据抓取间隔
  evaluation_interval: 15s  # 规则评估间隔

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']  # 监控Prometheus自身
      
  # 方式一：静态配置（适合少量固定目标）
  - job_name: 'windows-exporter'
    static_configs:
      - targets: ['localhost:9182']  # 监控本地Windows系统（需Windows Exporter运行在9182端口）
      
  # 方式二：文件服务发现（适合动态目标，推荐）
  # - job_name: 'windows-exporter'
  #   file_sd_configs:
  #     - files:
  #         - 'C:\Prometheus\windows-exporter.json'
  #       refresh_interval: 30s
  ```

**方式三：创建服务发现文件（可选）**

如使用文件服务发现，创建 `windows-exporter.json` 文件：

```json
[
  {
    "targets": ["localhost:9182"],
    "labels": {
      "env": "local",
      "os": "windows",
      "job": "windows-exporter"
    }
  },
  {
    "targets": ["192.168.1.10:9182"],
    "labels": {
      "env": "prod",
      "os": "windows",
      "job": "windows-exporter"
    }
  },
  {
    "targets": ["192.168.1.11:9182"],
    "labels": {
      "env": "prod",
      "os": "windows",
      "job": "windows-exporter"
    }
  }
]
```

添加新的 Windows Exporter 时，只需编辑此文件，Prometheus 会自动发现，无需重启。


### 2.3 启动Prometheus

**方式一：使用默认配置启动**

1. 双击 `prometheus.exe` 或在命令提示符中输入 `.\prometheus.exe`
2. 验证：访问 http://localhost:9090

**方式二：使用自定义配置启动**

1. 打开命令提示符（`Win + R` 输入 `cmd`）
2. 进入 Prometheus 目录：`cd C:\Prometheus\`
3. 启动服务：

   ```bash
   .\prometheus.exe --config.file=prometheus.yml
   ```

4. 验证：访问 http://localhost:9090



### 2.4 安装Exporter（可选）
>  Windows Exporter用于采集 Windows 系统的指标（如 CPU、内存、磁盘等）。

1. 访问 [Windows Exporter发布页面](https://github.com/prometheus-community/windows_exporter/releases)
2. 下载最新版本安装包（如 `windows_exporter-0.25.1-amd64.msi`）
3. 双击安装，默认监听端口 9182
4. 验证：访问 http://localhost:9182/metrics



### 2.5 设置开机自启

> 使用NSSM将 Prometheus 注册为 Windows 服务，实现开机自启。

1. 访问 [NSSM官网](https://nssm.cc/download) 下载并解压到 `C:\NSSM\`
2. 注册服务：

   ```bash
   nssm install Prometheus "C:\Prometheus\prometheus.exe" "--config.file=C:\Prometheus\prometheus.yml"
   ```

3. 启动服务：

   ```bash
   net start Prometheus
   ```

4. 在服务管理器中将 Prometheus 启动类型设置为"自动"

<br/>

## 三、查询示例

### 3.1 Prometheus 自身指标

访问 http://localhost:9090 ，在查询框中输入以下查询语句：

**1. 查询 Prometheus 自身的运行时间**

```promql
prometheus_build_info
```

说明：显示 Prometheus 版本信息，包含版本号、构建时间等元数据。

**2. 查询数据采集情况**

```promql
prometheus_sd_discovered_targets
```

说明：显示已发现的监控目标数量。

**3. 查询配置重载次数**

```promql
prometheus_config_last_reload_successful
```

说明：显示配置文件最后一次重载是否成功（1 表示成功，0 表示失败）。

**4. 查询存储操作统计**

```promql
prometheus_tsdb_storage_blocks_bytes
```

说明：显示当前数据块占用的存储空间大小（字节）。

### 3.2 Windows 系统指标

需先安装 Windows Exporter（见 2.4 节），然后在查询框中输入：

**1. 查询 CPU 使用率**

```promql
rate(windows_cpu_time_total[5m])
```

说明：计算过去 5 分钟的 CPU 使用率变化趋势，返回值范围为 0-1（乘以 100 即为百分比）。

**2. 查询内存使用情况**

```promql
windows_os_physical_memory_free_bytes
```

说明：显示当前可用的物理内存大小（字节）。

**3. 查询磁盘使用率**

```promql
windows_logical_disk_free_bytes
```

说明：显示各逻辑分区的可用空间（字节），可通过 `volume` 标签区分不同盘符。

**4. 查询网络流量**

```promql
rate(windows_net_bytes_received_total[5m])
```

说明：计算过去 5 分钟的网络接收速率（字节/秒）。

**5. 查询系统负载**

```promql
windows_system_processor_queue_length
```

说明：显示处理器队列长度，反映系统负载情况（数值越高表示负载越大）。

### 3.3 查询技巧

- **实时监控**：点击查询框右侧的 "Graph" 标签，可查看指标的历史趋势图
- **数据导出**：点击 "Table" 标签，可查看当前时间点的具体数值
- **时间范围**：在页面顶部选择时间范围，可查看不同时间段的指标变化
- **聚合查询**：使用 `sum()`、`avg()` 等函数对多个实例的指标进行聚合

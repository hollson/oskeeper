# CPU 监控系统



基于 chdb (ClickHouse Local) 的 CPU 监控系统，用于实时监控和存储 CPU 使用率数据。



## 功能特性



- 实时监控 CPU 整体使用率

- 监控各核心 CPU 使用率

- 记录系统负载信息

- 实时监控网络IO统计信息（发送/接收字节、包数、错误数、丢包数等）

- 使用 chdb 进行高效数据存储

- 支持批量数据写入

- 提供数据查询功能



## 技术栈



- Python 3.12+

- chdb (ClickHouse Local)

- psutil (系统监控)



## 安装与运行



### 1. 环境准备



```bash

# 创建虚拟环境

python3 -m venv .venv

source .venv/bin/activate



# 安装依赖

pip install --break-system-packages psutil chdb

```



### 2. 运行程序



```bash
source .venv/bin/activate
python main.py
```



## 数据存储



- 数据存储在 `./master.chdb/` 目录中

- 使用 MergeTree 引擎进行高效存储

- 支持批量写入以提高性能

- 包含两个表：

- `cpu_metrics`: 存储CPU监控数据

- `net_metrics`: 存储网络IO监控数据



## 数据库工具：

- SQLTools + ClickHouse Driver

- https://dbeaver.io/download/

- https://mirrors.nju.edu.cn/github-release/dbeaver/dbeaver/  



## 生产环境推荐



- 使用 MergeTree 引擎进行时序数据存储

- 推荐使用 Parquet 格式进行长期数据存储

- 定期备份数据库目录

- 根据数据量调整批量写入大小 (BATCH_SIZE)



## 配置项



- `COLLECT_INTERVAL`: 监控采集间隔（秒）

- `BATCH_SIZE`: 批量写入阈值

- `DB_FILE_PATH`: 数据库文件路径

- `CPU_TABLE_NAME`: CPU监控表名

- `NET_TABLE_NAME`: 网络监控表名



## 数据结构



### CPU 监控数据包含以下字段：

- `ts`: 时间戳（毫秒）

- `cpu_percent`: 整体 CPU 使用率

- `cpu_cores`: 各核心 CPU 使用率（数组）

- `load1`: 1分钟系统负载



### 网络IO监控数据包含以下字段：

- `ts`: 时间戳（毫秒）

- `bytes_sent`: 发送字节数

- `bytes_recv`: 接收字节数

- `packets_sent`: 发送包数

- `packets_recv`: 接收包数

- `errin`: 入口错误数

- `errout`: 出口错误数

- `dropin`: 入口丢包数

- `dropout`: 出口丢包数



## 常见问题



1. **权限问题**: 如果遇到 `externally-managed-environment` 错误，使用 `--break-system-packages` 参数安装

2. **数据持久化**: 程序使用 chdb.connect() 确保数据持久化存储

3. **查询性能**: MergeTree 引擎按时间戳排序，优化时序查询性能


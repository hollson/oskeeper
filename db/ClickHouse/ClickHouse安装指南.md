# ClickHouse数据库入门指南

## 一. ClickHouse介绍

[**ClickHouse**](https://clickhouse.com/docs/zh) 是一个开源的列式数据库管理系统，专为高性能实时数据分析与大规模数据查询优化设计。



**核心特点：**

- **列式存储**：高效聚合与压缩，适合分析场景，节省存储和I/O。
- **高性能查询**：秒级/亚秒级响应，向量化执行引擎充分利用CPU。
- **可扩展性强**：水平分布式架构，支持数据分片，轻松应对数据增长。
- **功能丰富**：兼容ANSI SQL，支持复杂查询，提供物化视图和多种表引擎。
- **高可靠性**：异步多副本复制，数据一致，具备自动/半自动故障恢复机制。
- **易用性好**：开源生态丰富，工具集成佳，部署简单，降低使用门槛。



**应用场景：**

- **实时分析**：广告、用户行为等实时数据仓库。
- **数据仓库**：快速查询海量历史数据。
- **监控报警**：实时显示监控数据，支持决策。
- **交互查询**：数据科学家探索分析工具。



## 二. ClickHouse安装

### 2.1 ClickHouse安装指南

ClickHouse提供了全平台 [ClickHouse安装指南](https://clickhouse.com/docs/zh/install) , 下面以`Debian/Ubuntu`为例演示：

- **配置Debian软件源**

```shell
# 安装必要的依赖包
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

# 下载ClickHouse的GPG密钥并保存到密钥环（用于验证官方软件包的合法性）
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg

# 获取系统架构信息（如amd64/arm64）
ARCH=$(dpkg --print-architecture)

# 将ClickHouse软件源添加到apt源列表
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list

# 更新软件包索引，并安装ClickHouse服务端和客户端（自动确认安装）
sudo apt-get update
```
- **安装服务端和客户端**

```shell
sudo apt-get install clickhouse-server clickhouse-client -y
```
- **启动clickhouse服务**

```shell
# 启动ClickHouse服务（使用systemd管理）
sudo service clickhouse-server start

# 1. 默认无密码登录（仅限本地测试环境）
clickhouse-client

# 2. 带密码验证登录（生产环境推荐）
# 首次运行时会自动生成默认密码，可通过sudo clickhouse-client --password输入
clickhouse-client --password
```
**安装验证**

```shell
clickhouse-client --query "SELECT version()"
```



**服务状态检查**

```bash
# Linux
sudo systemctl status clickhouse-server

# macOS（Homebrew）
brew services list | grep clickhouse
```

**端口监听确认**

```bash
netstat -tulnp | grep 9000  # 默认TCP端口
netstat -tulnp | grep 8123  # 默认HTTP端口
```



### 2.1 ClickHouse安装清单



通过官方 `deb` 包安装的 ClickHouse，核心目录遵循 Linux 标准布局，默认路径如下：

| 目录类型       | 默认路径                          | 说明                                  |
|----------------|-----------------------------------|---------------------------------------|
| 数据目录       | `/var/lib/clickhouse/`            | 核心数据存储目录，包含数据库、表数据等（默认权限归 `clickhouse` 用户） |
| 配置目录       | `/etc/clickhouse-server/`         | 主配置文件目录，核心配置文件为 `config.xml`；用户自定义配置可放在 `config.d/` 子目录（推荐通过子目录扩展，避免修改主配置） |
| 日志目录       | `/var/log/clickhouse-server/`     | 服务日志（`clickhouse-server.log`）、错误日志（`clickhouse-server.err.log`）等 |
| 临时文件目录   | `/var/lib/clickhouse/tmp/`        | 临时数据、查询中间结果存储            |
|  pid 文件目录   | `/var/run/clickhouse-server/`     | 服务进程 ID 文件（`clickhouse-server.pid`） |




**ClickHouse命令清单**

```shell
$ ll /usr/bin/|grep click
-r-xr-xr-x 1 root root 727M clickhouse*						# 主程序，其他都是命令别名或软链接
lrwxrwxrwx 1 root root   10 ch -> clickhouse*
lrwxrwxrwx 1 root root   10 chc -> clickhouse*
lrwxrwxrwx 1 root root   10 chdig -> clickhouse*
lrwxrwxrwx 1 root root   10 chl -> clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-benchmark -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-chdig -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-client -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-compressor -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-disks -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-extract-from-config -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-format -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-git-import -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-keeper -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   10 clickhouse-keeper-client -> clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-keeper-converter -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-local -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-obfuscator -> /usr/bin/clickhouse*
lrwxrwxrwx 1 root root   19 clickhouse-server -> /usr/bin/clickhouse*
```



**2. 关键目录结构**

```shell
/etc/clickhouse-server/
├── config.xml        # 主配置文件（监听地址、端口等）
├── users.xml         # 用户权限配置
└── metrika.xml       # 集群配置（如需集群部署）

/var/lib/clickhouse/  # 数据存储目录
/var/log/clickhouse-server/  # 日志目录
/usr/bin/             # 包含clickhouse-server、clickhouse-client等可执行文件
```

**3. 配置修改示例**

```xml
<!-- 修改/etc/clickhouse-server/config.xml -->
<listen_host>::</listen_host>  # 允许所有IP访问
<log>/data/clickhouse/logs/clickhouse-server.log</log>  # 自定义日志路径
```



### 2.3 自定义配置

ClickHouse 通过主配置文件 `config.xml` 或自定义配置文件（推荐）修改目录，**不建议直接修改主配置**，优先通过 `config.d/` 子目录添加自定义配置（避免升级覆盖）。

#### 操作步骤：

1. **创建自定义配置文件**（推荐方式）
   在配置扩展目录创建自定义配置（如 `custom-paths.xml`），优先级高于主配置：
   
   ```bash
   sudo vim /etc/clickhouse-server/config.d/custom-paths.xml
   ```
   
2. **配置自定义目录参数**
   在文件中添加以下内容，替换 `<自定义路径>` 为实际目录（需确保 `clickhouse` 用户有读写权限）：
   ```xml
   <yandex>
       <!-- 自定义数据目录（核心） -->
       <path>/<自定义路径>/clickhouse/data/</path>
       
       <!-- 自定义临时文件目录 -->
       <tmp_path>/<自定义路径>/clickhouse/tmp/</tmp_path>
       
       <!-- 自定义日志目录 -->
       <log>/<自定义路径>/clickhouse/logs/clickhouse-server.log</log>
       <errorlog>/<自定义路径>/clickhouse/logs/clickhouse-server.err.log</errorlog>
       
       <!-- 自定义 pid 文件路径 -->
       <pid_file>/<自定义路径>/clickhouse/run/clickhouse-server.pid</pid_file>
       
       <!-- （可选）自定义用户配置目录（默认无需修改） -->
       <users_config>/etc/clickhouse-server/users.xml</users_config>
       <users_dir>/etc/clickhouse-server/users.d/</users_dir>
   </yandex>
   ```

3. **创建目录并授权**
   手动创建自定义路径的目录，赋予 `clickhouse` 用户所有权（否则服务启动失败）：
   ```bash
   # 示例：假设自定义路径为 /data/clickhouse
   sudo mkdir -p /data/clickhouse/{data,tmp,logs,run}
   sudo chown -R clickhouse:clickhouse /data/clickhouse/
   sudo chmod -R 755 /data/clickhouse/
   ```

4. **重启 ClickHouse 生效**
   ```bash
   sudo service clickhouse-server restart
   # 验证服务状态
   sudo service clickhouse-server status
   ```

#### 关键说明：
- 配置优先级：`/etc/clickhouse-server/config.d/*.xml` > `/etc/clickhouse-server/config.xml`，新增配置会覆盖主配置的默认值。
- 目录权限必须正确：所有自定义目录的所有者和组必须是 `clickhouse`（deb 包安装时自动创建的系统用户），否则服务无法读写数据/日志。
- 若需修改配置目录本身（默认 `/etc/clickhouse-server/`）：需在启动命令中通过 `--config-file` 指定自定义配置文件路径（如 `sudo clickhouse-server --config-file /<自定义配置目录>/config.xml`），但不推荐（破坏默认规范）。



三、验证自定义目录是否生效

1. 查看服务日志，确认目录加载成功：
   ```bash
   grep "Path:" /var/log/clickhouse-server/clickhouse-server.log  # 旧日志路径（若已修改，查看新日志路径）
   # 或直接查看新日志目录下的日志，确认无权限错误
   ```

2. 通过客户端查询系统表验证数据目录：
   ```bash
   clickhouse-client  # 若设密码，加 --password
   ```
   执行 SQL：
   ```sql
   SELECT * FROM system.settings WHERE name LIKE '%path%';
   ```
   结果中 `path` 字段应显示自定义的目录路径。



<br/>




## 四. ClickHouseLocal

**1. 安装方式**

- **Linux/macOS通用**：通过ClickHouse客户端包自动安装

    ```bash
    # 安装clickhouse-client后即可使用
    clickhouse-local --query "SELECT * FROM table_name"
    ```

- **独立下载**（如需单独使用）

    ```bash
    # 下载预编译二进制包（示例）
    wget https://builds.clickhouse.com/master/amd64/clickhouse
    chmod +x clickhouse
    ./clickhouse local --help
    ```

**2. 核心功能演示**

```bash
# 示例1：查询CSV文件
echo -e "1,Alice\n2,Bob" > data.csv
clickhouse-local --query "SELECT * FROM file('data.csv', 'CSV', 'id UInt32, name String')"

# 示例2：生成测试数据并查询
clickhouse-local --query "
    CREATE TABLE test (date Date, id UInt32) ENGINE = Memory;
    INSERT INTO test SELECT toDate('2025-01-01') + number, number FROM numbers(10);
    SELECT * FROM test ORDER BY id
"
```


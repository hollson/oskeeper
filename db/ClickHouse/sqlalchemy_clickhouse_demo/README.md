# SQLAlchemy 与 chdb 文件数据库演示项目

本项目演示了如何使用 chdb（ClickHouse 的本地嵌入式版本）作为文件数据库，提供类似 SQLite 的体验，同时保持 SQLAlchemy 风格的代码结构。数据持久化到本地文件，适合时间序列数据处理和临时数据分析。

## 系统要求和先决条件

在运行项目之前，请确保系统已安装以下组件：

- Python 3.8+
- Python venv 模块 (Debian/Ubuntu: `sudo apt install python3-venv`)
- pip (Python 包管理器)

### VMware 共享文件夹用户特别注意

如果您在 VMware 共享文件夹中运行此项目（如 `/mnt/hgfs/`），请先安装 `python3-venv` 包：

```bash
sudo apt install python3-venv
```

这是因为 VMware 共享文件夹不支持符号链接，而 Python 虚拟环境需要这些功能。

## 项目结构

```
sqlalchemy_clickhouse_demo/
├── config.py                 # chdb 文件数据库配置
├── requirements.txt          # 项目依赖
├── pyproject.toml           # 项目配置（uv风格）
├── Makefile                 # 项目构建配置（支持uv）
├── main.py                  # 主应用程序入口
├── test_functionality.py    # 功能验证脚本
├── __init__.py              # 包初始化
├── models/                  # 数据库模型
│   ├── __init__.py
│   ├── base.py              # 基础模型类
│   ├── user.py              # 用户模型
│   ├── product.py           # 产品模型
│   ├── order.py             # 订单模型
│   └── order_item.py        # 订单项模型
├── utils/                   # 工具函数
│   └── database.py          # 数据库连接（适配 chdb 文件数据库）
└── examples/                # 示例操作（展示 SQLAlchemy 模式）
    ├── crud_operations.py   # CRUD 操作示例
    ├── query_operations.py  # 查询操作示例
    └── batch_operations.py  # 批量和事务操作示例
```

## 功能特性

1. **chdb 文件数据库**:
   - 数据持久化到本地文件 (`./data/master.chdb`)
   - 类似 SQLite 的使用体验
   - 支持完整的 SQL 查询功能
   - 特别适合时间序列数据处理

2. **SQLAlchemy 模式兼容**:
   - 展示 CRUD 操作模式
   - 展示查询操作模式
   - 展示批量操作模式
   - 提供模型定义模板

3. **开发友好**:
   - 支持 uv 依赖管理
   - 提供完整的 Makefile 命令
   - 自动创建数据目录

## 安装

1. 安装所需依赖 (使用 uv 推荐):
```bash
# 使用 uv 安装 (推荐)
make setup

# 或使用 pip 安装
pip install -r requirements.txt
```

2. 安装 chdb (如果尚未安装):
```bash
pip install chdb
# 或使用 uv
uv pip install chdb
```

注意：chdb 仅支持 macOS 和 Linux 平台。

## 使用方法

运行演示程序以查看 chdb 文件数据库功能:

```bash
# 使用 Makefile 运行 (推荐)
make run

# 或直接运行
python main.py
```

或运行单个示例:

```bash
# 运行 CRUD 操作示例
make crud

# 运行查询操作示例
make query

# 运行批量操作示例
make batch
```

## chdb 文件数据库操作

chdb 提供了类似 SQLite 的本地 ClickHouse 体验，数据持久化到文件系统：

```bash
# 运行功能验证
python test_functionality.py

# 或使用 chdb 直接操作
python chdb_demo.py
```

## 项目配置

项目使用以下配置:
- 数据库文件: `./data/master.chdb`
- 数据目录: `./data/`
- 临时目录: `./data/temp/`

## 注意事项

- 本项目使用 chdb 作为文件数据库，提供持久化存储
- 数据存储在 `./data/` 目录下，支持跨会话持久化
- chdb 仅支持 macOS 和 Linux 平台
- 适合开发、测试和临时数据处理任务
- 支持 uv 依赖管理工具
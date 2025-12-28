# SQLAlchemy 与 ClickHouse Local 模式演示项目

本项目演示了如何为 ClickHouse Local 模式准备 SQLAlchemy 风格的代码结构。ClickHouse Local 是一个无需服务器的模式，直接使用本地文件进行操作，类似于 SQLite。

## 项目结构

```
sqlalchemy_clickhouse_demo/
├── config.py                 # Local 模式数据库配置
├── requirements.txt          # 项目依赖
├── main.py                   # 主应用程序入口
├── __init__.py               # 包初始化
├── models/                   # 数据库模型（供参考）
│   ├── __init__.py
│   ├── base.py               # 基础模型类
│   ├── user.py               # 用户模型
│   ├── product.py            # 产品模型
│   ├── order.py              # 订单模型
│   └── order_item.py         # 订单项模型
├── utils/                    # 工具函数
│   └── database.py           # 数据库连接（适配 Local 模式）
└── examples/                 # 示例操作（展示 SQLAlchemy 模式）
    ├── crud_operations.py    # CRUD 操作示例
    ├── query_operations.py   # 查询操作示例
    └── batch_operations.py   # 批量和事务操作示例
```

## 功能特性

1. **SQLAlchemy 模式演示**:
   - 展示 CRUD 操作模式
   - 展示查询操作模式
   - 展示批量操作模式
   - 展示事务处理模式

2. **ClickHouse Local 模式适配**:
   - 无需服务器，使用本地文件
   - 代码结构适配 Local 模式
   - 提供实际操作示例

3. **开发准备**:
   - 模型定义兼容 ClickHouse
   - 代码结构支持服务器和本地模式
   - 为实际 Local 操作提供模板

## 安装

1. 安装所需依赖:
```bash
pip install -r requirements.txt
```

2. 安装 ClickHouse 以使用 Local 模式:
   - 下载安装: 请参考官方安装指南: https://clickhouse.com/docs/en/getting-started/install/
   - 确保 `clickhouse-local` 命令在系统 PATH 中

## 使用方法

运行演示程序以查看 SQLAlchemy 模式:

```bash
python main.py
```

或运行单个示例:

```bash
# 运行 CRUD 操作示例
python -m examples.crud_operations

# 运行查询操作示例
python -m examples.query_operations

# 运行批量操作示例
python -m examples.batch_operations
```

## ClickHouse Local 模式操作

真正的 ClickHouse Local 模式使用命令行工具:

```bash
# 创建内存表
clickhouse-local --query="CREATE TABLE users (id UInt32, name String) ENGINE=Memory"

# 插入数据
clickhouse-local --query="INSERT INTO users VALUES (1, 'John')"

# 查询数据
clickhouse-local --query="SELECT * FROM users"

# 使用本地数据文件
clickhouse-local --path=/path/to/data --structure="col1 String" --input-file=data.csv
```

## 注意事项

- 本项目展示 SQLAlchemy 风格的代码结构，用于 ClickHouse Local 模式
- 实际的 Local 操作需要使用 `clickhouse-local` 命令
- ClickHouse Local 模式无需服务器，直接操作本地文件
- 适合开发、测试和临时数据处理任务
# ClickHouse MergeTree 与 Parquet 存储方式使用指南

## 概述

本项目演示了 ClickHouse 中两种重要的存储方式：MergeTree 和 Parquet。MergeTree 是 ClickHouse 的原生表引擎，专为 OLAP 工作负载设计；Parquet 是一种高效的列式存储格式，用于数据交换和归档。

## 文件结构

- `mergetree_demo.py` - MergeTree 表引擎操作演示（主版本）
- `mergetree_demo_dev.py` - MergeTree 表引擎操作演示（开发版，包含ClickHouse连接）
- `mergetree_demo_prod.py` - MergeTree 表引擎操作演示（生产版，轻量级无连接）
- `parquet_demo.py` - Parquet 格式操作演示  
- `README.md` - 本说明文档

## MergeTree vs Parquet

### MergeTree 特点

- **适用场景**：
  - 实时数据分析和查询
  - 高频数据插入和更新
  - 复杂的聚合查询
  - 在线分析处理 (OLAP)

- **优势**：
  - 实时查询能力
  - 高效的数据插入
  - 高级功能（分区、索引等）
  - 高并发查询性能

- **最佳实践**：
  - 合理设计分区键，避免过多小分区
  - 选择合适的 ORDER BY 键以优化查询性能
  - 定期执行 OPTIMIZE TABLE 以合并分区
  - 使用 ReplicatedMergeTree 实现高可用

### Parquet 特点

- **适用场景**：
  - 数据仓库和 ETL 流程
  - 批量数据导入/导出
  - 与其他系统进行数据交换
  - 静态数据分析和报告

- **优势**：
  - 高压缩率
  - 列式存储
  - 跨平台兼容
  - 适合大数据处理

- **最佳实践**：
  - 使用适当的行组大小以优化读取性能
  - 选择合适的压缩算法 (Snappy, GZIP等)
  - 在写入时按列值排序以提高压缩率

## 操作演示

### MergeTree 操作

#### 主版本运行：

```bash
python mergetree_demo.py
```

#### 开发版本运行（包含ClickHouse连接）：

```bash
python mergetree_demo_dev.py
```

#### 生产版本运行（轻量级，无ClickHouse连接）：

```bash
python mergetree_demo_prod.py
```

演示内容包括：
1. 创建基础 MergeTree 表
2. 数据插入和查询
3. 分区查询
4. 聚合查询
5. SummingMergeTree（自动聚合）
6. ReplacingMergeTree（去重功能）
7. 分区管理和表信息查询

#### 版本说明：
- **主版本** (`mergetree_demo.py`) - 包含完整的ClickHouse连接和操作，适合一般演示
- **开发版** (`mergetree_demo_dev.py`) - 包含完整的ClickHouse连接功能，适合开发和测试环境
- **生产版** (`mergetree_demo_prod.py`) - 轻量级版本，不包含实际数据库连接，适合生产环境部署，追求极致轻量级

### Parquet 操作

运行 Parquet 演示：

```bash
python parquet_demo.py
```

演示内容包括：
1. 创建和读取 Parquet 文件
2. 从 Parquet 文件导入数据到 ClickHouse
3. 将 ClickHouse 数据导出为 Parquet 格式
4. 批量处理多个 Parquet 文件
5. 不同压缩算法的使用

### 推荐架构

建议采用分层架构：

1. **实时层**：使用 MergeTree 处理实时数据和查询
2. **归档层**：使用 Parquet 存储历史数据和备份
3. **ETL层**：在两层之间建立数据流转管道
4. **监控层**：建立全面的性能监控体系

### 选择指南

- **选择 MergeTree 如果**：
  - 需要实时数据插入和查询
  - 有复杂的聚合查询需求
  - 需要高级的分区和索引功能
  - 要求高并发查询性能

- **选择 Parquet 如果**：
  - 主要用于批处理和数据分析
  - 需要与其他大数据生态系统集成
  - 重视存储压缩率
  - 进行数据归档和备份

## 依赖安装

```bash
pip install clickhouse-connect pandas pyarrow
```

## 注意事项

1. 确保 ClickHouse 服务正在运行（仅开发版需要）
2. 演示脚本会创建临时表和文件，运行后会自动清理
3. 某些 Parquet 操作可能需要特定的 ClickHouse 配置
4. 生产环境使用时需要考虑数据安全和权限管理
5. 生产版 (`mergetree_demo_prod.py`) 不需要ClickHouse服务，仅展示SQL语句结构，适合轻量级部署
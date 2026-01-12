# Hello DuckDB - DuckDB完整使用示例项目

这是一个完整的DuckDB使用示例项目，基于Duckdb入门指南创建，演示了DuckDB的核心功能和最佳实践。



<br/>



## 项目结构

```
hello_duckdb/
├── main.py                 # 主程序，基本连接和数据操作
├── data_processor.py       # 数据处理模块，文件加载和批量操作
├── query_analyzer.py       # 查询分析模块，复杂查询和聚合分析
├── crud_demo.py            # CRUD操作演示，事务处理
├── performance_test.py     # 性能测试模块，性能对比
├── perf_monitor.py         # 性能监控模块，多连接使用示例
├── run_all.py              # 项目入口点，运行所有演示
├── requirements.txt        # 项目依赖
├── data/                   # 数据文件目录
│   └── sample_sales.csv    # 示例数据文件
└── output/                 # 输出文件目录
```



<br/>



## 功能特性

1. **基本操作**：数据库连接、表创建、数据插入
2. **数据处理**：从CSV/Parquet文件加载数据、批量插入
3. **查询分析**：复杂聚合查询、连接查询、时间序列分析
4. **CRUD操作**：完整的增删改查功能，带事务支持
5. **性能测试**：大数据量处理性能评估，与Pandas对比
6. **多连接应用**：服务器性能监控场景，展示多连接并发使用模式



<br/>



## 安装依赖

```bash
pip install -r requirements.txt
```

## 运行演示

### 运行单个模块
```bash
# 基本操作演示
python main.py

# 数据处理演示
python data_processor.py

# 查询分析演示
python query_analyzer.py

# CRUD操作演示
python crud_demo.py

# 性能测试演示
python performance_test.py

# 性能监控演示（需先安装psutil和schedule）
python perf_monitor.py
```



<br/>



### 运行完整演示

```bash
python run_all.py
```



<br/>



## 项目特点

- **零依赖部署**：DuckDB单文件数据库，无需额外服务
- **高性能**：列式存储和向量化执行引擎
- **多格式支持**：直接读取CSV、Parquet等文件
- **ACID事务**：支持事务处理确保数据一致性
- **Python集成**：与Pandas、PyArrow等生态无缝集成



<br/>



## 使用场景

- 本地数据分析
- ETL数据处理
- 数据科学工作流
- 大数据量聚合分析
- 快速原型开发
- 服务器性能监控
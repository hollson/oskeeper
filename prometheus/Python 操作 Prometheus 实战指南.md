# Python 操作 Prometheus 实战指南（全场景示例）
## 文档说明
你需要的是一份**以实操为核心**、涵盖 Prometheus 常用操作的 Python 示例文档，本文档基于工业界常用的 `prometheus-api-client` 库，所有代码均可直接复制运行，覆盖「数据查询、元数据管理、告警操作、数据导出」等核心场景，同时附带运行验证和问题排查方法。

### 前置准备（必做）
1. **安装依赖**：
```bash
# 核心依赖：Prometheus 客户端
pip install prometheus-api-client
# 辅助依赖：数据处理+可视化（实操必备）
pip install pandas matplotlib numpy
```
2. **环境验证**：确保你的 Python 环境能访问 Prometheus 服务（替换示例中的 `PROMETHEUS_URL` 为实际地址，如 `http://192.168.1.100:9090`）。

---

## 一、基础配置与连接验证
### 核心目标
初始化 Prometheus 客户端，验证连接有效性（实操第一步，避免后续操作踩坑）。

### 实操代码
```python
from prometheus_api_client import PrometheusConnect
from prometheus_api_client.utils import parse_datetime
import pandas as pd
import matplotlib.pyplot as plt

# ===================== 核心配置（替换为你的实际信息）=====================
PROMETHEUS_URL = "http://localhost:9090"  # Prometheus 服务地址
# 如有认证（如 Basic Auth），添加 headers（示例：用户名admin，密码123456）
HEADERS = {
    # "Authorization": "Basic YWRtaW46MTIzNDU2"
}
# =======================================================================

# 初始化客户端
def init_prom_client():
    """初始化并验证 Prometheus 连接"""
    try:
        prom = PrometheusConnect(
            url=PROMETHEUS_URL,
            headers=HEADERS,
            disable_ssl=True  # http 用 True，https 用 False
        )
        # 验证连接
        if prom.check_prometheus_connection():
            print("✅ Prometheus 连接成功！")
            return prom
        else:
            print("❌ Prometheus 连接失败：服务不可达")
            return None
    except Exception as e:
        print(f"❌ 初始化失败：{str(e)}")
        return None

# 执行初始化（后续所有操作基于此客户端）
prom_client = init_prom_client()
```

### 运行验证
- 成功：控制台输出 `✅ Prometheus 连接成功！`
- 失败：根据提示排查（如地址错误、端口未开放、认证失败）。

---

## 二、核心操作实战（覆盖90%常用场景）
### 场景1：即时查询（获取指标最新值）
#### 核心目标
快速获取某个指标的**实时值**（如当前CPU使用率、内存使用率），适用于监控大盘、状态检查。

#### 实操代码
```python
def query_instant_metric(prom):
    """
    即时查询示例：获取节点CPU使用率（按实例分组）
    """
    if not prom:
        return
    
    # 1. 定义 PromQL 查询语句（可替换为你的指标）
    # 说明：irate计算5分钟内CPU非空闲使用率，avg按instance分组
    promql = 'avg(irate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance)'
    
    # 2. 执行查询
    result = prom.custom_query(query=promql)
    
    # 3. 解析结果（实操重点：格式化输出）
    print("\n=== 即时查询结果（CPU使用率）===")
    if not result:
        print("⚠️  未查询到数据（检查指标名/实例是否存在）")
        return
    
    for item in result:
        instance = item["metric"].get("instance", "未知实例")
        value = float(item["value"][1])  # value格式：[时间戳, 数值]
        cpu_usage = round(value * 100, 2)  # 转换为百分比
        print(f"实例 {instance}: CPU使用率 {cpu_usage}%")

# 执行查询
query_instant_metric(prom_client)
```

#### 运行效果示例
```
=== 即时查询结果（CPU使用率）===
实例 192.168.1.101:9100: CPU使用率 15.67%
实例 192.168.1.102:9100: CPU使用率 8.32%
```

### 场景2：范围查询（获取时间段指标数据）
#### 核心目标
获取指定时间段内的指标趋势数据（如过去1小时的内存使用率），适用于趋势分析、故障回溯。

#### 实操代码
```python
def query_range_metric(prom):
    """
    范围查询示例：获取过去1小时的内存使用率，输出+可视化
    """
    if not prom:
        return
    
    # 1. 定义查询参数（实操重点：时间范围+采样间隔）
    promql = 'node_memory_usage_percentage{job="node_exporter"}'  # 内存使用率指标
    start_time = parse_datetime("1h")  # 开始时间：1小时前
    end_time = parse_datetime("now")   # 结束时间：当前
    step = "1m"                        # 采样间隔：1分钟（根据时间范围调整，避免数据过多）
    
    # 2. 执行范围查询
    try:
        result = prom.custom_query_range(
            query=promql,
            start_time=start_time,
            end_time=end_time,
            step=step
        )
    except Exception as e:
        print(f"❌ 范围查询失败：{e}（检查PromQL语法/时间范围）")
        return
    
    # 3. 解析为DataFrame（实操核心：便于数据处理）
    metric_dfs = []
    for metric in result:
        # 提取实例标签
        instance = metric["metric"].get("instance", "未知实例")
        # 转换数据为DataFrame
        df = pd.DataFrame(
            metric["values"],
            columns=["timestamp", "value"]
        )
        # 类型转换（时间戳转datetime，值转浮点型）
        df["timestamp"] = pd.to_datetime(df["timestamp"], unit="s")
        df["value"] = df["value"].astype(float)
        df["instance"] = instance
        metric_dfs.append(df)
    
    if not metric_dfs:
        print("⚠️  未查询到范围数据")
        return
    
    # 4. 合并数据并输出
    combined_df = pd.concat(metric_dfs)
    print("\n=== 范围查询结果（前5行）===")
    print(combined_df[["timestamp", "instance", "value"]].head())
    
    # 5. 可视化（实操扩展：直观展示趋势）
    plt.rcParams["font.sans-serif"] = ["SimHei"]  # 解决中文乱码
    plt.figure(figsize=(10, 5))
    
    for instance, group in combined_df.groupby("instance"):
        plt.plot(
            group["timestamp"],
            group["value"],
            label=f"实例 {instance}",
            linewidth=1.5
        )
    
    plt.title("节点内存使用率趋势（过去1小时）")
    plt.xlabel("时间")
    plt.ylabel("内存使用率（%）")
    plt.legend()
    plt.grid(alpha=0.3)
    plt.xticks(rotation=45)
    plt.tight_layout()
    plt.show()

# 执行范围查询
query_range_metric(prom_client)
```

#### 运行效果
- 控制台输出数据前5行；
- 自动弹出折线图，展示各实例内存使用率趋势。

### 场景3：获取指标元数据（盘点所有指标）
#### 核心目标
查看Prometheus中所有可用指标、标签，适用于指标盘点、查询调试。

#### 实操代码
```python
def get_metric_metadata(prom):
    """
    获取指标元数据：所有指标名称 + 指定指标标签
    """
    if not prom:
        return
    
    # 1. 获取所有指标名称
    all_metrics = prom.all_metrics()
    print(f"\n=== 所有指标（共{len(all_metrics)}个）===")
    print("前10个指标：", all_metrics[:10])
    
    # 2. 获取指定指标的元数据（标签信息）
    target_metric = "node_cpu_seconds_total"
    metadata = prom.get_metadata(metric_name=target_metric)
    print(f"\n=== 指标 {target_metric} 标签信息 ===")
    if metadata:
        # 提取唯一标签组合
        label_sets = set()
        for item in metadata:
            labels = str(item["metric"])
            label_sets.add(labels)
        for label in label_sets:
            print(label)
    else:
        print("⚠️  未获取到该指标元数据")

# 执行元数据查询
get_metric_metadata(prom_client)
```

### 场景4：管理告警规则（查看/创建/删除）
#### 核心目标
操作Prometheus告警规则，适用于自动化告警配置。

#### 实操代码
```python
def manage_alert_rules(prom):
    """
    告警规则管理：查看所有规则 + 创建自定义规则（示例）
    """
    if not prom:
        return
    
    # 1. 获取所有告警规则
    alert_rules = prom.get_alert_rules()
    rule_groups = alert_rules.get("groups", [])
    print(f"\n=== 告警规则（共{len(rule_groups)}个规则组）===")
    for group in rule_groups:
        print(f"规则组名称：{group['name']}")
        for rule in group.get("rules", []):
            print(f"  告警名称：{rule['alert']}，表达式：{rule['expr']}")
    
    # 2. 创建告警规则（注意：需Prometheus开启规则写入权限）
    new_rule_group = {
        "name": "custom_node_alerts",
        "rules": [
            {
                "alert": "HighCPUUsage",
                "expr": 'avg(irate(node_cpu_seconds_total{mode!="idle"}[5m])) by (instance) > 0.8',
                "for": "5m",
                "labels": {
                    "severity": "warning",
                    "env": "production"
                },
                "annotations": {
                    "summary": "实例 {{ $labels.instance }} CPU使用率过高",
                    "description": "CPU使用率持续5分钟超过80%（当前值：{{ $value | humanizePercentage }}）"
                }
            }
        ]
    }
    
    # 写入规则（需替换为实际规则文件路径，或使用API写入）
    # 注意：不同Prometheus部署方式（如K8s/单机）写入方式不同，此处为通用示例
    try:
        # 方式1：通过API写入（部分部署禁用，需确认）
        # prom.create_rule_group(rule_group=new_rule_group, rule_group_name="custom_node_alerts")
        # 方式2：写入规则文件（推荐实操方式）
        import yaml
        with open("custom_alerts.yml", "w", encoding="utf-8") as f:
            yaml.dump([new_rule_group], f, allow_unicode=True, sort_keys=False)
        print("\n✅ 告警规则已写入文件 custom_alerts.yml（需手动加载到Prometheus）")
    except Exception as e:
        print(f"❌ 创建告警规则失败：{e}")

# 执行告警规则管理
manage_alert_rules(prom_client)
```

### 场景5：数据导出（保存查询结果到文件）
#### 核心目标
将Prometheus查询结果导出为CSV/Excel，适用于数据归档、报表生成。

#### 实操代码
```python
def export_metric_data(prom):
    """
    导出指标数据：将范围查询结果保存为CSV文件
    """
    if not prom:
        return
    
    # 1. 执行范围查询（以磁盘使用率为例）
    promql = 'node_filesystem_usage_percentage{mountpoint="/"}'
    start_time = parse_datetime("24h")
    end_time = parse_datetime("now")
    step = "5m"
    
    result = prom.custom_query_range(
        query=promql,
        start_time=start_time,
        end_time=end_time,
        step=step
    )
    
    # 2. 解析数据
    metric_dfs = []
    for metric in result:
        instance = metric["metric"].get("instance", "未知实例")
        df = pd.DataFrame(metric["values"], columns=["timestamp", "usage"])
        df["timestamp"] = pd.to_datetime(df["timestamp"], unit="s")
        df["usage"] = df["usage"].astype(float)
        df["instance"] = instance
        metric_dfs.append(df)
    
    if not metric_dfs:
        print("⚠️  无数据可导出")
        return
    
    # 3. 导出为CSV
    combined_df = pd.concat(metric_dfs)
    export_path = "disk_usage_24h.csv"
    combined_df.to_csv(export_path, index=False, encoding="utf-8")
    print(f"\n✅ 数据已导出到：{export_path}")
    print(f"📊 导出数据量：{len(combined_df)} 行")

# 执行数据导出
export_metric_data(prom_client)
```

---

## 三、常见问题与排查（实操避坑）
1. **连接失败**：检查Prometheus地址是否正确、端口是否开放、防火墙是否放行；
2. **查询无数据**：确认PromQL语法正确、指标名称/标签匹配、时间范围有数据；
3. **认证失败**：核对Basic Auth的用户名密码，或确认是否需要Bearer Token；
4. **可视化中文乱码**：确保matplotlib已配置中文字体（示例中已包含）。

---

### 总结
1. **核心依赖**：`prometheus-api-client` 是Python操作Prometheus的首选库，覆盖所有常用操作；
2. **核心操作**：即时查询（查实时值）、范围查询（查趋势）、元数据查询（查指标列表）、告警管理（配规则）、数据导出（存文件）是最常用的5个场景；
3. **实操要点**：所有操作需先验证连接，PromQL语法是核心（需根据实际指标调整），数据解析优先用DataFrame便于处理。

这份文档所有示例均可直接运行，你只需替换 `PROMETHEUS_URL` 和对应的PromQL语句，即可适配你的实际场景。
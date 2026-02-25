# Prometheus 常用实操手册（精简版）

## 一、基础启动操作

1. **查看版本**：prometheus.exe --version（验证安装）

2. **默认启动**：prometheus.exe（用默认配置，监听9090端口）

3. **指定配置启动**：prometheus.exe --config.file="自定义路径/prometheus.yml"（生产常用）

## 二、核心配置操作

1. **配置自动重载**：prometheus.exe --config.file="prometheus.yml" --config.auto-reload-interval=60s（无需重启加载新配置）

2. **自定义监听地址/端口**：prometheus.exe --web.listen-address=IP:端口（解决端口冲突、安全限制）

## 三、数据存储操作

1. **指定数据存储路径**：prometheus.exe --storage.tsdb.path="自定义路径"（便于数据管理）

2. **临时设置数据保留时间**：prometheus.exe --storage.tsdb.retention.time=30d（默认15天，临时调试用）

## 四、运维与优化操作

1. **启用HTTP管控接口**：prometheus.exe --web.enable-lifecycle（支持热重载、优雅关闭）
        

    - 热重载配置：curl -X POST http://localhost:9090/-/reload

    - 关闭服务：curl -X POST http://localhost:9090/-/quit

2. **调整日志**：
        

    - 修改级别：prometheus.exe --log.level=debug/warn/error

    - 修改格式：prometheus.exe --log.format=json（便于日志采集）

3. **Agent模式运行（轻量）**：prometheus.exe --agent --storage.agent.path="自定义路径"

4. **优化查询性能**：prometheus.exe --query.timeout=5m --query.max-samples=100000000（避免慢查询、内存溢出）

## 五、promtool 常用实操（工具命令）

1. **查看版本**：promtool.exe --version（验证工具安装）

2. **检查配置文件**：promtool.exe check config 配置文件路径（验证prometheus.yml有效性）

3. **检查web配置**：promtool.exe check web-config web配置文件路径（验证web配置合法性）

4. **检查规则文件**：promtool.exe check rules 规则文件路径（验证告警/记录规则有效性）

5. **检查Prometheus健康状态**：promtool.exe check healthy（检测服务是否健康）

6. **检查Prometheus就绪状态**：promtool.exe check ready（检测服务是否就绪可提供服务）

7. **校验指标格式**：cat 指标文件.prom | promtool.exe check metrics（校验指标格式正确性）

8. **执行即时查询**：promtool.exe query instant http://IP:9090 "PromQL查询语句"（快速执行单条即时查询）

9. **格式化PromQL**：promtool.exe promql format "PromQL查询语句"（美化查询语句，提升可读性）

10. **查看TSDB块**：promtool.exe tsdb list TSDB数据路径（查看数据存储块信息）
> （注：文档部分内容可能由 AI 生成）
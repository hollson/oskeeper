"""
服务器性能指标采集与查询示例
展示DuckDB在多连接环境下的使用方式
"""
import duckdb
import threading
import time
import psutil
import schedule
import pandas as pd
from datetime import datetime


class PerformanceMonitor:
    def __init__(self, db_path="perf_monitor.duckdb"):
        self.db_path = db_path
        self.setup_database()
    
    def setup_database(self):
        """初始化数据库表结构"""
        conn = duckdb.connect(self.db_path)
        conn.execute("""
            CREATE TABLE IF NOT EXISTS system_metrics (
                timestamp TIMESTAMP,
                cpu_percent FLOAT,
                memory_percent FLOAT,
                disk_percent FLOAT,
                network_bytes_sent BIGINT,
                network_bytes_recv BIGINT
            )
        """)
        conn.close()
    
    def collect_metrics(self):
        """采集系统性能指标"""
        timestamp = datetime.now()
        cpu_percent = psutil.cpu_percent(interval=1)
        memory_percent = psutil.virtual_memory().percent
        disk_percent = psutil.disk_usage('/').percent
        network_io = psutil.net_io_counters()
        
        # 使用新的连接写入数据
        conn = duckdb.connect(self.db_path)
        conn.execute("""
            INSERT INTO system_metrics 
            VALUES (?, ?, ?, ?, ?, ?)
        """, [
            timestamp,
            cpu_percent,
            memory_percent,
            disk_percent,
            network_io.bytes_sent,
            network_io.bytes_recv
        ])
        conn.close()
        print(f"指标已采集: {timestamp}, CPU: {cpu_percent}%")
    
    def run_collector(self):
        """运行指标采集器（周期性）"""
        print("开始运行性能指标采集器...")
        # 每5秒采集一次
        schedule.every(5).seconds.do(self.collect_metrics)
        
        while True:
            schedule.run_pending()
            time.sleep(1)


class QueryAnalyzer:
    def __init__(self, db_path="perf_monitor.duckdb"):
        self.db_path = db_path
    
    def get_recent_metrics(self, limit=10):
        """获取最近的指标数据"""
        # 使用独立的连接进行查询
        conn = duckdb.connect(self.db_path)
        result = conn.execute("""
            SELECT * FROM system_metrics 
            ORDER BY timestamp DESC 
            LIMIT ?
        """, [limit]).df()
        conn.close()
        return result
    
    def get_cpu_avg(self, hours=1):
        """获取指定时间范围内的CPU平均使用率"""
        conn = duckdb.connect(self.db_path)
        result = conn.execute("""
            SELECT AVG(cpu_percent) as avg_cpu
            FROM system_metrics 
            WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '{}' HOUR
        """.format(hours)).fetchone()[0]
        conn.close()
        return result if result is not None else 0.0
    
    def get_peak_memory(self, hours=1):
        """获取指定时间范围内的内存峰值使用率"""
        conn = duckdb.connect(self.db_path)
        result = conn.execute("""
            SELECT MAX(memory_percent) as peak_memory
            FROM system_metrics 
            WHERE timestamp >= CURRENT_TIMESTAMP - INTERVAL '{}' HOUR
        """.format(hours)).fetchone()[0]
        conn.close()
        return result if result is not None else 0.0
    
    def run_analysis(self):
        """运行分析查询"""
        print("=== 系统性能分析 ===")
        
        # 获取最近数据
        recent_data = self.get_recent_metrics(5)
        print("最近5条数据:")
        if recent_data.empty:
            print("暂无数据")
        else:
            print(recent_data)
        
        # 获取统计信息
        avg_cpu = self.get_cpu_avg(1)
        peak_memory = self.get_peak_memory(1)
        
        print(f"\n过去1小时平均CPU使用率: {avg_cpu:.2f}%")
        print(f"过去1小时峰值内存使用率: {peak_memory:.2f}%")


def main():
    # 初始化性能监控器
    monitor = PerformanceMonitor()
    analyzer = QueryAnalyzer()
    
    # 在一个线程中运行采集器
    collector_thread = threading.Thread(target=monitor.run_collector, daemon=True)
    collector_thread.start()
    
    # 在主线程中定期运行分析
    print("启动分析查询，按 Ctrl+C 退出...")
    try:
        while True:
            analyzer.run_analysis()
            print("-" * 50)
            time.sleep(15)  # 每15秒分析一次
    except KeyboardInterrupt:
        print("\n程序已停止")


if __name__ == "__main__":
    main()
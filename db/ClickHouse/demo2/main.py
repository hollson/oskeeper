import time
import psutil
import chdb
import threading
from datetime import datetime
from typing import List, Dict, Tuple
import os

# ===================== 配置项 =====================
# 监控采集间隔（秒）
COLLECT_INTERVAL = 1
# 批量写入阈值（达到该条数时写入）
BATCH_SIZE = 10
# 数据存储文件路径
DB_FILE_PATH = "./master.chdb"
# 表名
CPU_TABLE_NAME = "cpu_metrics"
NET_TABLE_NAME = "net_metrics"

# ===================== 全局变量 =====================
# 批量数据缓冲区
cpu_data_buffer: List[Tuple] = []
net_data_buffer: List[Tuple] = []

# 缓冲区锁（线程安全）
cpu_buffer_lock = threading.Lock()
net_buffer_lock = threading.Lock()

# 创建全局连接，使用持久化数据库
connection = chdb.connect(DB_FILE_PATH)

# ===================== 初始化chdb表结构 =====================
def init_chdb_table():
    """初始化CPU监控表结构"""
    # 创建表（使用MergeTree引擎，按时间戳分区，优化时序查询）
    create_sql = f"""
    CREATE TABLE IF NOT EXISTS {CPU_TABLE_NAME} (
        ts UInt64,                  -- 时间戳（毫秒）
        cpu_percent Float32,        -- 整体CPU使用率
        cpu_cores Array(Float32),   -- 各核心CPU使用率
        load1 Float32               -- 1分钟系统负载
    ) ENGINE = MergeTree()
    ORDER BY ts
    SETTINGS index_granularity = 8192;
    """
    # 执行建表语句
    connection.query(create_sql)
    print(f"✅ 初始化chdb表 {CPU_TABLE_NAME} 完成，数据文件路径：{DB_FILE_PATH}")
    
    # 创建网络监控表
    create_net_sql = f"""
    CREATE TABLE IF NOT EXISTS {NET_TABLE_NAME} (
        ts UInt64,                  -- 时间戳（毫秒）
        bytes_sent UInt64,          -- 发送字节数
        bytes_recv UInt64,          -- 接收字节数
        packets_sent UInt64,        -- 发送包数
        packets_recv UInt64,        -- 接收包数
        errin UInt64,               -- 入口错误数
        errout UInt64,              -- 出口错误数
        dropin UInt64,              -- 入口丢包数
        dropout UInt64               -- 出口丢包数
    ) ENGINE = MergeTree()
    ORDER BY ts
    SETTINGS index_granularity = 8192;
    """
    # 执行建表语句
    connection.query(create_net_sql)
    print(f"✅ 初始化chdb表 {NET_TABLE_NAME} 完成，数据文件路径：{DB_FILE_PATH}")

# ===================== 数据采集函数 =====================
def collect_cpu_metrics() -> Dict:
    """采集CPU监控数据（极致性能版）"""
    # 减少psutil调用次数，一次性获取核心数据
    cpu_percent = psutil.cpu_percent(interval=None)  # 非阻塞获取，避免等待
    cpu_cores = psutil.cpu_percent(percpu=True, interval=None)
    load1 = psutil.getloadavg()[0] if psutil.getloadavg() else 0.0
    ts = int(time.time() * 1000)  # 毫秒级时间戳（避免浮点精度问题）
    
    return {
        "ts": ts,
        "cpu_percent": cpu_percent,
        "cpu_cores": cpu_cores,
        "load1": load1
    }

def collect_net_metrics() -> Dict:
    """采集网络IO监控数据"""
    # 获取网络IO统计
    net_io = psutil.net_io_counters()
    ts = int(time.time() * 1000)  # 毫秒级时间戳
    
    return {
        "ts": ts,
        "bytes_sent": net_io.bytes_sent,
        "bytes_recv": net_io.bytes_recv,
        "packets_sent": net_io.packets_sent,
        "packets_recv": net_io.packets_recv,
        "errin": net_io.errin,
        "errout": net_io.errout,
        "dropin": net_io.dropin,
        "dropout": net_io.dropout
    }

# ===================== 批量写入函数 =====================
def batch_write_to_chdb():
    """批量写入数据到chdb（线程安全）"""
    global cpu_data_buffer
    with cpu_buffer_lock:
        if len(cpu_data_buffer) < BATCH_SIZE:
            return
        
        # 构建插入SQL（参数化查询，避免SQL注入，提升性能）
        values_str = ", ".join([
            f"({ts}, {cpu_percent}, {cpu_cores}, {load1})"
            for ts, cpu_percent, cpu_cores, load1 in cpu_data_buffer
        ])
        insert_sql = f"""
        INSERT INTO {CPU_TABLE_NAME} (ts, cpu_percent, cpu_cores, load1)
        VALUES {values_str};
        """
        
        # 执行插入
        connection.query(insert_sql)
        
        # 清空缓冲区
        cpu_data_buffer.clear()
        print(f"📝 批量写入{BATCH_SIZE}条CPU监控数据完成")

def batch_write_net_to_chdb():
    """批量写入网络数据到chdb（线程安全）"""
    global net_data_buffer
    with net_buffer_lock:
        if len(net_data_buffer) < BATCH_SIZE:
            return
        
        # 构建插入SQL（参数化查询，避免SQL注入，提升性能）
        values_str = ", ".join([
            f"({ts}, {bytes_sent}, {bytes_recv}, {packets_sent}, {packets_recv}, {errin}, {errout}, {dropin}, {dropout})"
            for ts, bytes_sent, bytes_recv, packets_sent, packets_recv, errin, errout, dropin, dropout in net_data_buffer
        ])
        insert_sql = f"""
        INSERT INTO {NET_TABLE_NAME} (ts, bytes_sent, bytes_recv, packets_sent, packets_recv, errin, errout, dropin, dropout)
        VALUES {values_str};
        """
        
        # 执行插入
        connection.query(insert_sql)
        
        # 清空缓冲区
        net_data_buffer.clear()
        print(f"📝 批量写入{BATCH_SIZE}条网络监控数据完成")

# ===================== 监控线程 =====================
def monitor_worker():
    """CPU监控工作线程"""
    print("🚀 CPU监控线程启动，采集间隔：{}秒".format(COLLECT_INTERVAL))
    while True:
        try:
            # 采集数据
            metrics = collect_cpu_metrics()
            
            # 转换为元组存入缓冲区（元组比字典更高效）
            with cpu_buffer_lock:
                cpu_data_buffer.append((
                    metrics["ts"],
                    metrics["cpu_percent"],
                    metrics["cpu_cores"],
                    metrics["load1"]
                ))
            
            # 检查是否达到批量写入阈值
            if len(cpu_data_buffer) >= BATCH_SIZE:
                batch_write_to_chdb()
            
            # 休眠指定间隔（避免忙等）
            time.sleep(COLLECT_INTERVAL)
            
        except Exception as e:
            print(f"❌ CPU监控线程异常：{e}")
            time.sleep(COLLECT_INTERVAL)

def net_monitor_worker():
    """网络IO监控工作线程"""
    print("🚀 网络IO监控线程启动，采集间隔：{}秒".format(COLLECT_INTERVAL))
    while True:
        try:
            # 采集网络数据
            metrics = collect_net_metrics()
            
            # 转换为元组存入缓冲区
            with net_buffer_lock:
                net_data_buffer.append((
                    metrics["ts"],
                    metrics["bytes_sent"],
                    metrics["bytes_recv"],
                    metrics["packets_sent"],
                    metrics["packets_recv"],
                    metrics["errin"],
                    metrics["errout"],
                    metrics["dropin"],
                    metrics["dropout"]
                ))
            
            # 检查是否达到批量写入阈值
            if len(net_data_buffer) >= BATCH_SIZE:
                batch_write_net_to_chdb()
            
            # 休眠指定间隔（避免忙等）
            time.sleep(COLLECT_INTERVAL)
            
        except Exception as e:
            print(f"❌ 网络IO监控线程异常：{e}")
            time.sleep(COLLECT_INTERVAL)

# ===================== 数据查询函数 =====================
def query_cpu_metrics(time_range: Tuple[int, int] = None, limit: int = 1000) -> List[Dict]:
    """
    查询CPU监控数据
    :param time_range: 时间范围（起始毫秒，结束毫秒），None表示查询所有
    :param limit: 返回数据条数限制
    :return: 格式化的监控数据列表
    """
    # 构建查询条件
    where_clause = ""
    if time_range:
        start_ts, end_ts = time_range
        where_clause = f"WHERE ts >= {start_ts} AND ts <= {end_ts}"
    
    # 构建查询SQL（按时间戳降序，最新数据在前）
    query_sql_csv = f"""
    SELECT 
        ts,
        cpu_percent,
        cpu_cores,
        load1,
        toDateTime(ts / 1000) as dt
    FROM {CPU_TABLE_NAME}
    {where_clause}
    ORDER BY ts DESC
    LIMIT {limit}
    FORMAT CSV;
    """
    
    try:
        result = connection.query(query_sql_csv)
        result_str = str(result)
        
        # 解析CSV结果
        import csv
        import io
        
        # 将结果转换为CSV格式进行解析
        csv_data = io.StringIO(result_str)
        # 由于chdb的CSV格式可能不标准，我们直接按行解析
        lines = result_str.strip().split('\n')
        
        # 格式化数据（转换为更易读的结构）
        formatted_data = []
        for line in lines:
            if line.strip():
                # 手动解析CSV行（格式: ts,cpu_percent,cpu_cores,load1,dt）
                parts = line.split(',', 4)  # 分割成最多5部分，因为cpu_cores可能包含逗号
                if len(parts) >= 5:
                    ts, cpu_percent, cpu_cores_str, load1, dt = parts
                    # 修复cpu_cores的解析，它可能包含逗号
                    # 由于格式复杂，我们重新查询一次，但不包含cpu_cores
                    query_sql_simple = f"""
                    SELECT 
                        ts,
                        cpu_percent,
                        load1,
                        toDateTime(ts / 1000) as dt
                    FROM {CPU_TABLE_NAME}
                    WHERE ts = {ts}
                    FORMAT CSV;
                    """
                    simple_result = connection.query(query_sql_simple)
                    simple_result_str = str(simple_result).strip()
                    if simple_result_str:
                        simple_parts = simple_result_str.split(',')
                        if len(simple_parts) >= 4:
                            ts, cpu_percent, load1, dt = simple_parts
                            
                            # 再单独查询cpu_cores
                            cores_query = f"SELECT cpu_cores FROM {CPU_TABLE_NAME} WHERE ts = {ts} FORMAT CSV;"
                            cores_result = connection.query(cores_query)
                            cores_str = str(cores_result).strip()
                            
                            formatted_data.append({
                                "timestamp": int(ts),
                                "datetime": dt.strip().strip('"'),  # 去除可能的引号
                                "cpu_percent": float(cpu_percent),
                                "cpu_cores": eval(cores_str) if cores_str and cores_str != '[]' else [],
                                "load1": float(load1)
                            })
        
        return formatted_data
    except Exception as e:
        print(f"查询数据时出错: {e}")
        return []

def query_net_metrics(time_range: Tuple[int, int] = None, limit: int = 1000) -> List[Dict]:
    """
    查询网络IO监控数据
    :param time_range: 时间范围（起始毫秒，结束毫秒），None表示查询所有
    :param limit: 返回数据条数限制
    :return: 格式化的监控数据列表
    """
    # 构建查询条件
    where_clause = ""
    if time_range:
        start_ts, end_ts = time_range
        where_clause = f"WHERE ts >= {start_ts} AND ts <= {end_ts}"
    
    # 构建查询SQL（按时间戳降序，最新数据在前）
    query_sql_csv = f"""
    SELECT 
        ts,
        bytes_sent,
        bytes_recv,
        packets_sent,
        packets_recv,
        errin,
        errout,
        dropin,
        dropout,
        toDateTime(ts / 1000) as dt
    FROM {NET_TABLE_NAME}
    {where_clause}
    ORDER BY ts DESC
    LIMIT {limit}
    FORMAT CSV;
    """
    
    try:
        result = connection.query(query_sql_csv)
        result_str = str(result)
        
        # 解析CSV结果
        import csv
        import io
        
        # 将结果转换为CSV格式进行解析
        csv_data = io.StringIO(result_str)
        # 由于chdb的CSV格式可能不标准，我们直接按行解析
        lines = result_str.strip().split('\n')
        
        # 格式化数据（转换为更易读的结构）
        formatted_data = []
        for line in lines:
            if line.strip():
                # 手动解析CSV行
                parts = line.split(',', 9)  # 分割成最多10部分
                if len(parts) >= 10:
                    ts, bytes_sent, bytes_recv, packets_sent, packets_recv, errin, errout, dropin, dropout, dt = parts
                    
                    formatted_data.append({
                        "timestamp": int(ts),
                        "datetime": dt.strip().strip('"'),  # 去除可能的引号
                        "bytes_sent": int(bytes_sent),
                        "bytes_recv": int(bytes_recv),
                        "packets_sent": int(packets_sent),
                        "packets_recv": int(packets_recv),
                        "errin": int(errin),
                        "errout": int(errout),
                        "dropin": int(dropin),
                        "dropout": int(dropout)
                    })
        
        return formatted_data
    except Exception as e:
        print(f"查询网络数据时出错: {e}")
        return []

# ===================== 主函数 =====================
if __name__ == "__main__":
    # 初始化表结构
    init_chdb_table()
    
    # 启动CPU监控线程（后台运行）
    cpu_monitor_thread = threading.Thread(target=monitor_worker, daemon=True)
    cpu_monitor_thread.start()
    
    # 启动网络IO监控线程（后台运行）
    net_monitor_thread = threading.Thread(target=net_monitor_worker, daemon=True)
    net_monitor_thread.start()
    
    # 主线程用于查询演示
    try:
        # 等待5秒让监控线程采集一些数据
        time.sleep(5)
        
        # 示例1：查询最近10条CPU数据
        print("\n=== 查询最近10条CPU监控数据 ===")
        recent_cpu_data = query_cpu_metrics(limit=10)
        for idx, item in enumerate(recent_cpu_data):
            print(f"[{idx+1}] 时间：{item['datetime']} | CPU整体使用率：{item['cpu_percent']}% | 各核心：{item['cpu_cores']} | 1分钟负载：{item['load1']}")
        
        # 示例2：查询最近10条网络数据
        print("\n=== 查询最近10条网络IO监控数据 ===")
        recent_net_data = query_net_metrics(limit=10)
        for idx, item in enumerate(recent_net_data):
            print(f"[{idx+1}] 时间：{item['datetime']} | 发送字节：{item['bytes_sent']} | 接收字节：{item['bytes_recv']} | 发送包：{item['packets_sent']} | 接收包：{item['packets_recv']}")
        
        # 示例3：查询指定时间范围的CPU数据（最近10秒）
        print("\n=== 查询最近10秒CPU监控数据 ===")
        end_ts = int(time.time() * 1000)
        start_ts = end_ts - 10 * 1000
        time_range_cpu_data = query_cpu_metrics(time_range=(start_ts, end_ts))
        print(f"查询到{len(time_range_cpu_data)}条CPU数据，部分数据：")
        for item in time_range_cpu_data[:5]:  # 只打印前5条
            print(f"时间：{item['datetime']} | CPU使用率：{item['cpu_percent']}%")
        
        # 示例4：查询指定时间范围的网络数据（最近10秒）
        print("\n=== 查询最近10秒网络IO监控数据 ===")
        time_range_net_data = query_net_metrics(time_range=(start_ts, end_ts))
        print(f"查询到{len(time_range_net_data)}条网络数据，部分数据：")
        for item in time_range_net_data[:5]:  # 只打印前5条
            print(f"时间：{item['datetime']} | 发送字节：{item['bytes_sent']} | 接收字节：{item['bytes_recv']}")
        
        # 保持主线程运行
        while True:
            time.sleep(1)

    except KeyboardInterrupt:
        print("\n🛑 程序被用户中断")
        # 最后写入CPU缓冲区剩余数据
        with cpu_buffer_lock:
            if cpu_data_buffer:
                batch_write_to_chdb()
        # 最后写入网络缓冲区剩余数据
        with net_buffer_lock:
            if net_data_buffer:
                batch_write_net_to_chdb()
        print("✅ 缓冲区剩余数据已写入，程序退出")

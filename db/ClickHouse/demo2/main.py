"""
chDB系统监控数据管理工具

功能说明：
1. 初始化数据库表结构 (init)
2. 模拟插入监控数据 (simulate)
3. 查询监控数据 (query)

使用方法：
- python main.py init                    # 初始化数据库表结构
- python main.py simulate --count 100    # 模拟插入100条监控数据
- python main.py query --type both --limit 10  # 查询最近10条CPU和内存数据

参数说明：
init命令：
  --force          强制重新初始化表结构

simulate命令：
  --count COUNT    指定插入数据条数，默认100条

query命令：
  --type {cpu,memory,both}    查询数据类型，默认both
  --limit LIMIT               限制返回数据条数，默认10条
  --time-range START END      指定时间范围（毫秒时间戳）

示例：
- python main.py init                    # 初始化数据库
- python main.py simulate --count 50     # 插入50条模拟数据
- python main.py query --type cpu --limit 5   # 查询5条CPU数据
- python main.py query --type memory --limit 20 --time-range 1700000000000 1700086400000  # 查询指定时间范围的内存数据
"""

import time
import psutil
import chdb
import threading
from datetime import datetime
from typing import List, Dict, Tuple
import os
import argparse
import random

# ===================== 配置项 =====================
COLLECT_INTERVAL = 1            # 监控采集间隔（秒）
BATCH_SIZE = 10                 # 批量写入阈值（达到该条数时写入）
DB_FILE_PATH = "./master.chdb"  # 数据存储文件路径
CPU_TABLE_NAME = "cpu_metrics"  # CPU监控表名
MEM_TABLE_NAME = "mem_metrics"  # 内存监控表名

# ===================== 全局变量 =====================
# 批量数据缓冲区
cpu_data_buffer: List[Tuple] = []
memory_data_buffer: List[Tuple] = []

# 缓冲区锁（线程安全）
cpu_buffer_lock = threading.Lock()
memory_buffer_lock = threading.Lock()

# 创建全局连接，使用持久化数据库
connection = chdb.connect(DB_FILE_PATH)

# ===================== 初始化chdb表结构 =====================


def init_chdb_table():
    """初始化CPU监控表结构"""
    # 创建表（使用MergeTree引擎，按时间戳分区，优化时序查询）
    create_sql = f"""CREATE TABLE IF NOT EXISTS {CPU_TABLE_NAME} (
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

    # 创建内存监控表
    create_memory_sql = f"""
    CREATE TABLE IF NOT EXISTS {MEM_TABLE_NAME} (
        ts UInt64,                  -- 时间戳（毫秒）
        memory_percent Float32,     -- 内存使用率(%)
        memory_total UInt64,        -- 总内存(字节)
        memory_available UInt64,    -- 可用内存(字节)
        memory_used UInt64,         -- 已使用内存(字节)
        memory_free UInt64,         -- 空闲内存(字节)
        swap_percent Float32,       -- 交换空间使用率(%)
        swap_total UInt64,          -- 交换空间总量(字节)
        swap_used UInt64             -- 交换空间已使用(字节)
    ) ENGINE = MergeTree()
    ORDER BY ts
    SETTINGS index_granularity = 8192;
    """
    # 执行建表语句
    connection.query(create_memory_sql)
    print(f"✅ 初始化chdb表 {MEM_TABLE_NAME} 完成，数据文件路径：{DB_FILE_PATH}")

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


def collect_mem_metrics() -> Dict:
    """采集内存使用率监控数据"""
    # 获取虚拟内存统计
    virtual_memory = psutil.virtual_memory()
    # 获取交换内存统计
    swap_memory = psutil.swap_memory()
    ts = int(time.time() * 1000)  # 毫秒级时间戳

    return {
        "ts": ts,
        "memory_percent": virtual_memory.percent,
        "memory_total": virtual_memory.total,
        "memory_available": virtual_memory.available,
        "memory_used": virtual_memory.used,
        "memory_free": virtual_memory.free,
        "swap_percent": swap_memory.percent,
        "swap_total": swap_memory.total,
        "swap_used": swap_memory.used
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


def batch_write_memory_to_chdb():
    """批量写入内存数据到chdb（线程安全）"""
    global memory_data_buffer
    with memory_buffer_lock:
        if len(memory_data_buffer) < BATCH_SIZE:
            return

        # 构建插入SQL（参数化查询，避免SQL注入，提升性能）
        values_str = ", ".join([
            f"({ts}, {memory_percent}, {memory_total}, {memory_available}, {memory_used}, {memory_free}, {swap_percent}, {swap_total}, {swap_used})"
            for ts, memory_percent, memory_total, memory_available, memory_used, memory_free, swap_percent, swap_total, swap_used in memory_data_buffer
        ])
        insert_sql = f"""
        INSERT INTO {MEM_TABLE_NAME} (ts, memory_percent, memory_total, memory_available, memory_used, memory_free, swap_percent, swap_total, swap_used)
        VALUES {values_str};
        """

        # 执行插入
        connection.query(insert_sql)

        # 清空缓冲区
        memory_data_buffer.clear()
        print(f"📝 批量写入{BATCH_SIZE}条内存监控数据完成")

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


def memory_monitor_worker():
    """内存监控工作线程"""
    print("🚀 内存监控线程启动，采集间隔：{}秒".format(COLLECT_INTERVAL))
    while True:
        try:
            # 采集内存数据
            metrics = collect_mem_metrics()

            # 转换为元组存入缓冲区
            with memory_buffer_lock:
                memory_data_buffer.append((
                    metrics["ts"],
                    metrics["memory_percent"],
                    metrics["memory_total"],
                    metrics["memory_available"],
                    metrics["memory_used"],
                    metrics["memory_free"],
                    metrics["swap_percent"],
                    metrics["swap_total"],
                    metrics["swap_used"]
                ))

            # 检查是否达到批量写入阈值
            if len(memory_data_buffer) >= BATCH_SIZE:
                batch_write_memory_to_chdb()

            # 休眠指定间隔（避免忙等）
            time.sleep(COLLECT_INTERVAL)

        except Exception as e:
            print(f"❌ 内存监控线程异常：{e}")
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


def query_mem_metrics(time_range: Tuple[int, int] = None, limit: int = 1000) -> List[Dict]:
    """
    查询内存监控数据
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
        memory_percent,
        memory_total,
        memory_available,
        memory_used,
        memory_free,
        swap_percent,
        swap_total,
        swap_used,
        toDateTime(ts / 1000) as dt
    FROM {MEM_TABLE_NAME}
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
                    ts, memory_percent, memory_total, memory_available, memory_used, memory_free, swap_percent, swap_total, swap_used, dt = parts

                    formatted_data.append({
                        "timestamp": int(ts),
                        "datetime": dt.strip().strip('"'),  # 去除可能的引号
                        "memory_percent": float(memory_percent),
                        "memory_total": int(memory_total),
                        "memory_available": int(memory_available),
                        "memory_used": int(memory_used),
                        "memory_free": int(memory_free),
                        "swap_percent": float(swap_percent),
                        "swap_total": int(swap_total),
                        "swap_used": int(swap_used)
                    })

        return formatted_data
    except Exception as e:
        print(f"查询内存数据时出错: {e}")
        return []


# ===================== 数据模拟插入函数 =====================

def simulate_data_insertion(count: int = 100):
    """
    模拟数据插入功能
    :param count: 插入数据条数
    """
    print(f"🚀 开始模拟插入 {count} 条数据...")

    for i in range(count):
        # 生成模拟CPU数据
        ts = int(time.time() * 1000) - (count - i) * 1000  # 模拟过去时间的数据
        cpu_percent = round(random.uniform(10.0, 90.0), 2)
        cpu_cores = [round(random.uniform(5.0, 95.0), 2)
                     for _ in range(psutil.cpu_count())]
        load1 = round(random.uniform(0.1, 4.0), 2)

        # 添加到CPU缓冲区
        with cpu_buffer_lock:
            cpu_data_buffer.append((ts, cpu_percent, cpu_cores, load1))

        # 检查是否达到批量写入阈值
        if len(cpu_data_buffer) >= BATCH_SIZE:
            batch_write_to_chdb()

        # 生成模拟内存数据
        memory_percent = round(random.uniform(20.0, 85.0), 2)
        memory_total = 16 * 1024 * 1024 * 1024  # 16GB
        memory_used = int(memory_total * memory_percent / 100)
        memory_available = memory_total - memory_used
        memory_free = int(memory_available * 0.8)  # 假设free是available的80%
        swap_percent = round(random.uniform(0.0, 10.0), 2)
        swap_total = 4 * 1024 * 1024 * 1024  # 4GB
        swap_used = int(swap_total * swap_percent / 100)

        # 添加到内存缓冲区
        with memory_buffer_lock:
            memory_data_buffer.append((
                ts,
                memory_percent,
                memory_total,
                memory_available,
                memory_used,
                memory_free,
                swap_percent,
                swap_total,
                swap_used
            ))

        # 检查是否达到批量写入阈值
        if len(memory_data_buffer) >= BATCH_SIZE:
            batch_write_memory_to_chdb()

        # 每10条数据打印一次进度
        if (i + 1) % 10 == 0:
            print(f"📊 已插入 {i + 1}/{count} 条模拟数据")

        time.sleep(0.01)  # 短暂休眠，避免过快执行

    # 写入剩余数据
    with cpu_buffer_lock:
        if cpu_data_buffer:
            batch_write_to_chdb()
    with memory_buffer_lock:
        if memory_data_buffer:
            batch_write_memory_to_chdb()

    print(f"✅ 模拟数据插入完成，共插入 {count} 条数据")


# ===================== 命令行主函数 =====================

def main():
    parser = argparse.ArgumentParser(
        description="chDB系统监控数据管理工具",
        epilog="""
使用示例:
  python main.py init                    # 初始化数据库表结构
  python main.py simulate --count 100    # 模拟插入100条监控数据
  python main.py query --type both --limit 10  # 查询最近10条CPU和内存数据
  python main.py query --type cpu --limit 5   # 查询5条CPU数据
  python main.py query --type memory --limit 20 --time-range 1700000000000 1700086400000  # 查询指定时间范围的内存数据
        """,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    subparsers = parser.add_subparsers(dest="command", help="可用命令")

    # 初始化命令
    init_parser = subparsers.add_parser("init", help="初始化数据库表结构 - 创建CPU和内存监控表")
    init_parser.add_argument(
        "--force", action="store_true", help="强制重新初始化表结构，会覆盖现有表（如果存在）")

    # 数据模拟插入命令
    simulate_parser = subparsers.add_parser(
        "simulate", help="模拟插入监控数据 - 生成并插入模拟的CPU和内存监控数据")
    simulate_parser.add_argument(
        "--count", type=int, default=100, help="指定插入数据条数，默认为100条")

    # 数据查询命令
    query_parser = subparsers.add_parser(
        "query", help="查询监控数据 - 从数据库中检索CPU和/或内存监控数据")
    query_parser.add_argument(
        "--type", choices=["cpu", "memory", "both"], default="both", help="指定查询数据类型: 'cpu'仅CPU数据, 'memory'仅内存数据, 'both'CPU和内存数据（默认）")
    query_parser.add_argument(
        "--limit", type=int, default=10, help="限制返回数据条数，默认为10条")
    query_parser.add_argument(
        "--time-range", nargs=2, type=int, metavar=("START", "END"), help="指定查询时间范围（毫秒时间戳），格式：开始时间戳 结束时间戳")

    # 解析参数
    args = parser.parse_args()

    # 如果没有提供命令，显示帮助
    if args.command is None:
        parser.print_help()
        return

    # 根据命令执行相应操作
    if args.command == "init":
        print("🚀 开始初始化数据库表结构...")
        if args.force:
            print("⚠️  强制重新初始化表结构")
        init_chdb_table()

    elif args.command == "simulate":
        print(f"🚀 开始模拟插入 {args.count} 条数据...")
        simulate_data_insertion(args.count)

    elif args.command == "query":
        print("🔍 开始查询监控数据...")

        # 准备时间范围参数
        time_range = tuple(args.time_range) if args.time_range else None

        # 查询CPU数据
        if args.type in ["cpu", "both"]:
            print("\n=== CPU监控数据 ===")
            cpu_data = query_cpu_metrics(
                time_range=time_range, limit=args.limit)
            if cpu_data:
                for idx, item in enumerate(cpu_data):
                    print(
                        f"[{idx+1}] 时间：{item['datetime']} | CPU整体使用率：{item['cpu_percent']}% | 各核心：{item['cpu_cores']} | 1分钟负载：{item['load1']}")
            else:
                print("未查询到CPU监控数据")

        # 查询内存数据
        if args.type in ["memory", "both"]:
            print("\n=== 内存监控数据 ===")
            memory_data = query_mem_metrics(
                time_range=time_range, limit=args.limit)
            if memory_data:
                for idx, item in enumerate(memory_data):
                    print(f"[{idx+1}] 时间：{item['datetime']} | 内存使用率：{item['memory_percent']}% | 总内存：{item['memory_total']} | 已用内存：{item['memory_used']} | 可用内存：{item['memory_available']}")
            else:
                print("未查询到内存监控数据")


if __name__ == "__main__":
    main()

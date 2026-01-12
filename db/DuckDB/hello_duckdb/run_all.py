"""
Hello DuckDB - 项目入口点
运行所有演示模块的综合示例
"""

import os
import sys
from main import main as main_demo
from data_processor import demo_data_processing
from query_analyzer import demo_query_analysis
from crud_demo import crud_full_demo
from performance_test import performance_full_test
try:
    from perf_monitor import PerformanceMonitor, QueryAnalyzer
    PERF_MONITOR_AVAILABLE = True
except ImportError:
    PERF_MONITOR_AVAILABLE = False

def run_all_demos():
    """运行所有演示"""
    print("🚀 Hello DuckDB - 综合演示")
    print("=" * 60)
    print("这是一个完整的DuckDB使用示例项目")
    print("包含基本操作、数据处理、查询分析、CRUD操作和性能测试")
    print("=" * 60)
    
    # 确保必要目录存在
    os.makedirs("data", exist_ok=True)
    os.makedirs("output", exist_ok=True)
    
    # 1. 基本操作演示
    print("\n" + "="*60)
    print("1️⃣  基本操作演示")
    print("="*60)
    try:
        main_demo()
    except Exception as e:
        print(f"基本操作演示出错: {e}")
    
    # 2. 数据处理演示
    print("\n" + "="*60)
    print("2️⃣  数据处理演示")
    print("="*60)
    try:
        demo_data_processing()
    except Exception as e:
        print(f"数据处理演示出错: {e}")
    
    # 3. 查询分析演示
    print("\n" + "="*60)
    print("3️⃣  查询分析演示")
    print("="*60)
    try:
        demo_query_analysis()
    except Exception as e:
        print(f"查询分析演示出错: {e}")
    
    # 4. CRUD操作演示
    print("\n" + "="*60)
    print("4️⃣  CRUD操作演示")
    print("="*60)
    try:
        crud_full_demo()
    except Exception as e:
        print(f"CRUD操作演示出错: {e}")
    
    # 5. 性能测试演示
    print("\n" + "="*60)
    print("5️⃣  性能测试演示")
    print("="*60)
    try:
        performance_full_test()
    except Exception as e:
        print(f"性能测试演示出错: {e}")
    
    # 6. 性能监控演示
    print("\n" + "="*60)
    print("6️⃣  性能监控演示（多连接使用场景）")
    print("="*60)
    if PERF_MONITOR_AVAILABLE:
        try:
            # 创建性能监控器和分析器实例
            monitor = PerformanceMonitor()
            analyzer = QueryAnalyzer()
            
            # 立即采集一条数据用于演示
            monitor.collect_metrics()
            
            # 运行分析
            analyzer.run_analysis()
            print("性能监控演示完成！")
        except Exception as e:
            print(f"性能监控演示出错: {e}")
    else:
        print("性能监控模块不可用，请确保已安装psutil和schedule依赖")
    
    print("\n" + "="*60)
    print("✅ 所有演示完成！")
    print("Hello DuckDB 项目成功展示了DuckDB的核心功能")
    print("="*60)

if __name__ == "__main__":
    run_all_demos()
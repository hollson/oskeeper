"""
Hello DuckDB - 项目验证脚本
验证所有模块的功能是否正常工作
"""

import subprocess
import sys
import os

def run_command(cmd):
    """运行命令并返回结果"""
    try:
        result = subprocess.run(
            cmd, 
            shell=True, 
            capture_output=True, 
            text=True, 
            timeout=60
        )
        return result.returncode == 0, result.stdout, result.stderr
    except subprocess.TimeoutExpired:
        return False, "", "Command timed out"

def test_module(module_name, description):
    """测试单个模块"""
    print(f"\n🧪 测试 {description} ({module_name})")
    print("-" * 50)
    
    success, stdout, stderr = run_command(f"python {module_name}")
    
    if success:
        print(f"✅ {module_name} 运行成功")
        # 只显示关键输出
        lines = stdout.split('\n')
        # 打印前几行和后几行
        for line in lines[:5]:
            if line.strip():
                print(f"   {line[:80]}...")
        if len(lines) > 10:
            print("   ...")
            for line in lines[-3:]:
                if line.strip():
                    print(f"   {line[:80]}...")
    else:
        print(f"❌ {module_name} 运行失败")
        print(f"错误: {stderr}")
    
    return success

def main():
    """主验证函数"""
    print("🧪 Hello DuckDB - 项目功能验证")
    print("=" * 60)
    
    # 定义要测试的模块
    modules = [
        ("main.py", "基本操作演示"),
        ("data_processor.py", "数据处理演示"),
        ("query_analyzer.py", "查询分析演示"),
        ("crud_demo.py", "CRUD操作演示"),
        ("performance_test.py", "性能测试演示"),
        ("run_all.py", "完整演示")
    ]
    
    results = {}
    
    # 测试每个模块
    for module, description in modules:
        results[module] = test_module(module, description)
    
    # 汇总结果
    print("\n" + "=" * 60)
    print("📊 验证结果汇总:")
    print("=" * 60)
    
    all_passed = True
    for module, success in results.items():
        status = "✅ 通过" if success else "❌ 失败"
        print(f"{module:<20} {status}")
        if not success:
            all_passed = False
    
    print("=" * 60)
    if all_passed:
        print("🎉 所有测试通过！Hello DuckDB 项目功能正常。")
    else:
        print("⚠️  部分测试失败，请检查相关模块。")
    
    return all_passed

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
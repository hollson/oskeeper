"""
CRUD操作演示模块
演示创建(Create)、读取(Retrieve)、更新(Update)、删除(Delete)操作
"""

import duckdb
import pandas as pd
import time

def create_operation(conn):
    """创建操作演示"""
    print("\n📝 创建操作演示")
    
    # 创建新的表
    conn.execute("""
        CREATE TABLE IF NOT EXISTS employees (
            id INTEGER,
            name VARCHAR,
            department VARCHAR,
            salary DECIMAL(10,2),
            hire_date DATE
        )
    """)
    
    # 插入数据
    conn.execute("""
        INSERT INTO employees VALUES 
        (1, '张三', '技术部', 8000.00, '2023-01-15'),
        (2, '李四', '市场部', 7500.00, '2023-02-20'),
        (3, '王五', '财务部', 7000.00, '2023-03-10'),
        (4, '赵六', '人事部', 6500.00, '2023-04-05')
    """)
    
    print("员工表创建并插入数据完成")
    
    # 验证插入的数据
    result = conn.execute("SELECT * FROM employees").df()
    print("当前员工数据:")
    print(result)

def retrieve_operation(conn):
    """读取操作演示"""
    print("\n📖 读取操作演示")
    
    # 基本查询
    basic_query = conn.execute("SELECT * FROM employees WHERE salary > 7000").df()
    print("薪资大于7000的员工:")
    print(basic_query)
    
    # 聚合查询
    dept_salary = conn.execute("""
        SELECT 
            department,
            COUNT(*) as employee_count,
            AVG(salary) as avg_salary,
            MAX(salary) as max_salary
        FROM employees
        GROUP BY department
    """).df()
    print("\n各部门薪资统计:")
    print(dept_salary)

def update_operation(conn):
    """更新操作演示（带事务）"""
    print("\n🔄 更新操作演示（带事务）")
    
    try:
        # 开始事务
        print("开始事务...")
        conn.execute("BEGIN TRANSACTION;")
        
        # 执行更新操作 - 技术部员工薪资上调10%
        print("执行更新：技术部员工薪资上调10%")
        update_result = conn.execute("""
            UPDATE employees
            SET salary = salary * 1.10
            WHERE department = '技术部';
        """)
        
        # 显示更新前后的对比
        print("\n更新后的员工数据:")
        updated_data = conn.execute("SELECT * FROM employees ORDER BY salary DESC").df()
        print(updated_data)
        
        # 计算更新影响的行数
        affected_rows = conn.execute("SELECT COUNT(*) FROM employees WHERE department = '技术部'").fetchone()[0]
        print(f"更新了 {affected_rows} 名技术部员工的薪资")
        
        # 提交事务
        conn.execute("COMMIT;")
        print("事务提交成功！")
        
    except Exception as e:
        # 回滚事务
        conn.execute("ROLLBACK;")
        print(f"更新失败，已回滚: {e}")

def delete_operation(conn):
    """删除操作演示"""
    print("\n🗑️ 删除操作演示")
    
    # 显示删除前的数据
    print("删除前的员工数据:")
    before_delete = conn.execute("SELECT * FROM employees").df()
    print(before_delete)
    
    # 删除操作
    print("\n删除人事部员工...")
    conn.execute("DELETE FROM employees WHERE department = '人事部'")
    
    # 显示删除后的数据
    print("删除后的员工数据:")
    after_delete = conn.execute("SELECT * FROM employees").df()
    print(after_delete)
    
    deleted_count = len(before_delete) - len(after_delete)
    print(f"删除了 {deleted_count} 条记录")

def transaction_demo(conn):
    """事务演示 - 更复杂的场景"""
    print("\n💳 事务演示 - 复杂场景")
    
    try:
        # 开始事务
        conn.execute("BEGIN TRANSACTION;")
        print("开始事务...")
        
        # 插入新员工
        print("插入新员工...")
        conn.execute("""
            INSERT INTO employees VALUES 
            (5, '钱七', '技术部', 9000.00, '2023-05-01')
        """)
        
        # 更新薪资
        print("更新技术部薪资...")
        conn.execute("""
            UPDATE employees
            SET salary = salary * 1.05
            WHERE department = '技术部'
        """)
        
        # 验证更新结果
        tech_employees = conn.execute("SELECT * FROM employees WHERE department = '技术部'").df()
        print("技术部员工更新后:")
        print(tech_employees)
        
        # 提交事务
        conn.execute("COMMIT;")
        print("复杂事务提交成功！")
        
    except Exception as e:
        # 回滚事务
        conn.execute("ROLLBACK;")
        print(f"复杂事务失败，已回滚: {e}")

def crud_full_demo():
    """完整CRUD演示"""
    print("\n🚀 完整CRUD操作演示")
    print("=" * 50)
    
    # 连接到数据库
    conn = duckdb.connect("hello_duckdb.duckdb")
    
    # 执行CRUD操作
    create_operation(conn)
    retrieve_operation(conn)
    update_operation(conn)
    delete_operation(conn)
    transaction_demo(conn)
    
    # 最终状态检查
    print("\n📋 最终员工数据状态:")
    final_data = conn.execute("SELECT * FROM employees ORDER BY id").df()
    print(final_data)
    
    # 关闭连接
    conn.close()
    print("\n✅ CRUD操作演示完成")

if __name__ == "__main__":
    crud_full_demo()
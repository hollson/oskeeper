from utils.database import create_tables, test_connection
from examples.crud_operations import demo_crud_operations
from examples.query_operations import demo_query_operations
from examples.batch_operations import demo_batch_operations, demo_transaction_operations
import logging

# 配置日志
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def main():
    """
    在chdb文件数据库模式下运行SQLAlchemy ClickHouse演示的主要函数
    """
    print("SQLAlchemy与chdb文件数据库模式演示")
    print("=" * 45)

    # 测试数据库连接
    print("\n1. 测试chdb文件数据库可用性...")
    if test_connection():
        print("✓ chdb文件数据库可用\n")
    else:
        print("✗ chdb文件数据库不可用")
        print("  请安装chdb模块: pip install chdb 或 uv pip install chdb")
        print("  注意: chdb仅支持macOS和Linux系统")
        return

    print("2. 在chdb文件数据库模式下运行...")
    print("   本演示展示如何使用chdb作为文件数据库，类似SQLite")
    print("   数据将持久化到 ./data/clickhouse_local.db 文件中")
    print()

    print("自动继续演示...")
    # 自动继续演示，无需用户输入

    # 显示chdb文件数据库模式下的操作
    print("\n3. 在chdb文件数据库模式下创建表...")
    create_tables()
    print("✓ 表创建成功\n")

    # 运行CRUD操作演示
    print("4. 运行CRUD操作演示...")
    demo_crud_operations()

    # 运行查询操作演示
    print("\n5. 运行查询操作演示...")
    demo_query_operations()

    # 运行批处理和事务操作演示
    print("\n6. 运行批处理和事务操作演示...")
    demo_batch_operations()
    print("\n" + "="*50 + "\n")
    demo_transaction_operations()

    print("\n" + "=" * 45)
    print("演示成功完成!")
    print("数据已持久化到 ./data/clickhouse_local.db 文件中")
    print("您可以查看'data'目录中的数据库文件。")


if __name__ == "__main__":
    main()

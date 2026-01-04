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
    在Local模式下运行SQLAlchemy ClickHouse演示的主要函数
    """
    print("SQLAlchemy与ClickHouse Local模式演示")
    print("=" * 45)

    # 测试数据库连接
    print("\n1. 测试ClickHouse Local可用性...")
    if test_connection():
        print("✓ ClickHouse Local可用\n")
    else:
        print("✗ ClickHouse Local不可用")
        print("  请安装ClickHouse并确保'clickhouse-local'命令在您的PATH中")
        print("  或从以下地址下载: https://clickhouse.com/docs/en/getting-started/install/")
        return

    print("2. 在ClickHouse Local模式下运行...")
    print("   注意: 此演示显示ClickHouse Local的SQLAlchemy样式模式")
    print("   实际操作将直接使用clickhouse-local命令")
    print("   示例: clickhouse-local --query='SELECT 1'")
    print()
    
    print("自动继续演示...")
    # 自动继续演示，无需用户输入

    # 显示Local模式下的操作
    print("\n3. 在ClickHouse Local模式下创建表...")
    create_tables()
    print("✓ 表创建成功\n")

    # 运行CRUD操作演示(显示模式)
    print("4. 运行CRUD操作演示(显示SQLAlchemy模式)...")
    demo_crud_operations()

    # 运行查询操作演示(显示模式)
    print("\n5. 运行查询操作演示(显示SQLAlchemy模式)...")
    demo_query_operations()

    # 运行批处理和事务操作演示(显示模式)
    print("\n6. 运行批处理和事务操作演示(显示SQLAlchemy模式)...")
    demo_batch_operations()
    print("\n" + "="*50 + "\n")
    demo_transaction_operations()

    print("\n" + "=" * 45)
    print("演示成功完成!")
    print("您可以现在查看'examples'目录中的示例")
    print("并根据需要修改它们。")
    print("\n有关实际ClickHouse Local操作，请使用:")
    print("  clickhouse-local --query='SELECT ...'")
    print("  clickhouse-local --path=/path/to/data --structure='col1 String' --input-file=data.csv")


if __name__ == "__main__":
    main()
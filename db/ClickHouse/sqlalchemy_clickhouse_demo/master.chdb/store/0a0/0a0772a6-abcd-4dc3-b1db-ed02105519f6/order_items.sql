ATTACH TABLE _ UUID '537f2688-1867-4828-91cd-862a1c6cd13f'
(
    `id` Int32,
    `uuid` String,
    `order_id` Int32,
    `product_id` Int32,
    `quantity` Int32,
    `unit_price` Float64,
    `total_price` Float64,
    `created_at` DateTime
)
ENGINE = File('CSV', '/mnt/hgfs/E/github/oskeeper/db/ClickHouse/sqlalchemy_clickhouse_demo/order_items.csv')

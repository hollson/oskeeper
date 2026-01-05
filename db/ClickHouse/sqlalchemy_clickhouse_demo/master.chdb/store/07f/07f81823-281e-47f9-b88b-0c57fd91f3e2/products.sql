ATTACH TABLE _ UUID 'e2475dfb-f909-4826-ae1b-9c739d6ff667'
(
    `id` Int32,
    `uuid` String,
    `name` String,
    `description` String,
    `price` Float64,
    `stock_quantity` Int32,
    `category` String,
    `is_active` UInt8,
    `created_at` DateTime,
    `updated_at` DateTime
)
ENGINE = File('CSV', '/mnt/hgfs/E/github/oskeeper/db/ClickHouse/sqlalchemy_clickhouse_demo/products.csv')

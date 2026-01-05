ATTACH TABLE _ UUID 'f766d224-31c0-441e-9be8-8d827ea7611f'
(
    `id` Int32,
    `uuid` String,
    `user_id` Int32,
    `order_number` String,
    `total_amount` Float64,
    `status` String,
    `shipping_address` String,
    `created_at` DateTime,
    `updated_at` DateTime
)
ENGINE = File('CSV', '/mnt/hgfs/E/github/oskeeper/db/ClickHouse/sqlalchemy_clickhouse_demo/orders.csv')

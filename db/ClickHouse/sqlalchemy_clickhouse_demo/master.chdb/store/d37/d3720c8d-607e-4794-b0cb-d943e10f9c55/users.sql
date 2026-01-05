ATTACH TABLE _ UUID '83f3b89b-df38-49a3-8077-54051f5ba678'
(
    `id` Int32,
    `uuid` String,
    `username` String,
    `email` String,
    `first_name` String,
    `last_name` String,
    `age` Int32,
    `is_active` UInt8,
    `created_at` DateTime,
    `updated_at` DateTime
)
ENGINE = File('CSV', '/mnt/hgfs/E/github/oskeeper/db/ClickHouse/sqlalchemy_clickhouse_demo/users.csv')

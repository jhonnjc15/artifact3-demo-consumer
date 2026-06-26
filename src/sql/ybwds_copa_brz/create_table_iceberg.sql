CREATE TABLE db_demo.ybwds_copa_brz_iceberg (
  transaction_id STRING,
  customer_id STRING,
  product_sku STRING,
  sales_channel STRING,
  country_code STRING,
  gross_amount DOUBLE,
  discount_amount DOUBLE,
  net_amount DOUBLE,
  currency_code STRING,
  transaction_date DATE,
  ingestion_timestamp TIMESTAMP,
  source_system STRING
)
LOCATION 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/'
TBLPROPERTIES (
  'table_type' = 'ICEBERG',
  'format' = 'parquet',
  'write_compression' = 'snappy'
);

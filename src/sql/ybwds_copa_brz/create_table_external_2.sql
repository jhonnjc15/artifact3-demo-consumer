CREATE EXTERNAL TABLE IF NOT EXISTS db_demo.ybwds_copa_brz_external_2 (
  mandt STRING,
  kunnr STRING,
  matnr STRING,
  nt_wt_kg DOUBLE,
  cost_val_s DOUBLE,
  vkorg STRING
)
PARTITIONED BY (
  ingestion_date STRING
)
ROW FORMAT SERDE
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT
  'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION
  's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/'
TBLPROPERTIES (
  'classification' = 'parquet',
  'table_type' = 'EXTERNAL_TABLE'
);

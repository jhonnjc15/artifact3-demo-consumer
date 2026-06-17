CREATE EXTERNAL TABLE IF NOT EXISTS db_demo_dev.ybwds_copa_brz(
  mandt STRING,
  kunnr STRING,
  matnr STRING,
  nt_wt_kg DOUBLE,
  cost_val_s DOUBLE,
  ingestion_ts TIMESTAMP
)
PARTITIONED BY (ingestion_date STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
TBLPROPERTIES (
  'classification' = 'parquet',
  'UpdatedByJob' = 'prueba-la-br'
);

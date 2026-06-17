CREATE EXTERNAL TABLE IF NOT EXISTS db_demo_dev.ybwds_copa_brz(
  dummy STRING
)
PARTITIONED BY (ingestion_date STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/'
TBLPROPERTIES (
  'projection.enabled' = 'true',
  'projection.ingestion_date.type' = 'date',
  'projection.ingestion_date.range' = '2020-01-01,NOW',
  'projection.ingestion_date.format' = 'yyyy-MM-dd',
  'storage.location.template' = 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/ingestion_date=$\{ingestion_date}/',
  'classification' = 'parquet',
  'table_type' = 'EXTERNAL_TABLE'
);

CREATE EXTERNAL TABLE IF NOT EXISTS comercial_valor_agregado_brz.tabla_prueba_ybwds_copa_brz(
  mandt STRING,
  kunnr STRING,
  matnr STRING,
  nt_wt_kg DOUBLE,
  cost_val_s DOUBLE,
  vkorg STRING,
  vtweg STRING,
  prueba STRING,
  fecha DATE,
  ingestion_ts TIMESTAMP
)
PARTITIONED BY (ingestion_date STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/'
TBLPROPERTIES (
  'classification' = 'parquet',
  'projection.enabled' = 'true',
  'projection.ingestion_date.type' = 'date',
  'projection.ingestion_date.range' = '2020-01-01,NOW',
  'projection.ingestion_date.format' = 'yyyy-MM-dd',
  'storage.location.template' = 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/ingestion_date=${ingestion_date}/',
  'UpdatedByJob' = 'prueba-la-br'
);

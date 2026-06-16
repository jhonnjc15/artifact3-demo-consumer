CREATE EXTERNAL TABLE IF NOT EXISTS db_demo_dev.ybwds_copa_brz(
  mandt           STRING COMMENT 'Mandante SAP',
  vkorg           STRING COMMENT 'Organizacion de ventas',
  vtweg           STRING COMMENT 'Canal de distribucion',
  kunnr           STRING COMMENT 'Cliente',
  matnr           STRING COMMENT 'Material',
  nt_wt_kg        DOUBLE COMMENT 'Peso neto en kg',
  cost_val_s      DOUBLE COMMENT 'Costo',
  net_val_s       DOUBLE COMMENT 'Valor neto',
  ingestion_ts    TIMESTAMP COMMENT 'Marca de tiempo de ingesta'
)
PARTITIONED BY (ingestion_date STRING)
ROW FORMAT SERDE 'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe'
STORED AS INPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat'
OUTPUTFORMAT 'org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat'
LOCATION 's3://bronze-1358-0891-8691/COMERCIAL/ybwds_copa_brz/'
TBLPROPERTIES (
  'classification'='parquet',
  'table_type'='EXTERNAL_TABLE'
);

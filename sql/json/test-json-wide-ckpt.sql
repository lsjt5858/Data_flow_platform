-- Live JSON wide schema streaming test: source -> sink with checkpoints
SET 'execution.checkpointing.interval' = '10 s';

DROP TABLE IF EXISTS json_wide_source;
DROP TABLE IF EXISTS json_wide_sink;

CREATE TABLE json_wide_source (
  id BIGINT,
  age INT,
  name STRING,
  money DECIMAL(16, 3),
  brith DATE,
  map_field MAP<STRING, STRING>,
  array_field ARRAY<STRING>,
  customer_string STRING,
  kong STRING,
  recevi_time TIMESTAMP(3),
  `value` STRING
) WITH (
  'connector' = 'kafka',
  'topic' = 'json-wide-topic',
  'properties.bootstrap.servers' = 'kafka:29092',
  'properties.group.id' = 'flink-json-wide-group',
  'scan.startup.mode' = 'latest-offset',
  'value.format' = 'json',
  'value.json.ignore-parse-errors' = 'true',
  'value.json.timestamp-format.standard' = 'SQL'
);

CREATE TABLE json_wide_sink (
  id BIGINT,
  age INT,
  name STRING,
  money DECIMAL(16, 3),
  brith DATE,
  map_field MAP<STRING, STRING>,
  array_field ARRAY<STRING>,
  customer_string STRING,
  kong STRING,
  recevi_time TIMESTAMP(3),
  `value` STRING
) WITH (
  'connector' = 'kafka',
  'topic' = 'json-wide-sink',
  'properties.bootstrap.servers' = 'kafka:29092',
  'value.format' = 'json'
);

INSERT INTO json_wide_sink SELECT * FROM json_wide_source;


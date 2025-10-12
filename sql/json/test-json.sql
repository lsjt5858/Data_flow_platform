-- Kafka JSON end-to-end test: source -> sink via Flink SQL

DROP TABLE IF EXISTS json_source;
DROP TABLE IF EXISTS json_sink;

-- Kafka JSON source (inside Docker network use kafka:29092)
CREATE TABLE json_source (
  name STRING,
  age INT
) WITH (
  'connector' = 'kafka',
  'topic' = 'json-topic',
  'properties.bootstrap.servers' = 'kafka:29092',
  'properties.group.id' = 'flink-json-consumer-group',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'json',
  'value.json.ignore-parse-errors' = 'true'
);

-- Kafka JSON sink
CREATE TABLE json_sink (
  name STRING,
  age INT
) WITH (
  'connector' = 'kafka',
  'topic' = 'json-sink',
  'properties.bootstrap.servers' = 'kafka:29092',
  'value.format' = 'json'
);

-- Simple pass-through to validate counts in Flink UI
INSERT INTO json_sink SELECT * FROM json_source;


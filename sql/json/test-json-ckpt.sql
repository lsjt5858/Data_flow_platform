-- Enable periodic checkpoints so Kafka offsets are committed
SET 'execution.checkpointing.interval' = '10 s';

DROP TABLE IF EXISTS json_source;
DROP TABLE IF EXISTS json_sink;

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

CREATE TABLE json_sink (
  name STRING,
  age INT
) WITH (
  'connector' = 'kafka',
  'topic' = 'json-sink',
  'properties.bootstrap.servers' = 'kafka:29092',
  'value.format' = 'json'
);

INSERT INTO json_sink SELECT * FROM json_source;


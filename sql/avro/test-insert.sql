DROP TABLE IF EXISTS avro_source;
DROP TABLE IF EXISTS avro_sink;

-- Use Confluent Schema Registry aware format to avoid unsupported option errors
CREATE TABLE avro_source (
  name STRING,
  age INT
) WITH (
  'connector' = 'kafka',
  'topic' = 'avro-topic',
  'properties.bootstrap.servers' = 'kafka:29092',
  'properties.group.id' = 'flink-avro-consumer-group',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081'
);

CREATE TABLE avro_sink (
  name STRING,
  age INT
) WITH (
  'connector' = 'kafka',
  'topic' = 'avro-sink',
  'properties.bootstrap.servers' = 'kafka:29092',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'sink.delivery-guarantee' = 'at-least-once'
);

INSERT INTO avro_sink SELECT * FROM avro_source;

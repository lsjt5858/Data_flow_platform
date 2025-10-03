#!/bin/bash
mkdir -p flink-lib
cd flink-lib

echo "📥 下载 Avro..."
curl -f -s -S -o avro-1.11.3.jar https://repo1.maven.org/maven2/org/apache/avro/avro/1.11.3/avro-1.11.3.jar

echo "📥 下载 Flink Kafka Connector..."
curl -f -s -S -o flink-connector-kafka_2.12-1.15.2.jar https://repo1.maven.org/maven2/org/apache/flink/flink-connector-kafka_2.12/1.15.2/flink-connector-kafka_2.12-1.15.2.jar

echo "📥 下载 Kafka Avro Serializer..."
curl -f -s -S -o kafka-avro-serializer-7.3.0.jar https://packages.confluent.io/maven/io/confluent/kafka-avro-serializer/7.3.0/kafka-avro-serializer-7.3.0.jar

echo "📥 下载 Kafka Schema Registry Client..."
curl -f -s -S -o kafka-schema-registry-client-7.3.0.jar https://packages.confluent.io/maven/io/confluent/kafka-schema-registry-client/7.3.0/kafka-schema-registry-client-7.3.0.jar

echo "✅ 所有 JAR 下载完成！"
ls -lh

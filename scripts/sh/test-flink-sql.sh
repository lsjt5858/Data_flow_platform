#!/bin/bash

echo "🧪 测试 Flink SQL INSERT 操作（gateway 模式 + avro-confluent）..."

# Copy SQL to container and execute (path relative to this script)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
docker exec -i flink-jobmanager bash -c 'cat > /tmp/test.sql' < "$SCRIPT_DIR/../../sql/avro/test-insert.sql"
docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/test.sql

echo ""
echo "✅ 如果看到作业提交成功（Job ID显示），说明Flink SQL已经跑通！"

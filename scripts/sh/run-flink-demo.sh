#!/bin/bash
set -e

echo "=== Flink SQL + Kafka + Avro 完整测试流程 ==="
echo ""

# Step 1: 生成测试数据
echo "📝 Step 1: 生成测试数据到 avro-topic..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
if [ -d "$ROOT_DIR/.venv" ]; then source "$ROOT_DIR/.venv/bin/activate"; fi
python3 "$ROOT_DIR/scripts/python/produce_avro.py"
echo ""

# Step 2: 验证数据已写入
echo "✅ Step 2: 验证avro-topic中的数据..."
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic avro-topic
echo ""

# Step 3: 查看Schema Registry中的schema
echo "📋 Step 3: 查看注册的Avro schema..."
curl -s http://localhost:8081/subjects/avro-topic-value/versions/latest | python3 -m json.tool | grep '"schema"'
echo ""

# Step 4: 运行Flink SQL作业
echo "🚀 Step 4: 提交Flink SQL作业..."
docker exec -i flink-jobmanager bash -c 'cat > /tmp/test.sql' < "$ROOT_DIR/sql/avro/test-insert.sql"
JOB_OUTPUT=$(docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/test.sql 2>&1)
JOB_ID=$(echo "$JOB_OUTPUT" | grep "Job ID:" | awk '{print $NF}')
echo "Job ID: $JOB_ID"
echo ""

# Step 5: 等待并检查作业状态
echo "⏳ Step 5: 等待20秒让作业处理数据..."
sleep 20

echo "📊 Step 6: 检查作业状态和metrics..."
docker exec flink-jobmanager /opt/flink/bin/flink list
echo ""

if [ -n "$JOB_ID" ]; then
    echo "📈 作业 $JOB_ID 的详细metrics:"
    curl -s "http://localhost:8082/jobs/$JOB_ID" | python3 -c "
import json, sys
data = json.load(sys.stdin)
v = data['vertices'][0]
print(f\"  Status: {v['status']}\")
print(f\"  Read records: {v['metrics']['read-records']}\")
print(f\"  Write records: {v['metrics']['write-records']}\")
print(f\"  Read bytes: {v['metrics']['read-bytes']}\")
print(f\"  Write bytes: {v['metrics']['write-bytes']}\")
"
    echo ""
fi

# Step 7: 验证sink数据
echo "🔍 Step 7: 检查avro-sink topic..."
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --describe --topic avro-sink 2>/dev/null || echo "  ❌ avro-sink topic不存在"
echo ""

echo "📦 Step 8: 尝试读取avro-sink中的数据..."
timeout 5 docker exec schema-registry kafka-avro-console-consumer \
    --bootstrap-server kafka:29092 \
    --topic avro-sink \
    --from-beginning \
    --max-messages 5 \
    --property schema.registry.url=http://localhost:8081 2>&1 | grep -E '^\{' || echo "  ⚠️  没有读取到数据"
echo ""

echo "=== 测试完成 ==="
echo ""
echo "💡 查看Flink Web UI: http://localhost:8082"
echo "💡 查看Kafka UI: http://localhost:8080"
echo "💡 如果作业失败,查看日志:"
echo "   docker logs flink-jobmanager --tail 50"
echo "   docker logs flink-taskmanager --tail 50"

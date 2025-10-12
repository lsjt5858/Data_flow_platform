#!/bin/bash
set -euo pipefail

echo "=== Flink SQL + Kafka + JSON end-to-end demo ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo "Step 1: Produce sample JSON records to topic json-topic"
python3 "$ROOT_DIR/scripts/python/produce_json.py" json-topic

echo "Step 2: Show json-topic offsets in Kafka"
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic json-topic || true

echo "Step 3: Submit Flink SQL job (json source -> json sink)"
docker exec -i flink-jobmanager bash -c 'cat > /tmp/test-json.sql' < "$ROOT_DIR/sql/json/test-json.sql"
docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/test-json.sql || true

echo "Step 4: Check json-sink topic existence and offsets"
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep -E '^json-sink$' || echo "json-sink topic not found yet"
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic json-sink || true

echo "Done. Inspect Flink Web UI at http://localhost:8082 for subtask metrics."


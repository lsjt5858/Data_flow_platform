#!/bin/bash
set -euo pipefail

echo "Submitting Flink SQL (json_wide_source -> json_wide_sink with checkpoints)..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

docker exec -i flink-jobmanager bash -c 'cat > /tmp/test-json-wide-ckpt.sql' < "$ROOT_DIR/sql/json/test-json-wide-ckpt.sql"
docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/test-json-wide-ckpt.sql

echo "Submitted. Check Flink UI and Kafka offsets for live metrics."


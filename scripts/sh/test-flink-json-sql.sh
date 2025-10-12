#!/bin/bash
set -euo pipefail

echo "Running Flink SQL for Kafka JSON source->sink..."

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

docker exec -i flink-jobmanager bash -c 'cat > /tmp/test-json.sql' < "$ROOT_DIR/sql/json/test-json.sql"
docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/test-json.sql

echo "If a Job ID is printed above, the SQL was submitted successfully."


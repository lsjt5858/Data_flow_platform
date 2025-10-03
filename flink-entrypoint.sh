#!/bin/bash

# Copy user JARs to lib directory
if [ -d "/opt/flink/usrlib" ]; then
    echo "Copying user JARs from /opt/flink/usrlib to /opt/flink/lib..."
    cp /opt/flink/usrlib/*.jar /opt/flink/lib/ 2>/dev/null || true
    echo "JAR files in /opt/flink/lib:"
    ls -la /opt/flink/lib/*.jar | grep -E "(avro|kafka|schema)" || echo "No user JARs found"
fi

# Execute the original entrypoint
exec /docker-entrypoint.sh "$@"
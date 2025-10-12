"""
Continuous Kafka JSON producer for live Flink metrics testing.

Example:
  python scripts/python/produce_json_stream.py            # topic=json-wide-topic, 500ms interval
  python scripts/python/produce_json_stream.py my-topic 200 --start-id 100

Fields follow the requested schema; "id" auto-increments, and time fields
use current local time on each record.
"""

import json
import sys
import time
import signal
from datetime import datetime
from typing import Dict, Any
from confluent_kafka import Producer


def make_producer(bootstrap: str) -> Producer:
    return Producer(
        {
            "bootstrap.servers": bootstrap,
            "acks": "all",
            "compression.type": "lz4",
            "linger.ms": 5,
        }
    )


def build_record(i: int) -> Dict[str, Any]:
    now_ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    return {
        "id": i,
        "age": 12,
        "name": "xionger",
        "money": 1223.233,
        "brith": "2023-01-05",
        "map_field": {"key1": "value1", "key2": "value2"},
        "array_field": ["单个string"],
        "customer_string": "customer_string",
        "kong": "",
        "recevi_time": now_ts,
        "value": "morenzhi",
    }


def main() -> None:
    topic = sys.argv[1] if len(sys.argv) > 1 else "json-wide-topic"
    interval_ms_str = sys.argv[2] if len(sys.argv) > 2 else "500"
    interval_ms = max(1, int(float(interval_ms_str)))

    start_id = 1
    bootstrap = "localhost:9092"
    for idx, arg in enumerate(sys.argv[3:], start=3):
        if arg == "--start-id" and idx + 1 < len(sys.argv):
            start_id = int(sys.argv[idx + 1])
        if arg == "--bootstrap" and idx + 1 < len(sys.argv):
            bootstrap = sys.argv[idx + 1]

    stop = False

    def _sigint(_sig, _frame):
        nonlocal stop
        stop = True
        print("\nStopping producer...")

    signal.signal(signal.SIGINT, _sigint)
    signal.signal(signal.SIGTERM, _sigint)

    producer = make_producer(bootstrap)

    i = start_id
    sent = 0
    print(
        f"Producing to topic={topic} bootstrap={bootstrap} interval={interval_ms}ms starting_id={start_id} ..."
    )
    try:
        while not stop:
            record = build_record(i)
            payload = json.dumps(record, ensure_ascii=False, separators=(",", ":")).encode(
                "utf-8"
            )
            key = str(i).encode("utf-8")
            try:
                producer.produce(topic, key=key, value=payload)
            except BufferError:
                producer.poll(0)
                producer.produce(topic, key=key, value=payload)

            producer.poll(0)
            i += 1
            sent += 1
            if sent % 1000 == 0:
                print(f"sent={sent} last_id={i-1}")
            time.sleep(interval_ms / 1000.0)
    finally:
        producer.flush(5)
        print(f"Flushed. total_sent={sent}")


if __name__ == "__main__":
    main()


"""
Simple JSON consumer for Kafka using confluent-kafka.

Usage:
  python scripts/python/consume_json.py [topic] [group_id]

Defaults:
  topic: json-topic
  group_id: json-consumer-group
"""

import sys
import json
from typing import Optional
from confluent_kafka import Consumer


def make_consumer(group_id: str) -> Consumer:
    conf = {
        "bootstrap.servers": "localhost:9092",
        "group.id": group_id,
        "enable.auto.commit": True,
        "auto.offset.reset": "earliest",
        "max.poll.interval.ms": 300000,
    }
    return Consumer(conf)


def main() -> None:
    topic: str = sys.argv[1] if len(sys.argv) > 1 else "json-topic"
    group_id: str = sys.argv[2] if len(sys.argv) > 2 else "json-consumer-group"

    consumer = make_consumer(group_id)
    consumer.subscribe([topic])

    print(f"Starting JSON consumer. topic={topic} group={group_id} ... Press Ctrl+C to stop")
    try:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                print(f"Consumer error: {msg.error()}")
                continue
            try:
                value_str = msg.value().decode("utf-8") if msg.value() is not None else None
                value_obj: Optional[dict] = json.loads(value_str) if value_str else None
            except Exception as e:
                print(f"JSON decode failed: {e}; raw={msg.value()!r}")
                continue

            print(
                f"key={msg.key()} value={value_obj} topic={msg.topic()} partition={msg.partition()} offset={msg.offset()}"
            )
    except KeyboardInterrupt:
        print("\nStopping consumer...")
    finally:
        consumer.close()


if __name__ == "__main__":
    main()


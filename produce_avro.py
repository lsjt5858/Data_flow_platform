# save as produce_avro.py
from confluent_kafka.avro import AvroProducer
import json

# Avro schema definition
value_schema_str = """
{
  "type": "record",
  "name": "User",
  "fields": [
    {"name": "name", "type": "string"},
    {"name": "age", "type": "int"}
  ]
}
"""

key_schema_str = """
{
  "type": "string"
}
"""

def delivery_callback(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}]')

def main():
    # Producer configuration
    producer_config = {
        'bootstrap.servers': 'localhost:9092',
        'schema.registry.url': 'http://localhost:8081'
    }
    
    producer = AvroProducer(
        producer_config,
        default_key_schema=key_schema_str,
        default_value_schema=value_schema_str
    )
    
    # Sample data
    users = [
        {'name': 'Alice', 'age': 30},
        {'name': 'Bob', 'age': 25},
        {'name': 'Charlie', 'age': 35}
    ]
    
    try:
        for user in users:
            producer.produce(
                topic='avro-topic',
                key=user['name'],
                value=user,
                callback=delivery_callback
            )
        
        # Wait for all messages to be delivered
        producer.flush()
        print("All messages sent successfully!")
        
    except Exception as e:
        print(f"Error producing messages: {e}")

if __name__ == "__main__":
    main()
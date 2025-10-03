# save as consume_avro.py
from confluent_kafka.avro import AvroConsumer

def main():
    # Consumer configuration
    consumer_config = {
        'bootstrap.servers': 'localhost:9092',
        'group.id': 'avro-consumer-group',
        'auto.offset.reset': 'earliest',
        'schema.registry.url': 'http://localhost:8081'
    }
    
    consumer = AvroConsumer(consumer_config)
    consumer.subscribe(['avro-topic'])
    
    try:
        print("Starting consumer... Press Ctrl+C to stop")
        while True:
            msg = consumer.poll(1.0)
            
            if msg is None:
                continue
            if msg.error():
                print(f"Consumer error: {msg.error()}")
                continue
                
            print(f"Received message: key={msg.key()}, value={msg.value()}")
            
    except KeyboardInterrupt:
        print("\nStopping consumer...")
    finally:
        consumer.close()

if __name__ == "__main__":
    main()
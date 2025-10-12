from confluent_kafka import Producer
import json

def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f'Message delivered to {msg.topic()} [{msg.partition()}]')

producer_config = {
    'bootstrap.servers': 'localhost:9092',
}

producer = Producer(producer_config)

# 发送JSON数据
users = [
    {'name': 'Alice', 'age': 30},
    {'name': 'Bob', 'age': 25},
    {'name': 'Charlie', 'age': 35}
]

for user in users:
    json_str = json.dumps(user)
    producer.produce(
        'json-topic',
        value=json_str.encode('utf-8'),
        callback=delivery_report
    )

producer.flush()
print('All messages sent successfully!')

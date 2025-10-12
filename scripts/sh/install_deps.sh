#!/bin/bash

echo "Installing Kafka Avro dependencies..."

# Activate virtual environment
source .venv/bin/activate

# Uninstall existing confluent-kafka if present
pip uninstall -y confluent-kafka

# Install confluent-kafka with avro support (includes compatible avro and fastavro)
pip install 'confluent-kafka[avro]==2.3.0'

echo "Installation complete!"
echo "You can now run: python3 produce_avro.py"
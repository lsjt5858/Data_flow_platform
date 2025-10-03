# Flink SQL + Kafka + Avro 测试环境

这是一个完整的 Flink SQL + Kafka + Schema Registry + Avro 测试环境，用于学习和测试流式数据处理。

## 📋 目录结构

```
kafka-test-env/
├── README.md                    # 本文档
├── docker-compose.yml          # Docker 服务编排文件
├── flink-entrypoint.sh         # Flink 容器启动脚本
├── flink-lib/                  # Flink 依赖 JAR 包目录
│   ├── avro-1.11.3.jar
│   ├── flink-avro-1.15.2.jar
│   ├── flink-avro-confluent-registry-1.15.2.jar
│   ├── flink-sql-avro-1.15.2.jar
│   ├── flink-sql-connector-kafka-1.15.2.jar
│   ├── kafka-clients-3.3.1.jar
│   ├── kafka-avro-serializer-7.3.0.jar
│   └── ... (其他依赖)
├── test-insert.sql             # Flink SQL 脚本 (Avro 格式)
├── test-flink-sql.sh           # Flink SQL 执行脚本
├── run-flink-demo.sh           # 完整演示脚本
├── produce_avro.py             # Avro 数据生成器
├── produce_json.py             # JSON 数据生成器
├── consume_avro.py             # Avro 数据消费者
├── install_deps.sh             # Python 依赖安装脚本
├── setup-jars.sh               # JAR 包下载脚本
├── checkpoints/                # Flink checkpoint 目录
└── savepoints/                 # Flink savepoint 目录
```

## 🚀 快速开始

### 1. 启动所有服务

```bash
docker-compose up -d
```

服务包括：
- **Zookeeper** (端口 2181)
- **Kafka** (端口 9092)
- **Schema Registry** (端口 8081)
- **Kafka UI** (端口 8080)
- **Flink JobManager** (端口 8082)
- **Flink TaskManager**

### 2. 检查服务状态

```bash
docker ps
```

所有容器应该都是 `Up` 状态。

### 3. 运行完整演示

```bash
./run-flink-demo.sh
```

这会自动完成：
- 生成测试数据到 Kafka
- 提交 Flink SQL 作业
- 验证数据流转
- 显示结果

## 📝 手动步骤详解

### Step 1: 准备 Python 环境

```bash
# 创建虚拟环境（首次运行）
python3 -m venv .venv

# 激活虚拟环境
source .venv/bin/activate

# 安装依赖（首次运行）
./install_deps.sh
# 或手动安装
pip install confluent-kafka avro-python3
```

### Step 2: 生成测试数据

**方式 1: Avro 格式（推荐）**
```bash
source .venv/bin/activate
python produce_avro.py
```

**方式 2: JSON 格式**
```bash
source .venv/bin/activate
python produce_json.py
```

### Step 3: 验证数据已写入

```bash
# 查看 Kafka topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# 验证 Avro 数据
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic avro-topic \
  --from-beginning \
  --max-messages 3 \
  --property schema.registry.url=http://localhost:8081

# 输出应该是：
# {"name":"Alice","age":30}
# {"name":"Bob","age":25}
# {"name":"Charlie","age":35}
```

### Step 4: 运行 Flink SQL 作业

```bash
./test-flink-sql.sh
```

这会执行 `test-insert.sql` 中的 SQL：
- 创建 source 表（从 `avro-topic` 读取）
- 创建 sink 表（写入 `avro-sink`）
- 执行 `INSERT INTO avro_sink SELECT * FROM avro_source`

### Step 5: 验证结果

**方式 1: 查看 Flink Web UI**
```bash
# 打开浏览器访问
open http://localhost:8082
```
- 点击 "Running Jobs" 查看作业状态
- 应该看到作业处于 RUNNING 状态

**方式 2: 查看 sink topic 数据**
```bash
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic avro-sink \
  --from-beginning \
  --max-messages 10 \
  --property schema.registry.url=http://localhost:8081
```

输出示例：
```json
{"name":{"string":"Alice"},"age":{"int":30}}
{"name":{"string":"Bob"},"age":{"int":25}}
{"name":{"string":"Charlie"},"age":{"int":35}}
```

**方式 3: 查看 Flink 作业列表**
```bash
docker exec flink-jobmanager /opt/flink/bin/flink list
```

**方式 4: 查看 TaskManager 日志（用于 print sink）**
```bash
docker logs flink-taskmanager --tail 50 | grep "+I\["
```

## 🔧 自定义数据流转

### 创建自己的数据生成器

**示例 1: 自定义 Avro 数据**

```python
from confluent_kafka.avro import AvroProducer

# 定义 schema
value_schema_str = """
{
  "type": "record",
  "name": "Product",
  "fields": [
    {"name": "product_id", "type": "int"},
    {"name": "product_name", "type": "string"},
    {"name": "price", "type": "double"}
  ]
}
"""

producer_config = {
    'bootstrap.servers': 'localhost:9092',
    'schema.registry.url': 'http://localhost:8081'
}

producer = AvroProducer(
    producer_config,
    default_value_schema=avro.loads(value_schema_str)
)

# 发送数据
products = [
    {'product_id': 1, 'product_name': 'Laptop', 'price': 999.99},
    {'product_id': 2, 'product_name': 'Mouse', 'price': 29.99},
]

for product in products:
    producer.produce(topic='product-topic', value=product)

producer.flush()
```

**示例 2: 自定义 JSON 数据**

```python
from confluent_kafka import Producer
import json

producer = Producer({'bootstrap.servers': 'localhost:9092'})

orders = [
    {'order_id': 1, 'customer': 'Alice', 'amount': 100.0},
    {'order_id': 2, 'customer': 'Bob', 'amount': 200.0},
]

for order in orders:
    producer.produce(
        'order-topic',
        value=json.dumps(order).encode('utf-8')
    )

producer.flush()
```

### 创建自定义 Flink SQL

**示例: 创建 `my-pipeline.sql`**

```sql
-- 清理旧表
DROP TABLE IF EXISTS my_source;
DROP TABLE IF EXISTS my_sink;

-- 创建 Source 表
CREATE TABLE my_source (
  product_id INT,
  product_name STRING,
  price DOUBLE
) WITH (
  'connector' = 'kafka',
  'topic' = 'product-topic',
  'properties.bootstrap.servers' = 'kafka:29092',
  'properties.group.id' = 'flink-product-group',
  'scan.startup.mode' = 'earliest-offset',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081'
);

-- 创建 Sink 表
CREATE TABLE my_sink (
  product_id INT,
  product_name STRING,
  price DOUBLE
) WITH (
  'connector' = 'kafka',
  'topic' = 'product-sink',
  'properties.bootstrap.servers' = 'kafka:29092',
  'value.format' = 'avro-confluent',
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081',
  'sink.delivery-guarantee' = 'at-least-once'
);

-- 执行数据转换和写入
INSERT INTO my_sink
SELECT
  product_id,
  product_name,
  price * 0.9 as price  -- 打9折
FROM my_source
WHERE price > 50;  -- 只处理价格大于50的商品
```

**运行自定义 SQL:**

```bash
# 复制到容器
docker exec -i flink-jobmanager bash -c 'cat > /tmp/my-pipeline.sql' < my-pipeline.sql

# 执行
docker exec flink-jobmanager /opt/flink/bin/sql-client.sh -f /tmp/my-pipeline.sql
```

## ⚠️ 重要注意事项

### 1. 数据格式选择

**Avro (推荐用于生产环境)**
- ✅ Schema 强类型验证
- ✅ 二进制格式，存储高效
- ✅ Schema 演进支持
- ❌ 需要 Schema Registry
- ❌ 调试相对复杂

**JSON (推荐用于开发测试)**
- ✅ 易读易调试
- ✅ 不需要 Schema Registry
- ❌ 无类型验证
- ❌ 存储效率低

### 2. Flink SQL 配置要点

**Avro + Schema Registry 配置：**
```sql
WITH (
  'value.format' = 'avro-confluent',  -- 必须使用 avro-confluent 格式
  'value.avro-confluent.schema-registry.url' = 'http://schema-registry:8081'
)
```

**JSON 配置：**
```sql
WITH (
  'format' = 'json'  -- 简单的 JSON 格式
)
```

**Sink 可靠性配置：**
```sql
WITH (
  'sink.delivery-guarantee' = 'at-least-once'  -- 推荐，避免事务超时
  -- 或
  'sink.delivery-guarantee' = 'exactly-once'   -- 需要 Kafka 事务支持
)
```

### 3. 常见问题排查

**问题 1: 作业状态 RUNNING 但无数据流转**

检查步骤：
```bash
# 1. 查看 TaskManager 日志
docker logs flink-taskmanager --tail 100

# 2. 检查 source topic 是否有数据
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic avro-topic

# 3. 验证 Schema Registry 连接
curl http://localhost:8081/subjects
```

**问题 2: ClassNotFoundException**

确认 JAR 包已加载：
```bash
docker exec flink-jobmanager ls -lh /opt/flink/lib/ | grep -E "avro|kafka"
```

如果缺少 JAR 包，重启 Flink 容器：
```bash
docker restart flink-jobmanager flink-taskmanager
```

**问题 3: 事务超时 (exactly-once)**

修改为 at-least-once：
```sql
'sink.delivery-guarantee' = 'at-least-once'
```

### 4. 性能监控

**Flink Web UI** (http://localhost:8082)
- 查看作业运行状态
- 监控 checkpoint
- 查看 backpressure

**Kafka UI** (http://localhost:8080)
- 查看 topic 列表
- 监控消息积压
- 查看 consumer group lag

## 🔍 验证数据流转的检查点

### 必查项目：

1. **Source Topic 有数据**
   ```bash
   docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
     --broker-list localhost:9092 --topic avro-topic
   # 应该显示: avro-topic:0:3 (表示有3条消息)
   ```

2. **Schema Registry 有注册**
   ```bash
   curl http://localhost:8081/subjects
   # 应该返回: ["avro-topic-value", "avro-sink-value"]
   ```

3. **Flink 作业运行中**
   ```bash
   docker exec flink-jobmanager /opt/flink/bin/flink list
   # 应该看到 RUNNING 状态的作业
   ```

4. **TaskManager 有输出日志**
   ```bash
   docker logs flink-taskmanager --tail 50
   # 应该看到消息处理日志
   ```

5. **Sink Topic 有数据写入**
   ```bash
   docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
     --broker-list localhost:9092 --topic avro-sink
   # 应该显示有消息的 offset
   ```

### 端到端验证命令：

```bash
# 完整验证流程
echo "1. 生成数据..."
source .venv/bin/activate && python produce_avro.py

echo "2. 验证 source..."
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 --topic avro-topic \
  --from-beginning --max-messages 3 \
  --property schema.registry.url=http://localhost:8081

echo "3. 提交 Flink 作业..."
./test-flink-sql.sh

echo "4. 等待20秒..."
sleep 20

echo "5. 验证 sink..."
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 --topic avro-sink \
  --from-beginning --max-messages 10 \
  --property schema.registry.url=http://localhost:8081
```

## 🛠️ 工具命令速查

### Kafka 操作

```bash
# 列出所有 topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list

# 创建 topic
docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
  --create --topic my-topic --partitions 1 --replication-factor 1

# 删除 topic
docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
  --delete --topic my-topic

# 查看 topic 详情
docker exec kafka kafka-topics --bootstrap-server localhost:9092 \
  --describe --topic avro-topic

# 查看 consumer group
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list

# 查看 consumer group 详情
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group flink-avro-consumer-group
```

### Flink 操作

```bash
# 查看运行中的作业
docker exec flink-jobmanager /opt/flink/bin/flink list

# 查看所有作业（包括已完成）
docker exec flink-jobmanager /opt/flink/bin/flink list -a

# 取消作业
docker exec flink-jobmanager /opt/flink/bin/flink cancel <JOB_ID>

# 查看作业详情
curl http://localhost:8082/jobs/<JOB_ID>

# 进入 SQL 客户端（交互模式）
docker exec -it flink-jobmanager /opt/flink/bin/sql-client.sh
```

### Schema Registry 操作

```bash
# 查看所有 subjects
curl http://localhost:8081/subjects

# 查看 schema 详情
curl http://localhost:8081/subjects/avro-topic-value/versions/latest | python3 -m json.tool

# 删除 subject
curl -X DELETE http://localhost:8081/subjects/avro-topic-value
```

## 🧹 清理和重置

### 清理所有数据

```bash
# 停止所有服务
docker-compose down

# 删除所有数据（包括 Kafka 数据和 Flink 状态）
docker-compose down -v

# 重新启动
docker-compose up -d
```

### 仅清理 Kafka 数据

```bash
# 删除所有 topics
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | \
  grep -v "__consumer_offsets\|_schemas" | \
  xargs -I {} docker exec kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic {}
```

### 仅重启 Flink

```bash
docker restart flink-jobmanager flink-taskmanager
```

## 📚 参考资源

- [Apache Flink 官方文档](https://flink.apache.org/docs/stable/)
- [Flink SQL 连接器文档](https://nightlies.apache.org/flink/flink-docs-stable/docs/connectors/table/kafka/)
- [Confluent Schema Registry](https://docs.confluent.io/platform/current/schema-registry/index.html)
- [Avro 规范](https://avro.apache.org/docs/current/spec.html)

## 🎓 学习路径建议

1. **入门**：先用 JSON 格式熟悉整个流程
2. **进阶**：学习 Avro + Schema Registry
3. **实战**：尝试数据转换（WHERE、JOIN、聚合）
4. **优化**：学习 checkpoint、watermark、窗口函数

## ⚡ 常用场景示例

### 场景 1: 数据过滤

```sql
INSERT INTO filtered_sink
SELECT * FROM source
WHERE age > 25;
```

### 场景 2: 数据转换

```sql
INSERT INTO transformed_sink
SELECT
  UPPER(name) as name,
  age * 2 as double_age
FROM source;
```

### 场景 3: 数据聚合（需要时间属性）

```sql
-- 注意：需要在表中定义 watermark
SELECT
  name,
  COUNT(*) as cnt,
  SUM(age) as total_age
FROM source
GROUP BY name;
```

## 💡 最佳实践

1. **开发阶段**：使用 JSON 格式 + print sink，快速调试
2. **测试阶段**：使用 Avro 格式，验证 schema 兼容性
3. **生产环境**：使用 Avro + exactly-once + checkpoint
4. **监控告警**：配置 Flink metrics 导出到监控系统
5. **错误处理**：配置合适的重启策略

## 📞 问题反馈

如遇到问题，请检查：
1. Docker 容器是否都在运行
2. 日志中是否有错误信息
3. JAR 包是否完整加载
4. 网络连接是否正常

---

**祝你玩得开心！🚀**

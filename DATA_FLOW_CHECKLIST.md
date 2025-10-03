# ✅ 数据流转检查清单

当你自己造数据并运行 Flink SQL 时，按照这个清单逐一检查，确保数据能成功流转。

---

## 📋 前置检查（运行前）

### ☑️ 1. 环境检查
```bash
# 所有容器都在运行
docker ps | grep -E "kafka|zookeeper|schema-registry|flink"
```
**预期结果**：6个容器都是 `Up` 状态

---

### ☑️ 2. Python 环境检查
```bash
source .venv/bin/activate
python -c "import confluent_kafka, avro; print('✅ OK')"
```
**预期结果**：显示 `✅ OK`

如果失败，运行：
```bash
./install_deps.sh
```

---

## 📤 数据生成检查

### ☑️ 3. 生成数据成功
```bash
source .venv/bin/activate
python produce_avro.py
```
**预期结果**：
```
Message delivered to avro-topic [0]
Message delivered to avro-topic [0]
Message delivered to avro-topic [0]
All messages sent successfully!
```

---

### ☑️ 4. Topic 已创建
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep avro-topic
```
**预期结果**：显示 `avro-topic`

---

### ☑️ 5. 数据已写入 Kafka
```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic avro-topic
```
**预期结果**：`avro-topic:0:3` (表示有3条消息，数字可能不同)

---

### ☑️ 6. Schema 已注册到 Registry
```bash
curl -s http://localhost:8081/subjects | python3 -m json.tool
```
**预期结果**：包含 `"avro-topic-value"`

---

### ☑️ 7. 数据可以正常读取
```bash
timeout 10 docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic avro-topic \
  --from-beginning \
  --max-messages 3 \
  --property schema.registry.url=http://localhost:8081 2>&1 | grep "^{"
```
**预期结果**：显示 JSON 格式的数据
```json
{"name":"Alice","age":30}
{"name":"Bob","age":25}
{"name":"Charlie","age":35}
```

---

## 🔄 Flink SQL 执行检查

### ☑️ 8. SQL 脚本语法正确
```bash
# 查看 SQL 文件内容
cat test-insert.sql
```
**检查要点**：
- ✅ Source 表的 topic 名称正确（`avro-topic`）
- ✅ Sink 表的 topic 名称正确（`avro-sink`）
- ✅ Schema Registry URL 正确（`http://schema-registry:8081`）
- ✅ 字段类型匹配（name STRING, age INT）

---

### ☑️ 9. SQL 执行成功
```bash
./test-flink-sql.sh
```
**预期结果**：显示 `Job ID: xxxxxxxxxxxx`

**❌ 如果失败**，检查：
- Flink 容器是否正常运行
- JAR 包是否加载（见下一步）

---

### ☑️ 10. Flink JAR 包已加载
```bash
docker exec flink-jobmanager ls /opt/flink/lib/ | grep -E "avro|kafka"
```
**预期结果**：至少显示以下 JAR：
```
avro-1.11.3.jar
flink-avro-1.15.2.jar
flink-avro-confluent-registry-1.15.2.jar
flink-sql-avro-1.15.2.jar
flink-sql-connector-kafka-1.15.2.jar
kafka-avro-serializer-7.3.0.jar
kafka-clients-3.3.1.jar
kafka-schema-registry-client-7.3.0.jar
```

**❌ 如果缺少 JAR**：
```bash
docker restart flink-jobmanager flink-taskmanager
sleep 10
```

---

## 🎯 作业运行检查

### ☑️ 11. 作业状态为 RUNNING
```bash
docker exec flink-jobmanager /opt/flink/bin/flink list
```
**预期结果**：
```
Running/Restarting Jobs
01.10.2025 16:38:32 : xxxx : insert-into_default_catalog.default_database.avro_sink (RUNNING)
```

**❌ 如果是 FAILED**：
```bash
# 查看错误日志
docker logs flink-jobmanager --tail 50
docker logs flink-taskmanager --tail 50
```

---

### ☑️ 12. TaskManager 有数据处理日志
```bash
docker logs flink-taskmanager --tail 50 | grep -E "\+I\[|Subscribed to partition"
```
**预期结果**：显示类似：
```
INFO  org.apache.flink.kafka.shaded.org.apache.kafka.clients.consumer.KafkaConsumer [] - [Consumer clientId=flink-avro-consumer-group-0, groupId=flink-avro-consumer-group] Subscribed to partition(s): avro-topic-0
```

---

### ☑️ 13. Consumer Group 已创建并消费
```bash
docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 \
  --describe --group flink-avro-consumer-group 2>&1
```
**预期结果**：显示 offset 信息（如果已经消费）

**注意**：可能显示 "Consumer group does not exist" 是正常的（Flink 可能还没提交 offset）

---

## 📥 结果验证检查

### ☑️ 14. Sink Topic 已创建
```bash
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --list | grep avro-sink
```
**预期结果**：显示 `avro-sink`

---

### ☑️ 15. Sink Topic 有数据
```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell \
  --broker-list localhost:9092 --topic avro-sink
```
**预期结果**：`avro-sink:0:N` (N > 0，表示有数据)

**❌ 如果 N = 0**：
- 等待更长时间（可能需要30秒）
- 检查 TaskManager 日志是否有错误

---

### ☑️ 16. Sink Schema 已注册
```bash
curl -s http://localhost:8081/subjects | grep avro-sink-value
```
**预期结果**：显示 `avro-sink-value`

---

### ☑️ 17. 最终数据验证 ⭐
```bash
timeout 15 docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic avro-sink \
  --from-beginning \
  --max-messages 5 \
  --property schema.registry.url=http://localhost:8081 2>&1 | grep "^{"
```
**预期结果**：显示转换后的数据
```json
{"name":{"string":"Alice"},"age":{"int":30}}
{"name":{"string":"Bob"},"age":{"int":25}}
{"name":{"string":"Charlie"},"age":{"int":35}}
```

---

## 🎉 成功标准

如果以上17个检查都通过，说明你的数据流转**完全成功**！

---

## 🚨 常见失败原因及解决方案

### 问题 1: 作业状态 RUNNING 但无数据流转

**可能原因**：
1. ⏰ 等待时间不够（需要20-30秒）
2. 🔌 Kafka 连接配置错误
3. 📝 Schema 不匹配

**解决方案**：
```bash
# 1. 等待更长时间
sleep 30

# 2. 检查 Flink 到 Kafka 的连接
docker exec flink-jobmanager ping -c 3 kafka

# 3. 检查 Schema Registry 连接
docker exec flink-jobmanager curl http://schema-registry:8081/subjects
```

---

### 问题 2: ClassNotFoundException

**可能原因**：JAR 包未加载

**解决方案**：
```bash
# 重启 Flink 容器
docker restart flink-jobmanager flink-taskmanager

# 等待30秒
sleep 30

# 验证 JAR
docker exec flink-jobmanager ls /opt/flink/lib/ | grep avro-confluent
```

---

### 问题 3: Schema Registry 错误

**可能原因**：
1. Schema Registry 未启动
2. Schema 不兼容

**解决方案**：
```bash
# 1. 检查 Schema Registry 状态
docker logs schema-registry --tail 50

# 2. 查看已注册的 schemas
curl http://localhost:8081/subjects

# 3. 删除旧 schema 重新注册
curl -X DELETE http://localhost:8081/subjects/avro-topic-value
curl -X DELETE http://localhost:8081/subjects/avro-sink-value

# 重新生成数据
source .venv/bin/activate && python produce_avro.py
```

---

### 问题 4: 事务超时

**症状**：日志中显示 `TimeoutException: Timeout expired while awaiting InitProducerId`

**解决方案**：修改 `test-insert.sql`，将 sink 配置改为：
```sql
'sink.delivery-guarantee' = 'at-least-once'  -- 而不是 exactly-once
```

---

## 📊 监控要点

### 实时监控命令

```bash
# 1. 持续监控 TaskManager 日志
docker logs -f flink-taskmanager

# 2. 监控作业状态
watch -n 5 'docker exec flink-jobmanager /opt/flink/bin/flink list'

# 3. 监控 Kafka lag
watch -n 5 'docker exec kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group flink-avro-consumer-group'
```

### Flink Web UI 监控点

访问 http://localhost:8082，查看：
- ✅ Job Status = RUNNING
- ✅ Uptime > 30s
- ✅ No Failed Tasks
- ✅ Checkpoint Success

---

## 💡 最佳实践

1. **先用简单的 JSON 格式测试**，确保流程通了再用 Avro
2. **每次修改 SQL 后重启作业**（取消旧作业）
3. **清理测试数据**，避免混淆结果
4. **保存日志**，方便问题排查
5. **小步快跑**，每次只改一个配置

---

## 🔄 完整重置流程

如果遇到问题无法解决，可以完全重置：

```bash
# 1. 停止所有服务
docker-compose down

# 2. 清理所有数据（包括 Kafka 和 Flink 状态）
docker-compose down -v

# 3. 重新启动
docker-compose up -d

# 4. 等待服务就绪
sleep 30

# 5. 重新运行测试
source .venv/bin/activate
python produce_avro.py
./test-flink-sql.sh
```

---

**记住**：数据流转是一个链条，任何一环出问题都会导致失败。按照这个清单逐步检查，能快速定位问题！🎯

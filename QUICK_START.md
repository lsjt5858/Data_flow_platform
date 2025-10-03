# ⚡ 快速开始指南

## 5分钟跑通第一个示例

### 1️⃣ 启动环境 (30秒)
```bash
docker-compose up -d
```

### 2️⃣ 生成测试数据 (10秒)
```bash
source .venv/bin/activate
python produce_avro.py
```

### 3️⃣ 运行 Flink SQL (10秒)
```bash
./test-flink-sql.sh
```

### 4️⃣ 验证结果 (10秒)
```bash
# 等待20秒让数据流转
sleep 20

# 查看结果
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic avro-sink \
  --from-beginning \
  --max-messages 5 \
  --property schema.registry.url=http://localhost:8081
```

**预期输出：**
```json
{"name":{"string":"Alice"},"age":{"int":30}}
{"name":{"string":"Bob"},"age":{"int":25}}
{"name":{"string":"Charlie"},"age":{"int":35}}
```

✅ **成功！** 你已经完成了第一个 Flink SQL + Kafka + Avro 流式处理作业！

---

## 📊 监控面板

打开浏览器访问：

- **Flink Web UI**: http://localhost:8082
  - 查看作业状态、metrics、日志

- **Kafka UI**: http://localhost:8080
  - 查看 topics、消息、consumer groups

---

## 🎯 自定义数据流程

### 步骤 1: 修改数据生成器

编辑 `produce_avro.py`，修改数据：

```python
users = [
    {'name': 'YourName', 'age': 25},  # 改成你的数据
    {'name': 'Friend', 'age': 30},
]
```

### 步骤 2: 修改 SQL 逻辑

编辑 `test-insert.sql`，添加过滤条件：

```sql
INSERT INTO avro_sink
SELECT * FROM avro_source
WHERE age > 25;  -- 只要年龄大于25的
```

### 步骤 3: 重新运行

```bash
# 删除旧数据
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic avro-topic
docker exec kafka kafka-topics --bootstrap-server localhost:9092 --delete --topic avro-sink

# 重新生成和运行
source .venv/bin/activate && python produce_avro.py
./test-flink-sql.sh
```

---

## 🚨 常见问题

### Q: 作业提交后没有数据？
A: 等待20-30秒，Flink 需要时间初始化

### Q: 如何查看详细日志？
```bash
docker logs flink-taskmanager --tail 50
docker logs flink-jobmanager --tail 50
```

### Q: 如何重置所有数据？
```bash
docker-compose down -v
docker-compose up -d
```

### Q: 如何停止 Flink 作业？
```bash
# 查看作业ID
docker exec flink-jobmanager /opt/flink/bin/flink list

# 取消作业
docker exec flink-jobmanager /opt/flink/bin/flink cancel <JOB_ID>
```

---

## 📚 下一步学习

1. ✅ 完成快速开始 ← **你在这里**
2. 📖 阅读 `README.md` 了解详细说明
3. 🔍 查看 `PROJECT_STRUCTURE.md` 了解文件结构
4. 🎓 尝试修改 SQL 实现数据过滤和转换
5. 💪 创建自己的数据处理 pipeline

---

**需要帮助？** 查看 `README.md` 中的完整文档！

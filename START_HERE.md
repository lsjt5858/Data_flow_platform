# 🎯 从这里开始

欢迎使用 Flink SQL + Kafka + Avro 测试环境！

---

## 📚 文档导航

### 👉 我是新手，第一次使用
**阅读顺序**：
1. 📖 [QUICK_START.md](./QUICK_START.md) - 5分钟快速上手
2. 📘 [README.md](./README.md) - 完整使用指南
3. 📋 [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) - 了解项目结构

### 👉 我遇到了问题
**查看**：
- ✅ [DATA_FLOW_CHECKLIST.md](./DATA_FLOW_CHECKLIST.md) - 数据流转检查清单

### 👉 我想自定义数据处理
**参考**：
- 📘 [README.md](./README.md) - 查看"自定义数据流转"章节
- 📄 示例文件：`produce_avro.py`, `test-insert.sql`

### 👉 我只想快速查命令
**查看**：
- 📘 [README.md](./README.md) - 查看"工具命令速查"章节

---

## ⚡ 最快上手方式

```bash
# 1. 启动环境
docker-compose up -d

# 2. 一键运行演示
./run-flink-demo.sh

# 3. 查看 Flink Web UI
open http://localhost:8082
```

**就这么简单！** 🎉

---

## 🗂️ 文件说明速查

| 如果你想... | 应该查看 |
|------------|---------|
| 🚀 **快速开始** | [QUICK_START.md](./QUICK_START.md) |
| 📖 **详细学习** | [README.md](./README.md) |
| 🔍 **了解文件** | [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) |
| 🐛 **排查问题** | [DATA_FLOW_CHECKLIST.md](./DATA_FLOW_CHECKLIST.md) |
| 🔧 **修改数据** | `produce_avro.py` |
| 📝 **修改SQL** | `test-insert.sql` |
| ⚙️ **执行SQL** | `test-flink-sql.sh` |

---

## 🎓 学习路径建议

### 第1天：入门
- ✅ 完成 [QUICK_START.md](./QUICK_START.md)
- ✅ 理解数据流转过程
- ✅ 查看 Flink Web UI

### 第2天：实践
- ✅ 修改 `produce_avro.py` 生成自己的数据
- ✅ 修改 `test-insert.sql` 添加过滤条件
- ✅ 验证结果

### 第3天：进阶
- ✅ 学习 [README.md](./README.md) 中的高级功能
- ✅ 尝试数据转换和聚合
- ✅ 理解 Avro Schema 演进

---

## ❓ 常见问题

### Q: 我应该先看哪个文档？
**A**: 先看 [QUICK_START.md](./QUICK_START.md)，5分钟跑通示例后再看其他文档。

### Q: 文档太长了，我只想快速解决问题
**A**: 直接查看 [DATA_FLOW_CHECKLIST.md](./DATA_FLOW_CHECKLIST.md)，按照检查清单逐一排查。

### Q: 我不知道某个文件是做什么的
**A**: 查看 [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)，里面有每个文件的详细说明。

### Q: 我想学习更多 Flink SQL 功能
**A**: [README.md](./README.md) 的"常用场景示例"章节有详细说明。

---

## 🆘 获取帮助

如果遇到问题：

1. **查看日志**
   ```bash
   docker logs flink-taskmanager --tail 50
   docker logs flink-jobmanager --tail 50
   ```

2. **使用检查清单**
   按照 [DATA_FLOW_CHECKLIST.md](./DATA_FLOW_CHECKLIST.md) 逐步检查

3. **完全重置**
   ```bash
   docker-compose down -v
   docker-compose up -d
   ```

---

## 🎯 快速命令

```bash
# 查看所有运行的作业
docker exec flink-jobmanager /opt/flink/bin/flink list

# 生成测试数据
source .venv/bin/activate && python produce_avro.py

# 运行 Flink SQL
./test-flink-sql.sh

# 查看结果
docker exec schema-registry kafka-avro-console-consumer \
  --bootstrap-server kafka:29092 --topic avro-sink \
  --from-beginning --max-messages 5 \
  --property schema.registry.url=http://localhost:8081
```

---

## 🌟 项目亮点

✅ **开箱即用** - Docker Compose 一键启动
✅ **完整示例** - Avro + Schema Registry + Flink SQL
✅ **详细文档** - 从入门到进阶全覆盖
✅ **问题排查** - 完整的检查清单
✅ **易于扩展** - 可以轻松修改和定制

---

**现在就开始吧！** 打开 [QUICK_START.md](./QUICK_START.md) 👉

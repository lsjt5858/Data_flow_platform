# 项目文件说明

## 📁 核心文件（必需）

| 文件名 | 用途 | 是否可修改 |
|--------|------|-----------|
| `docker-compose.yml` | Docker 服务定义 | ⚠️ 谨慎修改 |
| `flink-entrypoint.sh` | Flink 启动脚本 | ⚠️ 谨慎修改 |
| `flink-lib/` | Flink 依赖 JAR 包 | ❌ 不要删除 |

## 📝 SQL 脚本

| 文件名 | 用途 | 说明 |
|--------|------|------|
| `test-insert.sql` | Avro 格式的 Flink SQL | 主要测试脚本 |

## 🐍 Python 脚本

| 文件名 | 用途 | 说明 |
|--------|------|------|
| `produce_avro.py` | 生成 Avro 测试数据 | ✅ 可以作为模板修改 |
| `produce_json.py` | 生成 JSON 测试数据 | ✅ 可以作为模板修改 |
| `consume_avro.py` | 消费 Avro 数据 | 用于验证数据 |

## 🔧 工具脚本

| 文件名 | 用途 | 说明 |
|--------|------|------|
| `test-flink-sql.sh` | 执行 Flink SQL 脚本 | 快速执行 test-insert.sql |
| `run-flink-demo.sh` | 完整演示流程 | 端到端测试 |
| `install_deps.sh` | 安装 Python 依赖 | 首次运行使用 |
| `setup-jars.sh` | 下载 JAR 包 | 已完成，无需再运行 |

## 📂 目录说明

| 目录名 | 用途 | 是否必需 |
|--------|------|---------|
| `.venv/` | Python 虚拟环境 | ✅ 必需 |
| `flink-lib/` | Flink JAR 包 | ✅ 必需 |
| `checkpoints/` | Flink checkpoint | ✅ 必需（自动生成）|
| `savepoints/` | Flink savepoint | ✅ 必需（自动生成）|
| `.claude/` | Claude 工作目录 | ⚠️ 可删除 |

## ❌ 可以删除的文件

以下文件已被清理或不再需要：
- ~~`consume_sink.py`~~ (已删除)
- ~~`quick_test.py`~~ (已删除)
- ~~`produce_avro_simple.py`~~ (已删除)
- ~~`test-avro-print.sql`~~ (已删除)
- ~~`test-json.sql`~~ (已删除)
- ~~`test-print.sql`~~ (已删除)
- `.DS_Store` (macOS 系统文件，可删除)

## 🎯 快速导航

### 我想生成自己的数据
→ 参考 `produce_avro.py` 或 `produce_json.py`

### 我想修改 Flink SQL 逻辑
→ 编辑 `test-insert.sql`

### 我想一键运行完整测试
→ 运行 `./run-flink-demo.sh`

### 我想查看详细文档
→ 阅读 `README.md`

## 📋 文件重要性等级

### ⭐⭐⭐ 核心文件（不能删除）
- `docker-compose.yml`
- `flink-entrypoint.sh`
- `flink-lib/` 目录及其内容

### ⭐⭐ 重要文件（推荐保留）
- `test-insert.sql`
- `test-flink-sql.sh`
- `produce_avro.py`
- `README.md`

### ⭐ 辅助文件（可选）
- `produce_json.py`
- `consume_avro.py`
- `run-flink-demo.sh`
- `install_deps.sh`

## 🔄 典型工作流程

```
1. 启动环境
   docker-compose up -d

2. 生成数据
   source .venv/bin/activate
   python produce_avro.py

3. 运行 Flink SQL
   ./test-flink-sql.sh

4. 验证结果
   查看 README.md 中的验证命令
```

---

**提示**：如果不确定某个文件的作用，请查看 `README.md` 获取详细说明。

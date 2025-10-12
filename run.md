# 运行指引（保姆级）

本项目提供 Flink SQL + Kafka + Schema Registry 的端到端演示。按照下列步骤，从环境准备到验证页面、日志排查，每一步都有明确可执行命令与预期结果。

建议在项目根目录运行所有命令（即本文件所在目录）。

---

## 0. 前提条件

- 已安装 Docker 与 Docker Compose（macOS 用户建议安装 Docker Desktop）
- 端口未被占用：
  - Kafka UI: `http://localhost:8080`
  - Flink Web UI: `http://localhost:8082`
  - Schema Registry: `http://localhost:8081`
- 首次使用建议下载 Flink 依赖 JAR，并安装 Python 依赖

---

## 1. 初始化依赖（首次运行必看）

如果 `flink/lib` 目录为空（或你不确定），先下载 JAR 依赖：

```bash
./scripts/sh/setup-jars.sh
```

安装 Python 依赖（使用项目自带虚拟环境 `.venv`）：

```bash
./scripts/sh/install_deps.sh
```

预期结果：
- 终端显示 JAR 下载完成
- Python 安装成功且无错误

---

## 2. 启动基础服务

启动 Kafka、Schema Registry、Flink 等全部服务：

```bash
docker-compose up -d
```

检查容器是否就绪（可多等 5–10 秒）：

```bash
docker ps
```

打开 Flink Web UI（作业与指标页）：

```bash
open http://localhost:8082
```

打开 Kafka UI（主题与消息页）：

```bash
open http://localhost:8080
```

打开 Schema Registry（REST 接口自检）：

```bash
open http://localhost:8081
```

预期结果：
- Flink UI 打开，能看到 JobManager 页面（可能暂无作业）
- Kafka UI 打开，后续会看到 `json-topic`、`json-sink`、`avro-topic`、`avro-sink` 等主题
- Schema Registry 页面响应正常

---

## 3. 运行 JSON 快速演示（源 -> 汇）

此演示会：
- 生产 JSON 数据到 `json-topic`
- 提交 Flink SQL：`json_source -> json_sink`
- 验证 `json-sink` 主题存在且有偏移增长

运行脚本：

```bash
./scripts/sh/run-flink-json-demo.sh
```

查看 `json-topic` 最新偏移：

```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic json-topic
```

查看 `json-sink` 最新偏移（执行 SQL 后应增长）：

```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic json-sink
```

在 Flink UI 验证：
- 打开 `http://localhost:8082`，查看作业是否存在
- 查看该作业的 `Read/Write Records` 指标是否增长

在 Kafka UI 验证：
- 打开 `http://localhost:8080`，查看 `json-sink` 主题是否已创建
- 检查分区的消息数量是否增加

---

## 4. 运行 Avro 完整演示（含 Schema Registry）

此演示会：
- 使用虚拟环境运行 Python 生产 Avro 数据到 `avro-topic`
- 提交 Flink SQL（`sql/avro/test-insert.sql`）
- 自动打印作业 ID，并抓取作业顶点的指标

运行脚本：

```bash
./scripts/sh/run-flink-demo.sh
```

查看当前所有 Flink 作业：

```bash
docker exec flink-jobmanager /opt/flink/bin/flink list
```

从 Schema Registry 消费 `avro-sink` 的数据（最多 5 条）：

```bash
docker exec schema-registry kafka-avro-console-consumer --bootstrap-server kafka:29092 --topic avro-sink --from-beginning --max-messages 5 --property schema.registry.url=http://localhost:8081
```

在 Flink UI 验证：
- 打开 `http://localhost:8082`
- 找到该作业，查看顶点指标：`read-records`、`write-records` 是否增长

在 Kafka UI 验证：
- 打开 `http://localhost:8080`
- 查找 `avro-sink` 主题消息是否递增

---

## 5. 手动提交 Avro SQL（分步验证）

如果你想手动只跑 SQL，使用以下脚本：

```bash
./scripts/sh/test-flink-sql.sh
```

预期结果：
- 终端显示 Job ID（说明 SQL 提交成功）
- Flink UI 中能看到该作业处于 RUNNING 或 FINISHED

---

## 6. 持续 JSON 流（压力与实时指标观察）

持续生产 JSON 数据到某个主题（默认 `json-wide-topic`，可带参数）：

```bash
python3 ./scripts/python/produce_json_stream.py
```

示例：指定主题与间隔（毫秒），并从特定 ID 开始：

```bash
python3 ./scripts/python/produce_json_stream.py my-topic 200 --start-id 100
```

在 Flink UI 验证：
- 打开 `http://localhost:8082`
- 对应作业的图表与指标应持续增长

在 Kafka UI 验证：
- 打开 `http://localhost:8080`
- 查看对应主题的消息数量、分区偏移随时间增加

---

## 7. 常用验证命令（随时可用）

查看 `json-sink` 偏移：

```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic json-sink
```

查看 `avro-topic` 偏移：

```bash
docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic avro-topic
```

列出已加载的 Flink JAR（检查 Avro/Kafka 相关依赖是否在容器内）：

```bash
docker exec flink-jobmanager ls -lh /opt/flink/lib/ | grep -E "avro|kafka"
```

查看 JobManager 日志（尾部 100 行）：

```bash
docker logs flink-jobmanager --tail 100
```

查看 TaskManager 日志（尾部 100 行）：

```bash
docker logs flink-taskmanager --tail 100
```

---

## 8. 停止与清理

只停止服务（保留状态与数据）：

```bash
docker-compose down
```

停止并删除所有数据卷（完全重置环境）：

```bash
docker-compose down -v
```

---

## 9. 常见问题排查（FAQ）

- 作业 RUNNING 但数据不流动
  - 确认 source 主题中确实有数据：
    ```bash
    docker exec kafka kafka-run-class kafka.tools.GetOffsetShell --broker-list localhost:9092 --topic avro-topic
    ```
  - 检查 SQL 的 topic 名称和 schema 设置是否正确（查看 `sql/avro/test-insert.sql`）
  - 确认 JAR 已加载：
    ```bash
    docker exec flink-jobmanager ls -lh /opt/flink/lib/ | grep -E "avro|kafka"
    ```

- ClassNotFoundException（JAR 未加载）
  - 重新下载 JAR：
    ```bash
    ./scripts/sh/setup-jars.sh
    ```
  - 重启 Flink 容器：
    ```bash
    docker-compose restart flink-jobmanager flink-taskmanager
    ```

- 端口被占用
  - 关闭占用相同端口的其他服务或修改 `docker-compose.yml` 中的 `ports` 映射

- 虚拟环境未启用导致无法调用 Python 依赖
  - 你可以直接运行带有完整路径与激活的脚本（示例已在脚本内部自动处理）

---

## 10. 结构与入口（方便你确认）

- Shell 脚本：
  - `./scripts/sh/run-flink-json-demo.sh`（JSON E2E 演示）
  - `./scripts/sh/run-flink-demo.sh`（Avro E2E 演示）
  - `./scripts/sh/test-flink-sql.sh`（只执行 Avro SQL）
  - `./scripts/sh/setup-jars.sh`（下载 JAR）
  - `./scripts/sh/install_deps.sh`（安装 Python 依赖）
- Python 脚本：
  - `./scripts/python/produce_json.py`（一次性 JSON 数据）
  - `./scripts/python/produce_avro.py`（一次性 Avro 数据）
  - `./scripts/python/produce_json_stream.py`（持续 JSON 数据）
  - `./scripts/python/consume_json.py`、`consume_avro.py`（消费与验证）
- SQL 脚本：
  - `./sql/json/test-json.sql`（JSON Source->Sink）
  - `./sql/json/test-json-ckpt.sql`、`test-json-wide-ckpt.sql`（含 checkpoint 示例）
  - `./sql/avro/test-insert.sql`（Avro + Schema Registry 示例）
- Flink 依赖：
  - `./flink/lib`（挂载到容器 `/opt/flink/usrlib`）
  - `./flink/state/checkpoints`、`./flink/state/savepoints`（状态与快照）

---

照着这份文档执行，你可以完成从环境启动、数据生产、SQL 提交到页面与日志验证的完整流程。遇到任何问题，提运行日志或页面截图，我帮你继续排查。
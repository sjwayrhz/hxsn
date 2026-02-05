这份文档记录了你如何通过 **Beyla (eBPF)** 实现跨机器监控，并将远程节点接入 **intro-to-mltp** 后端的过程。

------

# 远程节点监控接入指南 (eBPF + Beyla)

本教程详细记录了如何在分部 Linux 机器上部署 Beyla 探针，并将其监控数据推送至 Ubuntu 总部服务器。

## 1. 环境准备

### 1.1 总部 (Ubuntu) 资产

- **IP 地址**: `192.168.246.129` (请替换为你的实际 IP)
- **运行项目**: `intro-to-mltp`
- **开放端口**: 确保防火墙已放行 `4317` (Tempo/OTLP)。

### 1.2 分部 (远程 Linux) 资产

- **IP 地址**: 你的测试机器 IP。
- **运行环境**: 已安装 Docker。

------

## 2. 操作步骤

### 第一步：在分部机器启动模拟业务

由于 Beyla 监控的是流量，如果机器没有业务，拓扑图将无法显示。我们使用 Python 快速启动一个 80 端口的 Web 服务。

Bash



```
# 进入你想要展示的目录
sudo python3 -m http.server 80
```

> **注意**: 请保持该窗口运行，或在后台执行。

### 第二步：部署 Beyla 探针容器

在分部机器执行以下 Docker 命令，将监控数据发往总部。

Bash



```
docker run -d --name remote-beyla \
  --pid host \
  --privileged \
  -e BEYLA_OPEN_PORT=80 \
  -e OTEL_EXPORTER_OTLP_ENDPOINT=http://192.168.246.129:4317 \
  -e BEYLA_SERVICE_NAME=Remote-Node-01 \
  grafana/beyla:latest
```

**环境变量说明：**

- `--pid host`: 允许 Beyla 看到宿主机的所有进程。
- `BEYLA_OPEN_PORT=80`: 监控 80 端口的流入流量。
- `OTEL_EXPORTER_OTLP_ENDPOINT`: 总部机器接收数据的地址。
- `BEYLA_SERVICE_NAME`: 在 Grafana 拓扑图中显示的名称。

### 第三步：触发测试流量

手动制造一些请求，让 Beyla 抓取。

Bash



```
# 连续请求 10 次
for i in {1..10}; do curl http://localhost:80; done
```

------

## 3. 验证与观测

### 3.1 检查 Beyla 日志

执行 `docker logs -f remote-beyla`，若看到以下内容则表示成功识别：

- `instrumenting process ... cmd=/usr/bin/python3`
- `Starting main node`

### 3.2 在总部的 Grafana 查看拓扑

1. 访问 `http://192.168.246.129:3000`。
2. 进入 **Explore**，数据源选择 **Tempo**。
3. 切换到 **Service Graph** 标签页并点击 **Run query**。
4. **结果表现**:
   - 你会看到一个独立的圆圈 **Remote-Node-01**。
   - 列表下方会出现 `GET /` 的记录，对应的 **Rate** 约为 `0.03` 左右。

------

## 4. 常见问题排查

| **现象**             | **可能原因**       | **解决方法**                                    |
| -------------------- | ------------------ | ----------------------------------------------- |
| **拓扑图没出现圆圈** | 总部 4317 端口没开 | 检查 `ufw` 或云平台安全组规则。                 |
| **日志提示 Timeout** | 网络不通           | 在分部执行 `telnet 192.168.246.129 4317` 测试。 |
| **列表显示 NaN**     | 样本量太少         | 增加 `curl` 请求的次数，扩大 Grafana 时间范围。 |

------

**下一步建议：**

这份文档保存好后，如果你想监控其他端口（比如公司真实的 Java 或 Go 应用），只需修改 `BEYLA_OPEN_PORT` 并重启容器即可。


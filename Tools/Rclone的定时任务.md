由于 Docker 容器默认没有运行 `cron` 服务，且你当前的系统没有 `systemd`，我们需要先安装 cron 并手动启动它。

根据你的要求（中国凌晨 2:00 = **UTC 时间前一天 18:00**），以下是完整的配置步骤：

### 1. 准备上传脚本

首先，我们写一个带校验逻辑的脚本，防止上传失败就把文件删了。

```bash
cat << 'EOF' > /root/upload_to_gdrive.sh
#!/bin/bash

# 定义路径
LOCAL_DIR="/usr/local/share/downloads"
REMOTE_PATH="gdrive:/douyin_records"
# 加上代理环境变量，确保甲骨文 IP 不被拒
export ALL_PROXY=socks5://127.0.0.1:40000

echo "Starting upload at $(date)"

# 在这里直接加入重试和限流参数
/usr/bin/rclone copy "$LOCAL_DIR" "$REMOTE_PATH" \
  --retries 10 \
  --retries-sleep 10s \
  --tpslimit 3 \
  --drive-chunk-size 64M \
  -v

# 校验：增加相同的重试参数，防止 check 阶段也因为 429 报错
if /usr/bin/rclone check "$LOCAL_DIR" "$REMOTE_PATH" --one-way --retries 10 --tpslimit 3; then
    echo "Check successful. Deleting local files..."
    rm -rf "${LOCAL_DIR:?}"/*
else
    echo "Check failed! File mismatch. Keeping local files."
    exit 1
fi
EOF

# 赋予执行权限
chmod +x /root/upload_to_gdrive.sh
```

---

### 2. 安装并设置 Cron

在容器内安装 cron 服务：

```bash
apt update && apt install -y cron
```

编辑定时任务：

```bash
crontab -e
```

在文件末尾添加以下内容（注意：既然你已经手动设置了上海时区，建议直接用上海时间 **0 2 * * ***。如果系统非要用 UTC，则是 **0 18 * * ***）：

```cron
# 每天凌晨 2:00 (中国时间) 执行脚本
0 2 * * * /bin/bash /root/upload_to_gdrive.sh >> /root/rclone_cron.log 2>&1
```

---

### 3. 关键：启动 Cron 服务

因为没有 `systemctl`，你需要手动在后台启动 cron 守护进程：

```bash
# 直接运行 cron 进程
cron
```

**验证是否启动成功：**

```bash
ps -ef | grep cron
```

---

### 💡 为什么这样写最安全？

1. **`rclone check` 校验**：这是最核心的一步。它会逐一比对本地和云盘文件的哈希值。只有完全一致，才会执行 `rm -rf`。
2. **`${LOCAL_DIR:?}`**：这是一个 Shell 安全技巧。如果变量因为某种原因为空，`rm -rf` 不会误删根目录。
3. **日志记录**：所有的执行情况都会记录在 `/root/rclone_cron.log`。

### ⚠️ 注意事项（重要）

1. **进程保活**：如果你的 Docker 容器重启了，`cron` 进程会消失。你需要在你启动容器的脚本（比如 `main.py` 的启动脚本）里加入一行 `cron`。
2. **带宽限制**：如果 2:00 录制任务还在运行（比如某个主播还没下播），`rclone` 会尝试复制正在写入的文件。`rclone copy` 默认会跳过正在变化的文件，下次执行才会成功，这通常是安全的。
3. **内存**：`rclone check` 比较费内存（需要计算哈希），你的 **4G 内存** 没问题，但如果文件数达到几万个，请留意内存压力。

你现在可以先手动执行一次 `/bin/bash /root/upload_to_gdrive.sh` 看看能不能跑通？
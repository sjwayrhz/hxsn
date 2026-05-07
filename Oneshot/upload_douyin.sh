#!/bin/bash

# 运行此脚本需要在同级目录下包含 channels.json,内容样式如下：
# {
#   "TikTok直播/Isa_Uyên-isauyen_official": "PLaEnOcR3Z1V8WTIyICmV9DKxnayWZ6Y10",
#   "抖音直播/三七": "PLaEnOcR3Z1V-8KibtiWPXzTGXKC6t-j19"
# }
# 配置crontab的任务举例
# 0 * * * * flock -n /tmp/upload_douyin.lock -c "/bin/bash /usr/local/bin/upload_douyin.sh"

# ================= 配置区域 =================
UPLOADER_BIN="/usr/local/bin/youtubeuploader"
LOG_FILE="/root/youtube_upload.log"
CLIENT_SECRETS="/etc/youtube/client_secrets.json"
REQUEST_TOKEN="/etc/youtube/request.token"
BASE_DIR="/root/DouyinLiveRecorder/downloads"
CONFIG_JSON="/usr/local/bin/channels.json"

# --- 参数处理逻辑 ---
TARGET_EXT=$1

if [ -z "$TARGET_EXT" ]; then
    # 如果没传参数，匹配常见的所有视频格式
    FIND_PATTERN="\( -name *.mp4 -o -name *.flv -o -name *.ts -o -name *.mkv -o -name *.mov \)"
    echo "未指定格式，将扫描所有支持的视频类型..." >> "$LOG_FILE"
else
    # 如果传了参数 (比如 mp4)，则只匹配该后缀
    CLEAN_EXT=${TARGET_EXT#.} # 去掉可能的点
    FIND_PATTERN="-name *.$CLEAN_EXT"
    echo "指定上传格式: $CLEAN_EXT" >> "$LOG_FILE"
fi
# ===========================================

# 检查环境
if ! command -v jq &> /dev/null; then echo "需安装 jq" >> "$LOG_FILE"; exit 1; fi
if [ ! -f "$CONFIG_JSON" ]; then echo "配置不存在" >> "$LOG_FILE"; exit 1; fi

echo "----------- 任务开始: $(date) -----------" >> "$LOG_FILE"

# 读取配置并循环
jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$CONFIG_JSON" | while IFS=$'\t' read -r RELATIVE_PATH CURRENT_PLAYLIST; do

    FULL_PATH="${BASE_DIR}/${RELATIVE_PATH}"
    [ ! -d "$FULL_PATH" ] && continue

    echo ">> 正在检查目录: [${RELATIVE_PATH}]" >> "$LOG_FILE"

    # 使用 eval 动态执行带模式的 find 命令
    eval "find \"$FULL_PATH\" -type f $FIND_PATTERN -print0" | while IFS= read -r -d '' FILE_PATH; do

        FILENAME=$(basename "$FILE_PATH")

        # ================= TS动态文件检测 =================
        if [[ "${FILENAME##*.}" == "ts" ]]; then
            # 记录当前文件大小（字节）
            SIZE_BEFORE=$(stat -c%s "$FILE_PATH" 2>/dev/null)
            
            # 等待 3 秒（根据你的网络和录制写入频率，可以适当调整，比如 5）
            sleep 3
            
            # 再次获取文件大小
            SIZE_AFTER=$(stat -c%s "$FILE_PATH" 2>/dev/null)

            # 如果获取不到大小，或者大小发生变化，说明文件正在动态写入中
            if [ -z "$SIZE_BEFORE" ] || [ "$SIZE_BEFORE" != "$SIZE_AFTER" ]; then
                echo "   [$(date +%H:%M:%S)] 跳过动态文件 (正在录制): $FILENAME" >> "$LOG_FILE"
                continue # 跳过当前文件，进入下一次循环
            fi
        fi
        # ========================================================

        echo "   [$(date +%H:%M:%S)] 准备上传: $FILENAME" >> "$LOG_FILE"

        UPLOAD_OUTPUT=$(mktemp)
        "$UPLOADER_BIN" \
          -secrets "$CLIENT_SECRETS" \
          -cache "$REQUEST_TOKEN" \
          -playlistID "$CURRENT_PLAYLIST" \
          -filename "$FILE_PATH" >> "$LOG_FILE" 2> "$UPLOAD_OUTPUT"

        EXIT_CODE=$?
        cat "$UPLOAD_OUTPUT" >> "$LOG_FILE"

        # 配额检查
        if grep -q -i "quotaExceeded" "$UPLOAD_OUTPUT"; then
            echo "   !!! 配额耗尽，脚本退出 !!!" >> "$LOG_FILE"
            rm -f "$UPLOAD_OUTPUT"
            exit 1
        fi

        # 结果处理
        if [ $EXIT_CODE -eq 0 ]; then
            echo "   >>> 成功，删除文件。" >> "$LOG_FILE"
            rm -f "$FILE_PATH"
        else
            echo "   <<< 失败，保留文件。" >> "$LOG_FILE"
        fi
        rm -f "$UPLOAD_OUTPUT"

    done
    # 如果内部循环因为配额 exit 1，我们需要确保外部也能感知并退出
    [ $? -eq 1 ] && exit 1

done

echo "----------- 任务结束: $(date) -----------" >> "$LOG_FILE"

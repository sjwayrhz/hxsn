#!/bin/bash

# ================= 强制环境编码 =================
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# ================= 配置区域 =================
UPLOADER_BIN="/usr/local/bin/youtubeuploader"
LOG_FILE="/root/youtube_upload.log"
CLIENT_SECRETS="/etc/youtube/client_secrets.json"
REQUEST_TOKEN="/etc/youtube/request.token"
BASE_DIR="/root/DouyinLiveRecorder/downloads"
CONFIG_JSON="/usr/local/bin/channels.json"
MIN_SIZE_MB=100
# ----------------------------------------

# --- 参数处理逻辑 ---
TARGET_EXT=$1
if [ -z "$TARGET_EXT" ]; then
    FIND_ARGS=( \( -name "*.mp4" -o -name "*.flv" -o -name "*.ts" -o -name "*.mkv" -o -name "*.mov" \) )
    echo "未指定格式，将扫描所有支持的视频类型..." >> "$LOG_FILE"
else
    CLEAN_EXT=${TARGET_EXT#.}
    FIND_ARGS=( -name "*.$CLEAN_EXT" )
    echo "指定上传格式: $CLEAN_EXT" >> "$LOG_FILE"
fi

# 检查环境
if ! command -v jq &> /dev/null; then echo "需安装 jq" >> "$LOG_FILE"; exit 1; fi
if [ ! -f "$CONFIG_JSON" ]; then echo "配置不存在" >> "$LOG_FILE"; exit 1; fi

echo "----------- 任务开始: $(date) -----------" >> "$LOG_FILE"

# 读取配置并循环
jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$CONFIG_JSON" | while IFS=$'\t' read -r RELATIVE_PATH CURRENT_PLAYLIST; do

    FULL_PATH="${BASE_DIR}/${RELATIVE_PATH}"

    if [ ! -d "$FULL_PATH" ]; then
        echo "   [警告] 目录不存在，跳过: [$FULL_PATH]" >> "$LOG_FILE"
        continue
    fi

    echo ">> 正在检查目录: [${RELATIVE_PATH}]" >> "$LOG_FILE"

    find "$FULL_PATH" -type f "${FIND_ARGS[@]}" -print0 | while IFS= read -r -d '' FILE_PATH; do

        FILENAME=$(basename "$FILE_PATH")
        
        # ================= 1. 文件大小检查 (新增) =================
        # 获取文件大小 (Byte)
        FILE_SIZE_BYTES=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
        # 换算为 MB (整数)
        FILE_SIZE_MB=$(( FILE_SIZE_BYTES / 1024 / 1024 ))

        if [ "$FILE_SIZE_MB" -lt "$MIN_SIZE_MB" ]; then
            echo "   [$(date +%H:%M:%S)] 跳过过小文件: $FILENAME (${FILE_SIZE_MB}MB < ${MIN_SIZE_MB}MB)" >> "$LOG_FILE"
            # 注意：此处你可以选择 rm -f "$FILE_PATH" 来清理垃圾文件，
            # 或者直接 continue 保留它。脚本目前默认保留。
            continue
        fi

        # ================= 2. TS动态文件检测 =================
        if [[ "${FILENAME##*.}" == "ts" ]]; then
            SIZE_BEFORE=$FILE_SIZE_BYTES
            sleep 3
            SIZE_AFTER=$(stat -c%s "$FILE_PATH" 2>/dev/null)

            if [ -z "$SIZE_BEFORE" ] || [ "$SIZE_BEFORE" != "$SIZE_AFTER" ]; then
                echo "   [$(date +%H:%M:%S)] 跳过动态文件 (正在录制): $FILENAME" >> "$LOG_FILE"
                continue
            fi
        fi

        # ================= 3. 执行上传 =================
        echo "   [$(date +%H:%M:%S)] 准备上传: $FILENAME (${FILE_SIZE_MB}MB)" >> "$LOG_FILE"

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
    
    [ $? -eq 1 ] && exit 1

done

echo "----------- 任务结束: $(date) -----------" >> "$LOG_FILE"


# 运行此脚本需要在同级目录下包含 channels.json,内容样式如下：
# {
#   "TikTok直播/Isa_Uyên-isauyen_official": "PLaEnOcR3Z1V8WTIyICmV9DKxnayWZ6Y10",
#   "抖音直播/三七": "PLaEnOcR3Z1V-8KibtiWPXzTGXKC6t-j19"
# }
# 配置crontab的任务举例
# 0 * * * * flock -n /tmp/upload_douyin.lock -c "/bin/bash /usr/local/bin/upload_douyin.sh"

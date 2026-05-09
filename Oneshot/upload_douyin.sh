#!/bin/bash

# ================= 强制环境编码 =================
# 使用系统自带的通用 C.UTF-8 编码，防止部分精简系统报错
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# ================= 配置区域 =================
UPLOADER_BIN="/usr/local/bin/youtubeuploader"
LOG_FILE="/root/youtube_upload.log"
CLIENT_SECRETS="/etc/youtube/client_secrets.json"
REQUEST_TOKEN="/etc/youtube/request.token"
BASE_DIR="/root/DouyinLiveRecorder/downloads"
CONFIG_JSON="/usr/local/bin/channels.json"

# --- 参数处理逻辑 (优化为数组，彻底抛弃 eval) ---
TARGET_EXT=$1

if [ -z "$TARGET_EXT" ]; then
    # 如果没传参数，匹配常见的所有视频格式
    FIND_ARGS=( \( -name "*.mp4" -o -name "*.flv" -o -name "*.ts" -o -name "*.mkv" -o -name "*.mov" \) )
    echo "未指定格式，将扫描所有支持的视频类型..." >> "$LOG_FILE"
else
    # 如果传了参数 (比如 mp4)，则只匹配该后缀
    CLEAN_EXT=${TARGET_EXT#.} # 去掉可能的点
    FIND_ARGS=( -name "*.$CLEAN_EXT" )
    echo "指定上传格式: $CLEAN_EXT" >> "$LOG_FILE"
fi
# ===========================================

# 检查环境
if ! command -v jq &> /dev/null; then echo "需安装 jq" >> "$LOG_FILE"; exit 1; fi
if [ ! -f "$CONFIG_JSON" ]; then echo "配置不存在" >> "$LOG_FILE"; exit 1; fi

echo "----------- 任务开始: $(date) -----------" >> "$LOG_FILE"

# 读取配置并循环 (使用 jq 原始输出模式)
jq -r 'to_entries[] | "\(.key)\t\(.value)"' "$CONFIG_JSON" | while IFS=$'\t' read -r RELATIVE_PATH CURRENT_PLAYLIST; do

    # 严格使用双引号保护路径变量
    FULL_PATH="${BASE_DIR}/${RELATIVE_PATH}"

    # 调试日志：如果目录真的不存在，打印到日志里方便排查编码问题
    if [ ! -d "$FULL_PATH" ]; then
        echo "   [警告] 目录不存在或名字不匹配，跳过: [$FULL_PATH]" >> "$LOG_FILE"
        continue
    fi

    echo ">> 正在检查目录: [${RELATIVE_PATH}]" >> "$LOG_FILE"

    # 使用数组传递参数，彻底避免 eval 带来的特殊字符解析灾难
    find "$FULL_PATH" -type f "${FIND_ARGS[@]}" -print0 | while IFS= read -r -d '' FILE_PATH; do

        FILENAME=$(basename "$FILE_PATH")

        # ================= TS动态文件检测 =================
        if [[ "${FILENAME##*.}" == "ts" ]]; then
            # 记录当前文件大小（字节）
            SIZE_BEFORE=$(stat -c%s "$FILE_PATH" 2>/dev/null)

            # 等待 3 秒
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
        
        # 严谨引用变量，防止特殊字符报错
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
    
    # 如果内部循环因为配额 exit 1，确保外部也能感知并退出
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

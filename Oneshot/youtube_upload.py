#!/bin/bash

# ================= 配置区域 =================
# 1. 基础程序路径
UPLOADER_BIN="/usr/local/bin/youtubeuploader"
LOG_FILE="/root/youtube_upload.log"

# 2. 共有认证文件路径
CLIENT_SECRETS="/etc/youtube/client_secrets.json"
REQUEST_TOKEN="/etc/youtube/request.token"

# 3. 基础下载目录 (所有录制平台的总根目录)
# 脚本会将这个目录与下面的相对路径拼接
BASE_DIR="/root/DouyinLiveRecorder/downloads"

# 4. 映射配置: ["平台/主播目录"]="对应的播放列表ID"
# 支持自定义多级相对路径
declare -A FOLDER_TO_PLAYLIST
FOLDER_TO_PLAYLIST["抖音直播/水水家猪蹄"]="PLaEnOcR3Z1V8V_yLEULP4ArwLygyuhQdG"
FOLDER_TO_PLAYLIST["TikTok直播/Isa_Uyên-isauyen_official"]="PLaEnOcR3Z1V_dY0BACkGTMqtGXhYA3gJ3"

# ===========================================

echo "----------- 任务开始: $(date) -----------" >> "$LOG_FILE"

# Step 1: 遍历映射关系
for RELATIVE_PATH in "${!FOLDER_TO_PLAYLIST[@]}"; do
    CURRENT_PLAYLIST="${FOLDER_TO_PLAYLIST[$RELATIVE_PATH]}"
    
    # 将基础根目录与配置的相对路径拼接
    FULL_PATH="${BASE_DIR}/${RELATIVE_PATH}"

    echo ">> 正在检查目录: [${RELATIVE_PATH}]" >> "$LOG_FILE"

    if [ ! -d "$FULL_PATH" ]; then
        echo "   跳过: 目录不存在 ($FULL_PATH)" >> "$LOG_FILE"
        continue
    fi

    # Step 2: 递归查找并上传视频
    # 优化点：使用进程替换 < <(...) 替代管道 | ，确保 exit 1 能够退出整个主脚本，而不是仅退出子 Shell
    while IFS= read -r -d '' FILE_PATH; do
        FILENAME=$(basename "$FILE_PATH")

        echo "   [$(date +%H:%M:%S)] 准备上传: $FILENAME" >> "$LOG_FILE"

        # 创建临时文件捕获输出，用于判断 API 配额
        UPLOAD_OUTPUT=$(mktemp)

        "$UPLOADER_BIN" \
          -secrets "$CLIENT_SECRETS" \
          -cache "$REQUEST_TOKEN" \
          -playlistID "$CURRENT_PLAYLIST" \
          -filename "$FILE_PATH" >> "$LOG_FILE" 2> "$UPLOAD_OUTPUT"

        EXIT_CODE=$?

        # 将错误输出合并到日志
        cat "$UPLOAD_OUTPUT" >> "$LOG_FILE"

        # 关键逻辑 A: 判断配额是否超限
        if grep -q -i "quotaExceeded" "$UPLOAD_OUTPUT"; then
            echo "   !!! 严重错误: YouTube API 配额已用完，立即停止本次所有任务 !!!" >> "$LOG_FILE"
            rm -f "$UPLOAD_OUTPUT"
            # 因为没有使用管道，这里的 exit 1 会真正中断并退出整个脚本
            exit 1 
        fi

        # 关键逻辑 B: 根据上传结果决定是否删除文件
        if [ $EXIT_CODE -eq 0 ]; then
            echo "   >>> 上传成功，正在删除本地文件..." >> "$LOG_FILE"
            rm -f "$FILE_PATH"
            if [ $? -eq 0 ]; then
                echo "   已成功清理: $FILENAME" >> "$LOG_FILE"
            else
                echo "   警告: 文件删除失败，请检查权限。" >> "$LOG_FILE"
            fi
        else
            echo "   <<< 上传失败 (错误码: $EXIT_CODE)，保留文件以供下次重试。" >> "$LOG_FILE"
        fi

        echo "   ----------------------------------------" >> "$LOG_FILE"
        rm -f "$UPLOAD_OUTPUT"
        
    done < <(find "$FULL_PATH" -type f \( -name "*.mp4" -o -name "*.flv" -o -name "*.ts" -o -name "*.mkv" -o -name "*.mov" \) -print0)
done

echo "----------- 任务结束: $(date) -----------" >> "$LOG_FILE"

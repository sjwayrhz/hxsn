@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

echo 正在扫描当前目录下的 .ts 文件...
echo.

set count=0

for %%f in (*.ts) do (
    set /a count+=1
    echo 正在转换: "%%f"
    ffmpeg -i "%%f" -c copy -movflags +faststart "%%~nf.mp4"
    echo.
)

if %count%==0 (
    echo 当前目录下未找到任何 .ts 文件。
) else (
    echo 全部完成，共处理 %count% 个文件。
)

pause
@echo off
setlocal enabledelayedexpansion
title 空闲 IP 扫描工具

:: 1. 获取用户输入（仅需输入第三段数字）
set /p "THIRD_OCTET=请输入第三段数字 (直接回车默认 50): "
if "%THIRD_OCTET%"=="" set "THIRD_OCTET=50"

:: 自动拼接成完整的网段前缀
set "SUBNET=66.207.%THIRD_OCTET%"

set "USED_FILE=temp_used.txt"
set "USEABLE_FILE=temp_useable_ip.txt"

echo.
echo ===================================================
echo 正在扫描网段: %SUBNET%.x
echo 第 1 步: 正在发送 Ping 请求以更新本地 ARP 缓存...
echo ===================================================

:: 打印进度条的起始括号
<nul set /p ="进度: ["

:: 2. 遍历并 Ping 所有 IP (1-254)
for /L %%i in (1,1,254) do (
    :: 实时更新 CMD 窗口标题的数字进度
    title 扫描进度: %%i / 254
    
    :: 发送 1 个数据包，超时 200ms
    ping -n 1 -w 200 %SUBNET%.%%i >nul 2>&1

    :: 进度条动画：每扫描 5 个 IP，打印一个方块，总共约 50 个方块
    set /a "mod=%%i %% 5"
    if !mod! equ 0 (
        <nul set /p ="■"
    )
)

:: 补全进度条的结束括号
echo ] 100%%
title 扫描完成

echo.
echo 第 2 步: 正在比对数据并生成 txt 文件...

:: 3. 导出当前 ARP 表，保留为 temp_used.txt
arp -a > "%USED_FILE%"

:: 初始化最终的可用 IP 文本（覆盖之前的内容）
> "%USEABLE_FILE%" echo %SUBNET%.x 网段可用 IP 列表:
>> "%USEABLE_FILE%" echo =================================

:: 4. 在 254 个 IP 中“减去”已被使用的 IP
for /L %%i in (1,1,254) do (
    set "IP=%SUBNET%.%%i"
    
    :: 在 temp_used.txt 中查找该 IP 是否存在 (前后加空格确保精准匹配)
    findstr /C:" !IP! " "%USED_FILE%" >nul
    
    :: errorlevel 不等于 0，说明在 arp 表(temp_used.txt)里没找到，即该 IP 未被使用
    if !errorlevel! NEQ 0 (
        echo !IP! >> "%USEABLE_FILE%"
    )
)

echo.
echo ===================================================
echo 扫描与提取完成！
echo.
echo [保留] 已用 IP 缓存文件 : %USED_FILE%
echo [生成] 空闲可用 IP 文件 : %USEABLE_FILE%
echo ===================================================
pause

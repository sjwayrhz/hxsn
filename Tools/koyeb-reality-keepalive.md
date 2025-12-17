这是一个非常具体的需求。为了实现这一目标，我们需要在你的 Ubuntu 服务器上安装 **Xray**（因为你的链接使用了 `REALITY` 和 `Vision` 流控，这是 Xray 的特性，虽然大家习惯叫 V2Ray，但在技术上需要 Xray 核心），将该服务器配置为客户端，然后写一个脚本通过代理访问网络，最后用定时任务（Crontab）来执行。

⚠️ **安全警告：你刚刚贴出了包含 UUID 和 Public Key 的完整链接。这等同于把你的账号密码公开了。任何人都可以使用这个链接消耗你的流量。建议你在配置完成后，去服务端（Koyeb）重新生成一个新的 UUID。**

以下是完整的一步步操作教程：

### 第一步：在 Ubuntu 上安装 Xray

我们需要安装 Xray 核心来解析你的链接。在你的 Ubuntu 终端执行以下命令：

```bash
# 切换到 root 用户 (如果没有)
sudo -i

# 安装 Xray (官方脚本)
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
```

安装完成后，Xray 会自动运行，但我们需要修改配置文件。

### 第二步：配置 Xray (将你的链接转为配置)

我根据你提供的链接 `vless://...` 转换成了标准的 JSON 配置文件。

1. 打开配置文件进行编辑：

    ```bash
    nano /usr/local/etc/xray/config.json
    ```

2. **清空**里面的所有内容，然后**粘贴**以下内容（我已经根据你的链接填好了参数）：

    ```json
    {
      "log": {
        "loglevel": "warning"
      },
      "inbounds": [
        {
          "port": 10808,
          "protocol": "socks",
          "settings": {
            "auth": "noauth",
            "udp": true
          },
          "sniffing": {
            "enabled": true,
            "destOverride": ["http", "tls"]
          }
        }
      ],
      "outbounds": [
        {
          "protocol": "vless",
          "settings": {
            "vnext": [
              {
                "address": "01.proxy.koyeb.app",
                "port": 20172,
                "users": [
                  {
                    "id": "0447f7f3-64af-4da7-8d4e-dee5ba37cb15",
                    "flow": "xtls-rprx-vision",
                    "encryption": "none"
                  }
                ]
              }
            ]
          },
          "streamSettings": {
            "network": "tcp",
            "security": "reality",
            "realitySettings": {
              "serverName": "www.apple.com",
              "fingerprint": "chrome",
              "publicKey": "eZfl07Tg9UII29GaS23QXqB15aqrJ4Khm0vKJIcaMCo",
              "shortId": ""
            }
          },
          "tag": "proxy"
        },
        {
          "protocol": "freedom",
          "tag": "direct"
        }
      ]
    }
    ```

3. 按 `Ctrl+O` 然后回车保存，再按 `Ctrl+X` 退出。

4. 重启 Xray 服务以应用配置：

    ```bash
    systemctl restart xray
    ```

5. **测试一下是否通了：**
    运行下面这行命令，如果返回了一大堆 HTML 代码，说明连接成功：

    ```bash
    curl -x socks5://127.0.0.1:10808 https://www.google.com
    ```

### 第三步：编写保活脚本

我们需要一个脚本，通过刚才搭建的本地代理（端口 10808）去访问网络，从而让远程 Koyeb 服务器认为“有流量”，防止休眠。

1. 创建脚本文件：

    ```bash
    nano /root/keepalive.sh
    ```

2. 粘贴以下内容：

    ```bash
    #!/bin/bash

    # 打印当前时间，方便查看日志
    echo "Running keepalive check at $(date)"

    # 通过本地 SOCKS5 代理 (10808) 访问 Google，只会下载头信息，不消耗过多流量
    # -s: 静默模式
    # -o /dev/null: 不保存输出
    # -w: 显示HTTP状态码
    # --connect-timeout 10: 10秒超时防止卡死

    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -x socks5://127.0.0.1:10808 https://www.google.com)

    if [ "$CODE" = "200" ]; then
        echo "Success: Alive! (Status: $CODE)"
    else
        echo "Failed: Something is wrong. (Status: $CODE)"
        # 如果挂了，尝试重启一下 Xray 服务 (可选)
        # systemctl restart xray
    fi
    ```

3. 给脚本执行权限：

    ```bash
    chmod +x /root/keepalive.sh
    ```

4. 手动试运行一次，看看有没有报错：

    ```bash
    /root/keepalive.sh
    ```

    如果显示 `Success: Alive! (Status: 200)`，就说明成功了。

### 第四步：设置定时任务 (每2分钟一次)

最后，我们把这个脚本加入到 Crontab 计划任务中。

1. 编辑 Crontab：

    ```bash
    crontab -e
    ```

2. 在文件的**最底部**添加这一行：

    ```bash
    */2 * * * * /root/keepalive.sh >> /root/keepalive.log 2>&1
    ```

    *解释：`*/2` 代表每2分钟执行一次，日志会保存在 `/root/keepalive.log` 中。*

3. 保存并退出（如果用的是 nano，按 `Ctrl+O` 回车，`Ctrl+X`）。

### 完成

现在，你的 Ubuntu 服务器会每隔 2 分钟通过 Xray 客户端连接你的 Koyeb 节点并访问 Google。这会产生持续的流量，使 Koyeb 容器保持活跃状态。

**后续维护：**
你可以随时查看日志文件来确定它是否在工作：

```bash
tail -f /root/keepalive.log
```

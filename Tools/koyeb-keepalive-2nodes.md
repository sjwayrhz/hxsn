# config.json

```json
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "in-node1",
      "port": 10001,
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "tag": "in-node2",
      "port": 10002,
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
      "tag": "out-node1",
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
      }
    },
    {
      "tag": "out-node2",
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "01.proxy.koyeb.app",
            "port": 17644,
            "users": [
              {
                "id": "4dd97e90-d8e0-4b47-b06c-dce95b4e24a1",
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
          "publicKey": "jcdABKj-F4CRruC-5VR0Y53C2yIEdSq-bd_Ay79-3VM",
          "shortId": ""
        }
      }
    },
    {
      "tag": "direct",
      "protocol": "freedom"
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["in-node1"],
        "outboundTag": "out-node1"
      },
      {
        "type": "field",
        "inboundTag": ["in-node2"],
        "outboundTag": "out-node2"
      }
    ]
  }
}
```

# keepalive.sh

```
#!/bin/bash

# 定义需要保活的本地端口列表 (中间用空格隔开)
# 这里对应你 config.json 里设置的 inbounds 端口
PORTS="10001 10002"

echo "=== Starting Keepalive Check at $(date) ==="

# 循环遍历每个端口
for PORT in $PORTS; do
    echo "Checking port $PORT..."

    # 请求 Google
    CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 10 -x socks5://127.0.0.1:$PORT https://www.google.com)

    if [ "$CODE" = "200" ]; then
        echo " -> Port $PORT: Success! (Status: 200)"
    else
        echo " -> Port $PORT: Failed! (Status: $CODE)"
    fi

    # 稍微暂停1秒，防止并发太快
    sleep 1
done

echo "=== Check Finished ==="
```

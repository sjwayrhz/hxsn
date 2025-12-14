# koyeb

官网地址：<https://app.koyeb.com/>  
这是一个提供免费docker容器和postgres数据库的网址  
新手注册赠送10美元可以在一周内用完  
部署reality方法：  

## Docker Image 设置

### 镜像源

```
Image: teddysun/xray:latest
```

### 端口  

设置8000端口，tcp，然后需要勾选Proxy TCP access

```
Port: 8000
Protocol: TCP
Proxy TCP access: Ture
```

### 启动命令 (Override Command)

在 Settings -> Docker -> Override Command 中填入：

```
sh -c 'echo "$XRAY_CONFIG" > /etc/xray/config.json && /usr/bin/xray -config /etc/xray/config.json'
```

### 环境变量 (Environment Variables)

1. 点击 "Add Variable"。
2. Name: XRAY_CONFIG
3. Value: (复制下方的 JSON 内容，记得修改 UUID 和 PrivateKey)

```
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 8000,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "0447f7f3-64af-4da7-8d4e-dee5ba37cb15",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.apple.com:443",
          "serverNames": [
            "www.apple.com",
            "images.apple.com"
          ],
          "privateKey": "QNraK6EdxPNOzfbL2G1BTl_OeMSxm49H5vps2qzQ3E0",
          "shortIds": [
            ""
          ]
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
```

### Depoly

运行成功后，在面板Overview看到TCP proxy是 `URL:PORT`

这样得到的URL如下：(需要替换URL为实际上面板生成的URL:PORT)

```
vless://0447f7f3-64af-4da7-8d4e-dee5ba37cb15@URL:PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.apple.com&fp=chrome&pbk=eZfl07Tg9UII29GaS23QXqB15aqrJ4Khm0vKJIcaMCo&type=tcp&headerType=none#Koyeb-Final
```

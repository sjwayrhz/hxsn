# 一份 Hysteria 2 的简单配置记录

Hysteria2 配置记录

## 一键安装Hysteria2

```
bash <(curl -fsSL https://get.hy2.sh/)
```

## 生成自签证书

```
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt -subj "/CN=*.bing.com" -days 36500 && sudo chown hysteria /etc/hysteria/server.key && sudo chown hysteria /etc/hysteria/server.crt
```

## 配置hysteria2配置文件

默认是UDP的443端口，可替换
默认设置的密码（123456），可替换

```
cat << EOF > /etc/hysteria/config.yaml
listen: :65443 
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: 123456

quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false

bandwidth:
  up: 1 gbps
  down: 1 gbps

masquerade:
  type: proxy
  proxy:
    url: https://www.bing.com
    rewriteHost: true

disableUDP: false
udpIdleTimeout: 60s
EOF
```

相比较端口跳跃配置，在quic配置下会少了以下三行。

```
ports:
    min: 20000
    max: 50000
```

然后服务器防火墙需要开放UDP的65443端口

```
iptables -A INPUT -p udp --dport 65443 -j ACCEPT
```

## Hysteria服务设定

将Hysteria服务设定为开机自启并启动

```
systemctl enable --now hysteria-server.service
```

查看服务状态

```
systemctl status hysteria-server.service
```

在V2rayN V7.15.7中，配置信息截图链接：[简单配置](https://i.ibb.co/7D2rqw2/image.jpg)

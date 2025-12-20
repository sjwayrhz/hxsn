# 一份 Hysteria 2 的端口跳跃记录

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

默认是UDP的65443端口，可替换
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
  ports:
    min: 20000
    max: 50000

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

假设网卡名称是eth0,需要开放UDP的65443，20000-50000端口。
当接入20000-50000 udp请求的时候，会转入UDP 65443进入实例。

```
iptables -A INPUT -p udp --dport 65443 -j ACCEPT

IPV4
iptables -t nat -A PREROUTING -i eth0 -p udp --dport 20000:50000 -j DNAT --to-destination :65443

IPV6
ip6tables -t nat -A PREROUTING -i eth0 -p udp --dport 20000:50000 -j DNAT --to-destination :65443
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

在V2rayN V7.15.7中，配置信息截图链接：[端口跳跃](https://i.ibb.co/Dq7H1MY/image.png)

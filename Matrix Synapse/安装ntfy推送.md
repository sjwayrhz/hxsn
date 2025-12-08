# 安装地址

安装地址参考[ntfy](https://docs.ntfy.sh/install/)
这里介绍ubuntu系统

```
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/ntfy.gpg https://archive.ntfy.sh/apt/keyring.gpg
sudo apt install apt-transport-https
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/ntfy.gpg] https://archive.ntfy.sh/apt stable main" \
    | sudo tee /etc/apt/sources.list.d/ntfy.list
sudo apt update
sudo apt install ntfy
```

但是安装之后无法直接启动，因为 /etc/ntfy/server.yml 里面的内容全是注释的，实际上没有有效的配置。

```
mv /etc/ntfy/server.yml /etc/ntfy/server.yml.bak

cat << 'EOF' >> /etc/ntfy/server.yml
listen-http: "0.0.0.0:8080"
cache-file: "/var/lib/ntfy/cache.db"
cache-duration: "7d"
cors-origins: ["*"]
log-level: "info"
auth-file: "/var/lib/ntfy/user.db" 
auth-default-access: "deny-all" 
EOF

sudo chown -R ntfy:ntfy /var/lib/ntfy
sudo chown ntfy:ntfy /etc/ntfy/server.yml
```

可以尝试启动，检查配置是否正确

```
ntfy serve --config /etc/ntfy/server.yml
```

然后可以正式启动了

```
systemctl enable --now ntfy
systemctl status ntfy
ss -lntp | grep 8080
```

重启服务并测试认证

```
sudo systemctl restart ntfy
systemctl status ntfy

创建用户，例如用户sjwayrhz,密码vwv56ty7
sudo ntfy user add sjwayrhz
验证创建的用户
sudo ntfy user list
仅仅添加用户还不够，您还需要为用户分配对特定主题的读/写权限。ntfy 的访问控制列表（ACL）使用 ntfy access 命令管理。
ntfy access sjwayrhz universal-topic read-write
如果想允许用户对所有主题进行读写,但是我这里不做这样的设置
ntfy access sjwayrhz '*' read-write 
```

验证是否配置成功

```
# 不带认证的消息会失败
curl -d "这是一条匿名的测试消息" http://localhost:8080/universal-topic -v
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
> POST /universal-topic HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/8.5.0
> Accept: */*
> Content-Length: 33
> Content-Type: application/x-www-form-urlencoded
>
< HTTP/1.1 403 Forbidden
< Access-Control-Allow-Origin: *
< Content-Type: application/json
< Date: Fri, 28 Nov 2025 14:28:21 GMT
< Content-Length: 100
<
{"code":40301,"http":403,"error":"forbidden","link":"https://ntfy.sh/docs/publish/#authentication"}
* Connection #0 to host localhost left intact

# 发布消息需带认证（示例）
curl -d "这是认证用户发布的消息" --user "sjwayrhz:vwv56ty7" http://localhost:8080/universal-topic -v
* Host localhost:8080 was resolved.
* IPv6: ::1
* IPv4: 127.0.0.1
*   Trying [::1]:8080...
* Connected to localhost (::1) port 8080
* Server auth using Basic with user 'sjwayrhz'
> POST /universal-topic HTTP/1.1
> Host: localhost:8080
> Authorization: Basic c2p3YXlyaHo6dnd2NTZ0eTc=
> User-Agent: curl/8.5.0
> Accept: */*
> Content-Length: 33
> Content-Type: application/x-www-form-urlencoded
>
< HTTP/1.1 200 OK
< Access-Control-Allow-Origin: *
< Content-Type: application/json
< Date: Fri, 28 Nov 2025 14:27:08 GMT
< Content-Length: 151
<
{"id":"jhvszzUsgig1","time":1764340028,"expires":1764426428,"event":"message","topic":"universal-topic","message":"这是认证用户发布的消息"}
* Connection #0 to host localhost left intact
```

验证成功后，要设置https启动，先生成证书：

```
ls /etc/letsencrypt/live/ntfy.xmsx.dpdns.org/
fullchain.pem  privkey.pem
chown -R ntfy:ntfy /etc/letsencrypt/live/ntfy.xmsx.dpdns.org/
```

然后修改配置

```
mv /etc/ntfy/server.yml /etc/ntfy/server.yml.bak

cat << 'EOF' > /etc/ntfy/server.yml

# 监听HTTPS
listen-https: "0.0.0.0:443"

# 证书路径
cert-file: "/etc/letsencrypt/live/ntfy.xmsx.dpdns.org/fullchain.pem"
key-file: "/etc/letsencrypt/live/ntfy.xmsx.dpdns.org/privkey.pem"

# 缓存配置
cache-file: "/var/lib/ntfy/cache.db"
cache-duration: "7d"

# CORS限定具体域名
cors-origins: ["https://ntfy.xmsx.dpdns.org"]

# 日志级别
log-level: "info"

# 认证配置
auth-file: "/var/lib/ntfy/user.db"
auth-default-access: "deny-all"
EOF

```

验证配置是否生效, 虽然80和443都被nginx占用了，但是至少验证成功了

```
ntfy serve --config /etc/ntfy/server.yml
2025/11/28 20:58:10 INFO Listening on :80[http] 0.0.0.0:443[https], ntfy 2.15.0, log level is INFO (tag=startup)
2025/11/28 20:58:10 FATAL listen tcp :80: bind: address already in use (exit_code=1)
listen tcp :80: bind: address already in use
```

但是现在的/etc/ntfy/server.yml是把证书配置在ntfy上，如果要使用nginx，还需取消ntfy的证书，然后把证书地址配置在nginx上，修改server.yml如下：

```
# /etc/ntfy/server.yml (修正后的配置)

# 确保只有这一行是活动的，并且端口是 8080
listen-http: "127.0.0.1:8080" 

# --- 以下行必须被删除或注释掉 ---
# # listen-https: "0.0.0.0:443" 
# # tls-cert: "/..."
# # tls-key: "/..."
# # cert-file: "/..."
# # key-file: "/..."
# -----------------------------------

# 缓存配置 (保留)
cache-file: "/var/lib/ntfy/cache.db"
cache-duration: "7d"

# CORS限定具体域名 (保留)
cors-origins: ["https://ntfy.xmsx.dpdns.org"]

# 日志级别 (保留)
log-level: "info"

# 认证配置 (保留)
auth-file: "/var/lib/ntfy/user.db"
auth-default-access: "deny-all"
```

然后配置nginx里面的配置文件 ntfy.conf

```
cat << 'EOF' > /etc/nginx/conf.d/ntfy.conf

# 重定向 HTTP 到 HTTPS (可选，推荐)
server {
    listen 80;
    server_name ntfy.xmsx.dpdns.org;

    # 返回 301 永久重定向到 HTTPS
    return 301 https://$host$request_uri;
}


# HTTPS 配置
server {
    listen 443 ssl;
    http2 on;
    server_name ntfy.xmsx.dpdns.org;

    # --- SSL 证书配置 (使用您的路径) ---
    ssl_certificate /etc/letsencrypt/live/xmsx.dpdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xmsx.dpdns.org/privkey.pem;

    # --- ntfy 反向代理配置 ---
    location / {

        # ntfy 服务器的本地监听地址 (请根据您的 ntfy 配置调整端口，例如 8080)
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # 保持 WebSocket 长连接所必需的设置
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # 客户端最大主体大小
        client_max_body_size 25m;
    }
}
EOF
```

浏览器打开[ntfy](https://ntfy.xmsx.dpdns.org/)即可访问
测试也可以成功

```
curl -u sjwayrhz:vwv56ty7 -H "Title: My-Test-Message-12345" -d "This is the body content" https://ntfy.xmsx.dpdns.org/universal-topic
```

然后可以在homeserver.yaml中配置网关

```
cat /etc/matrix-synapse/homeserver.yaml
```

添加最后2行

```
pid_file: "/var/run/matrix-synapse.pid"
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['::1', '127.0.0.1']
    resources:
      - names: [client, federation]
        compress: false
database:
  name: sqlite3
  args:
    database: /var/lib/matrix-synapse/homeserver.db
log_config: "/etc/matrix-synapse/log.yaml"
media_store_path: /var/lib/matrix-synapse/media
signing_key_path: "/etc/matrix-synapse/homeserver.signing.key"
trusted_key_servers:
  - server_name: "matrix.org"

server_name: "matrix.xmsx.dpdns.org"
pid_file: "/var/run/matrix-synapse.pid"

enable_registration: false
registration_shared_secret: "WQtYKxi8bZBJVzxE7vI8R0glY7E2BY5Y"

trusted_key_servers:
  - server_name: "matrix.org"

turn_uris: ["turn:matrix.xmsx.dpdns.org:3478?transport=udp"]
turn_shared_secret: "a28ba88cd6660d00da7260e95753671bc4252ede01714c8bb076afbeca8e8c2a"
turn_user_lifetime: 86400

allowed_push_gateways:
  - "ntfy.xmsx.dpdns.org"
```

重启synapse

```
 systemctl restart matrix-synapse
```

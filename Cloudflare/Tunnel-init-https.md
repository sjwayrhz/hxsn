# 使用acme.sh生成证书

详情请见
![DNS-01手动申请证书](../Nginx_conf/DNS-01手动申请证书.md)

生成的证书位于

```
Your cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/test.taoistmonk.
Your cert key is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/test.
The intermediate CA cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/ca.
And the full-chain cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/fullchain.cer
```

# 配置 Docker + Nginx 使用证书

修改后的www.conf配置如下：

```
# HTTP 80 - 重定向到 HTTPS
server {
    listen 80;
    server_name test.taoistmonk.dpdns.org;

    # 所有 HTTP 请求跳转到 HTTPS
    return 301 https://$host$request_uri;
}

# HTTPS 443
server {
    listen 443 ssl;
    server_name test.taoistmonk.dpdns.org;

    root  /usr/share/nginx/html;
    index index.html index.htm;

    # 使用 acme.sh 生成的 ECC 证书
    ssl_certificate /etc/letsencrypt/test.taoistmonk.dpdns.org_ecc/fullchain.cer;
    ssl_certificate_key /etc/letsencrypt/test.taoistmonk.dpdns.org_ecc/test.taoistmonk.dpdns.org.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    location / {
        try_files $uri $uri/ =404;
    }

    error_page 404 /404.html;
    location = /404.html {
        root /usr/share/nginx/html;
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }

    location ~ /\. {
        deny all;
    }

    access_log /var/log/nginx/test.taoistmonk.dpdns.org.access.log;
    error_log  /var/log/nginx/test.taoistmonk.dpdns.org.error.log warn;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;
}
```

测试配置是否正确

```
docker run --rm -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  -v /usr/share/nginx/html:/usr/share/nginx/html \
  -v /root/.acme.sh/test.taoistmonk.dpdns.org_ecc:/etc/letsencrypt/test.taoistmonk.dpdns.org_ecc \
  nginx:1.29.3-alpine nginx -t
```

现在应该这样启动docker里面的nginx了

```
docker run -d --name nginx-mini \
  -p 80:80 -p 443:443 \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d:ro \
  -v /usr/share/nginx/html:/usr/share/nginx/html \
  -v /root/.acme.sh/test.taoistmonk.dpdns.org_ecc:/etc/letsencrypt/test.taoistmonk.dpdns.org_ecc:ro \
  --user root \
  nginx:1.29.3-alpine
```

# 在tunnel界面配置

Service 选择 <HTTPS://192.168.6.8:443>

需要选择Additional application settings，然后在TLS那里设置打开 【No TLS Verify】

```
No TLS Verify
Disables TLS verification of the certificate presented by your origin. Will allow any certificate from the origin to be accepted.
```

这个意思是，不使用本地的https证书，而是采用远程的cloudflare证书。

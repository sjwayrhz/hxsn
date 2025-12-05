# 当tennel配置的后端是http服务

docker启动nginx

```
docker run --rm -d \
  --name nginx-mini \
  -p 80:80 \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  -v /usr/share/nginx/html:/usr/share/nginx/html \
  nginx:1.29.3-alpine
```

检查由docker启动的nginx配置如下

```
# cat /etc/nginx/conf.d/www.conf
server {
    listen 80;
    server_name www.taoist.ggff.net;

    root  /usr/share/nginx/html;
    index index.html index.htm;

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

    access_log /var/log/nginx/www.taoist.ggff.net.access.log;
    error_log  /var/log/nginx/www.taoist.ggff.net.error.log warn;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;
}
```

Published application routes 配置如下：

```
Hostname: test.taoistmonk.dpdns.org
Service: HTTP://192.168.6.8
```

浏览器打开链接 `https://test.taoistmonk.dpdns.org` 会自动跳转到https，查看ssl证书是cloudflare临时签署的。
意味着，只要在本地搭建http 80端口的服务，然后映射到cloudflare，不但可以公网映射，还可以获得cloudflare的https证书。

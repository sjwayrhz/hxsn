## 80端口的静态页面

docker启动脚本

```
docker run --rm -d \
  --name nginx-mini \
  -p 80:80 \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  -v /usr/share/nginx/html:/usr/share/nginx/html \
  nginx:1.29.3-alpine
```

```
server {
    listen 80;
    server_name your.domain.com;

    root /usr/share/nginx/html;
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

    access_log /var/log/nginx/your.domain.com.access.log;
    error_log  /var/log/nginx/your.domain.com.error.log warn;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;
}
```

Https启动配置

```
server {
    listen 80;
    server_name your.domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your.domain.com;

    root /usr/share/nginx/html;
    index index.html index.htm;

    ssl_certificate /etc/nginx/ssl/your.domain.com.crt;
    ssl_certificate_key /etc/nginx/ssl/your.domain.com.key;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

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

    access_log /var/log/nginx/your.domain.com.access.log;
    error_log  /var/log/nginx/your.domain.com.error.log warn;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/svg+xml;
    gzip_min_length 1024;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Frame-Options SAMEORIGIN;
}
```

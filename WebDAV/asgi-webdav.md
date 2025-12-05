# 快速启动

使用如下命令可以尝试启动

```
docker run --rm \
    -p 8000:8000 \
    -v /data:/data \
    --name asgi-webdav \
    ray1ex/asgi-webdav
```

默认情况下，这个容器会使用以下默认账号：

- 用户名 (Username): username
- 密码 (Password): password

强烈建议您不要使用默认的用户名和密码

在您的共享目录（例如 /data）内创建以下文件：/data/webdav.json

然后docker在启动的时候需要添加--config /data/webdav.json

```
{
    "accounts": [
        {
            "username": "my_new_user",
            "password": "my_secure_password",
            "permissions": "all"
        }
    ]
}
```

重启容器

```
docker run --rm \
    -p 8000:8000 \
    -v /data:/data \
    --name asgi-webdav \
    ray1ex/asgi-webdav \
    python -m asgi_webdav --config /data/webdav.json
```

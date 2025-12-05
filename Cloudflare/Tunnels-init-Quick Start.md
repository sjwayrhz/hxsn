# 简要说明

tunnels在cloudflare上是免费使用的，地址：[one-dash-cloudflare](https://one.dash.cloudflare.com/)。
登录之后，发现是在Networks>Connectors里面配置。
设定一个tunnel名字之后，可以选择使用docker启动，命令如下：

```
docker run cloudflare/cloudflared:latest tunnel --no-autoupdate run --token &your_token
```

如果想后台启动cloudflare插件，可以执行如下命令行

```
docker run -d --name cloudflared-tunnel \
  --restart unless-stopped \
  cloudflare/cloudflared:latest tunnel --no-autoupdate run \
  --token <token>
```

然后配置Published application routes就可以了

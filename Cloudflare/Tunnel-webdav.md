## 本地启动一个webdav

```
docker run -d  --rm -p 8000:8000 sjwayrhz/webdav:asgi
```

然后在本地浏览器打开 localhost:8000 之后输入用户名admin，密码admin  
这就是本地的webdav本地服务器  

## 映射到公网

通过docker启动tunnel可以将这个本地的内网服务映射到公网  
启动方法如下：

```
docker run -d cloudflare/cloudflared:latest tunnel --no-autoupdate run --token <token>
```

相关配置如下：
>Published application routes

```
{
    Hostname Domain Path : link.ectw.netlib.re 
    Service :  HTTP://host.docker.internal:8000
}
```

因为webdav和tunnel都是通过容器启动的，所以他们之间相互访问只能使用host.docker.internal而不能使用localhost.  
映射之后，浏览器打开`https://link.ectw.netlib.re`访问正常  
也可以通过linux系统下载文件

```
wget --user=admin --password=admin https://link.ectw.netlib.re/path/to/file
```

## 参考链接

[github](https://github.com/sjwayrhz/webdav)  
[docker hub](https://hub.docker.com/repository/docker/sjwayrhz/webdav/general)

## 尝试启动

```
docker run --rm -p 8000:8000 sjwayrhz/webdav:asgi
```

容器暴露的是8000端口，存放文件的位置位于容器的/data目录，账号和密码默认都是admin
添加文件到容器,举例，新建test文件夹，然后放入a.txt文件和Dockerfile，目录结果如下

```
root@dynamic:~# tree test/
test/
├── Dockerfile
└── a.txt

1 directory, 2 files
```

其中，Dockerfile内容如下

```
FROM sjwayrhz/webdav:asgi
ADD . /data
RUN rm -f /data/Dockerfile
CMD [ "/app/entrypoint.sh" ]
```

然后可以构建镜像

```
 docker build -t webdav:test .
```

启动镜像

```
docker run -d --rm  -p 8000:8000 -v /data:/data webdav:test
```

启动之后，打开浏览器，访问 <http://localhost:8000> 使用默认账号和密码都是admin登录，即可看到a.txt文件已经存在了。还可以通过webadv工具访问，例如windows上的WinSCP登录。

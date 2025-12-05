使用cloudflare的tunnel可以生成直链，现在举例子，我将打包2个文件成tar包

## 需要保存的文件打包

```
犬夜叉 完结篇第1集.mp4
犬夜叉 完结篇第1集.mp4
test.tar
```

也就是test.tar是由犬夜叉 完结篇第1集.mp4和犬夜叉 完结篇第1集.mp4打包得来  

## 将test.tar放入本地webdav

本地计算机打开WinSCP,然后访问localhost:8000，账号密码admin，将test.tar放进去

## tunnel映射成公网直链

启动本地cloudflared,然后配置如下：

```
{
    Hostname Domain Path : link.ectw.netlib.re 
    Service :  HTTP://host.docker.internal:8000
}
```

获得直连是 `https://link.ectw.netlib.re/test.tar`  
然后打开项目 `https://github.com/sjwayrhz/docker-images`  
修改 tasks/index.yml，确定执行github action.

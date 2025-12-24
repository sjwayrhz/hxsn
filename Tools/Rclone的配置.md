## 创建磁盘

```shell
 mkdir /mnt/gdrive
```



## 后台启动rclone 

```shell
rclone mount gdrive:/douyin_records /mnt/gdrive \
  --allow-other \
  --vfs-cache-mode writes \
  --daemon
```

## ./config/URL_config.ini

```
vi ./config/URL_config.ini
```

内容为

```
https://live.douyin.com/ssjzt777
https://live.douyin.com/Ain81314820
```

## 生产配置文件

运行一个临时容器来生成配置，初始化

```
docker run -it --rm \
  -v $(pwd)/config:/config \
  ihmily/douyin-live-recorder:latest
```


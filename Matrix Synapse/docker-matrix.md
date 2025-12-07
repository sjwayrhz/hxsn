# 阐述

本次文档是学习[docker-matrix](https://github.com/AVENTER-UG/docker-matrix/blob/master/Example.configs.md)的学习笔记

# 部署

本次部署的相关变量，域名为matrix.monk.de5.net

## 步骤一： 域名设定

在cloudflare上绑定的域名monk.de5.net设定内容如下：

```
Type		Name							Content					Port
A			matrix							150.230.215.187
SRV			_matrix-federation._tcp			  matrix.monk.de5.net	   8448
SRV			_matrix._tcp					 matrix.monk.de5.net       8448
```

Priority 和 Weight 设置成 10 和 5 就好

测试设定是否成功，一般情况下，方法一稍快。

```
方法一：
dig @8.8.8.8 SRV _matrix._tcp.monk.de5.net
方法二：
dig -t SRV _matrix._tcp.monk.de5.net
```

正确反馈的结果是反馈了ANSWER: 1, 

```shell
dig @8.8.8.8 SRV _matrix._tcp.monk.de5.net | grep ANSWER
;; flags: qr rd ra; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; ANSWER SECTION:
```

## 步骤二：生成配置文件

 这里用root用户生成，以防止权限不足：

```
docker run --user=root \
>   -v /opt/synapse:/data --rm \
>   -e SERVER_NAME=matrix.monk.de5.net \
>   -e REPORT_STATS=no \
>   avhost/docker-matrix:v1.143 generate
```

得到的如下文件：

```
ls -l /opt/synapse 
total 24
drwxr-xr-x 2 root root 4096 Dec  7 10:18 ./
drwxr-xr-x 9 root root 4096 Dec  7 10:17 ../
-rw------- 1 root root 1334 Dec  7 10:18 homeserver.yaml
-rw-r--r-- 1 root root 2714 Dec  7 10:18 matrix.monk.de5.net.log.config
-rw-r----- 1 root root   59 Dec  7 10:18 matrix.monk.de5.net.signing.key
-rw-r--r-- 1 root root  282 Dec  7 10:18 turnserver.conf
```


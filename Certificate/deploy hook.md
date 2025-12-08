# deploy hook 的使用方法

在使用certbot生成泛域名证书之后，证书会在以下文件夹：

```shell
ll /etc/letsencrypt/live/xmsx.dpdns.org/

total 12
drwxr-xr-x 2 root root 4096 Dec  8 01:25 ./
drwx------ 3 root root 4096 Dec  8 01:25 ../
-rw-r--r-- 1 root root  692 Dec  8 01:25 README
lrwxrwxrwx 1 root root   38 Dec  8 01:25 cert.pem -> ../../archive/xmsx.dpdns.org/cert1.pem
lrwxrwxrwx 1 root root   39 Dec  8 01:25 chain.pem -> ../../archive/xmsx.dpdns.org/chain1.pem
lrwxrwxrwx 1 root root   43 Dec  8 01:25 fullchain.pem -> ../../archive/xmsx.dpdns.org/fullchain1.pem
lrwxrwxrwx 1 root root   41 Dec  8 01:25 privkey.pem -> ../../archive/xmsx.dpdns.org/privkey1.pem
```

但是默认生成的目录文件，他们的权限并不适合普通用户去使用，例如 matrix-synapse在启动的时候，并不是使用root用户启动，对于证书的要求就很苛刻。

这时，就需要复制certbot默认目录下的证书到指定的位置，例如：

```
cp /etc/letsencrypt/live/xmsx.dpdns.org/fullchain.pem /etc/matrix-synapse/certs/fullchain.pem
cp /etc/letsencrypt/live/xmsx.dpdns.org/privkey.pem /etc/matrix-synapse/certs/privkey.pem
chmod 640 /etc/matrix-synapse/letsencrypt/privkey.pem
chown matrix-synapse:matrix-synapse /etc/matrix-synapse/letsencrypt/privkey.pem
```

certbot是会自动更新的，但是拷贝到其他目录的证书，并不会自动更新

当certbot在更新证书的时候，会自动执行 `/etc/letsencrypt/renewal-hooks/deploy`目录下的脚本，那么可以在这里添加synapse.sh，自动更新`/etc/matrix-synapse/certs`目录下的证书文件。

```
vim /etc/letsencrypt/renewal-hooks/deploy/synapse.sh
```

内容为

```
#!/bin/bash
# Matrix Synapse 证书更新脚本

# 定义 Synapse 专用目录
SYNAPSE_CERT_DIR="/etc/matrix-synapse/certs/"
mkdir -p "$SYNAPSE_CERT_DIR"
chown matrix-synapse:matrix-synapse "$SYNAPSE_CERT_DIR"
chmod 700 "$SYNAPSE_CERT_DIR"

# 复制证书
cp /etc/letsencrypt/live/xmsx.dpdns.org/fullchain.pem "$SYNAPSE_CERT_DIR/fullchain.pem"
cp /etc/letsencrypt/live/xmsx.dpdns.org/privkey.pem "$SYNAPSE_CERT_DIR/privkey.pem"

# 修改权限
chown matrix-synapse:matrix-synapse "$SYNAPSE_CERT_DIR/fullchain.pem" "$SYNAPSE_CERT_DIR/privkey.pem"
chmod 640 "$SYNAPSE_CERT_DIR/privkey.pem"

# 重启 Synapse 服务
systemctl restart matrix-synapse
```

设置可执行权限

```
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/synapse.sh
```

总结：

deploy hook ， 就是certbot renew的时候，自动执行位于`/etc/letsencrypt/renewal-hooks/deploy`目录下的shell脚本。
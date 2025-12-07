在certbot的使用中，拷贝原来的证书到其他文件夹，需要持续更新的办法

```
sudo certbot renew --deploy-hook "cp /etc/letsencrypt/live/matrix.xmsx.dpdns.org/* /etc/matrix-synapse/certs/ && chown -R matrix-synapse:matrix-synapse /etc/matrix-synapse/certs"
```

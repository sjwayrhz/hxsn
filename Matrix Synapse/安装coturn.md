## Install coturn TURN

Now, install the coturn TURN  using the following command.

```shell
sudo apt install -y coturn
```

add configure context in turn's configfile

```shell
sudo cat >> /etc/turnserver.conf << EOF
listening-port=3478
tls-listening-port=5349
listening-ip=0.0.0.0
relay-ip=0.0.0.0
fingerprint
lt-cred-mech
use-auth-secret
static-auth-secret=a28ba88cd6660d00da7260e95753671bc4252ede01714c8bb076afbeca8e8c2a
realm=matrix.hsafj.dpdns.org
total-quota=100
bps-capacity=0
stale-nonce=600
cert=/etc/letsencrypt/live/matrix.hsafj.dpdns.org/fullchain.pem
pkey=/etc/letsencrypt/live/matrix.hsafj.dpdns.org/privkey.pem
EOF
```

checkout the file added success

```shell
sudo tail -n 14 /etc/turnserver.conf
```

restart turn

```shell
sudo systemctl restart coturn
sudo systemctl status coturn
```



cloudflare有个官方的turn ,不用搭建，即可直接使用

```
stun.cloudflare.com:3478
```


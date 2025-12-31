# How to Create a Chat Server Using Matrix Synapse and Element on Ubuntu 24.04

## Step 1 – Add Matrix Synapse Repository

By default, the Matrix Synapse package is not included in the Ubuntu default repository, so you will need to install it from its official repository.

First, download the Matrix Synapse GPG key.

```shell
wget -O /usr/share/keyrings/matrix-org-archive-keyring.gpg https://packages.matrix.org/debian/matrix-org-archive-keyring.gpg
```

Then, add the Matrix Synapse repository to the APT source file.

```shell
echo "deb [signed-by=/usr/share/keyrings/matrix-org-archive-keyring.gpg] https://packages.matrix.org/debian/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/matrix-org.list
```

Next, update the package index using the following command.

```shell
apt update 
```

## Step 2 – Install Matrix Synapse

Now, install the Matrix Synapse package using the following command.

```shell
apt install matrix-synapse-py3
```

You will be asked to provide your domain name as shown below:

```
Name of the server: matrix.hsafj.dpdns.org
Report homeserver usage statistics? [yes/no] : no
```

Provide your domain name and click on OK. Once Matrix Synapse is installed, start the Matrix Synapse service using the following command.

At this point, Matrix Synapse is started and listens on port 8008. You can verify it using the command given below:

```
apt install iproute2
ss -plnt | grep 8008
```

Output.

```ini
null
```



## Step 3 – Configure Matrix Synapse

编辑文件

```bash
vim /etc/matrix-synapse/homeserver.yaml
```

内容为

```yaml
server_name: "matrix.hsafj.dpdns.org"
public_baseurl: "https://matrix.hsafj.dpdns.org/"

listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['0.0.0.0']
    resources:
      - names: [client, federation]
        compress: false

database:
  name: sqlite3
  args:
    database: /var/lib/matrix-synapse/homeserver.db

push:
  include_content: true
  gateways:
    - method: http
      url: "https://ntfy.hsafj.dpdns.org/_matrix/push/v1/notify"

turn_urb: []
stun_servers:
  - "stun.cloudflare.com:3478"

pid_file: "/var/run/matrix-synapse.pid"
log_config: "/etc/matrix-synapse/log.yaml"
media_store_path: /var/lib/matrix-synapse/media
signing_key_path: "/etc/matrix-synapse/homeserver.signing.key"
trusted_key_servers:
  - server_name: "matrix.org"

report_stats: false
suppress_key_server_warning: true
macaroon_secret_key: "hsafj_dpdns_secret_macaroon_secret_key"
registration_shared_secret: "hsafj_dpdns_secret_registration_shared_secret"
form_secret: "hsafj_dpdns_secret_form_secret"
enable_registration_without_verification: true
```

Step 4 –注册用户和重新启动

启动

```
/opt/venvs/matrix-synapse/bin/synctl start /etc/matrix-synapse/homeserver.yaml
```

注册

```
ss -lntp | grep 8008
LISTEN 0      50           0.0.0.0:8008       0.0.0.0:*    users:(("python",pid=967,fd=13))

/opt/venvs/matrix-synapse/bin/register_new_matrix_user -c /etc/matrix-synapse/homeserver.yaml http://localhost:8008
```

启动cloudflare tunnel

```bash
nohup cloudflared tunnel run --token eyJhIjoiYjE5OTY2YmVjODMzMTEyZGZjY2JjNjAyYzkyM2NmY2YiLCJ0IjoiMmU1MDA0NmQtZDExMi00MjEwLWJlNjgtYWRmNTFmMDdiM2Y0IiwicyI6IlpUYzFNVEF6TXpjdFl6UmtOaTAwWkRobUxXSmtNVFV0T1RCbE1qVXpaakZtWXpVeiJ9 > /var/log/cloudflared.log 2>&1 &
```

查看日志

```
tail -f /var/log/matrix-synapse/homeserver.log
```

**确认进程是否存在**

Bash

```
ps aux | grep synapse
```

**检查端口监听** 使用你之前安装的 `ss` 命令确认 8008 端口是否处于 `LISTEN` 状态：

Bash

```
ss -tunlp | grep 8008
```
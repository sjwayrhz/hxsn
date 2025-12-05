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
apt update -y
```

## Step 2 – Install Matrix Synapse

Now, install the Matrix Synapse package using the following command.

```shell
apt install matrix-synapse-py3
```

You will be asked to provide your domain name as shown below:

```
Name of the server: matrix.xmsx.dpdns.org
Report homeserver usage statistics? [yes/no] : no
```

Provide your domain name and click on OK. Once Matrix Synapse is installed, start the Matrix Synapse service using the following command.

You can now verify the status of Matrix Synapse using the following command.

```shell
systemctl status matrix-synapse
```

At this point, Matrix Synapse is started and listens on port 8008. You can verify it using the command given below:

```
ss -plnt | grep 8008
```

Output.

```ini
LISTEN 0      50         127.0.0.1:8008      0.0.0.0:*    users:(("python",pid=2170,fd=14))        
LISTEN 0      50             [::1]:8008         [::]:*    users:(("python",pid=2170,fd=13))  
```

## Step 3 – Install coturn TURN

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
realm=matrix.xmsx.dpdns.org
total-quota=100
bps-capacity=0
stale-nonce=600
cert=/etc/letsencrypt/live/matrix.xmsx.dpdns.org/fullchain.pem
pkey=/etc/letsencrypt/live/matrix.xmsx.dpdns.org/privkey.pem
EOF
```

checkout the file added success

```shell
sudo tail -n 14 /etc/turnserver.conf
```

restart turn

```shell
sudo systemctl restart coturn
```

## Step 4 – Configure Matrix Synapse

First, generate the secret key using the following command.

```shell
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1
```

Output.

```
WQtYKxi8bZBJVzxE7vI8R0glY7E2BY5Y
```

[Install Nginx](..//Nginx_conf/Ubuntu%20Install%20Nginx.md)
Next, edit the Matrix Synapse main configuration file.

```shell
rm -f /etc/matrix-synapse/homeserver.yaml
cat << 'EOF' >> /etc/matrix-synapse/homeserver.yaml
pid_file: "/var/run/matrix-synapse.pid"
listeners:
  - port: 8008
    tls: false
    type: http
    x_forwarded: true
    bind_addresses: ['::1', '127.0.0.1']
    resources:
      - names: [client, federation]
        compress: false
database:
  name: sqlite3
  args:
    database: /var/lib/matrix-synapse/homeserver.db
log_config: "/etc/matrix-synapse/log.yaml"
media_store_path: /var/lib/matrix-synapse/media
signing_key_path: "/etc/matrix-synapse/homeserver.signing.key"
trusted_key_servers:
  - server_name: "matrix.org"

server_name: "matrix.xmsx.dpdns.org"
pid_file: "/var/run/matrix-synapse.pid"

enable_registration: false
registration_shared_secret: "WQtYKxi8bZBJVzxE7vI8R0glY7E2BY5Y"

trusted_key_servers:
  - server_name: "matrix.org"

turn_uris: ["turn:matrix.xmsx.dpdns.org:3478?transport=udp"]
turn_shared_secret: "a28ba88cd6660d00da7260e95753671bc4252ede01714c8bb076afbeca8e8c2a"
turn_user_lifetime: 86400
EOF
```

Save and close the file, then restart the Matrix Synapse service to reload the changes.

```shell
systemctl restart matrix-synapse
```

## Step 5 – Create an Administrative User

```shell
register_new_matrix_user -c /etc/matrix-synapse/homeserver.yaml http://localhost:8008
```

Define your user and password as shown below:

```
New user localpart [root]: admin
Password: eovGY140NjURQ
Confirm password: eovGY140NjURQ
Make admin [no]: yes
Sending registration request...
Success!
```

## Step 6 – Download Let’s Encrypt SSL

Install the prerequisites:

Next, install the Certbot Let’s Encrypt client using the following commands.

```shell
sudo snap install core
sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

Next, download the Let’s Encrypt SSL for your domain.

```
certbot certonly --nginx --agree-tos --no-eff-email --staple-ocsp --preferred-challenges http -m sjwayrhz@gmail.com -d matrix.xmsx.dpdns.org
```

Next, generate the dhparam using the following command.

```
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096
```

## Step 7 – Configure Nginx for Matrix Synapse

Next, you will need to configure Nginx as a reverse proxy for Matrix Synapse.

First, edit the Nginx main configuration file.

```
vim /etc/nginx/nginx.conf
```

Add the following line after the line http{:

```
server_names_hash_bucket_size 64;
```

Next, create an Nginx virtual host configuration file for Matrix Synapse.

```
cat << 'EOF' >> /etc/nginx/conf.d/synapse.conf 
# enforce HTTPS
server {
    # Client port
    listen 80;
    server_name matrix.xmsx.dpdns.org;
    return 301 https://$host$request_uri;
}

server {
    server_name matrix.xmsx.dpdns.org;

    # Client port
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    # Federation port
    listen 8448 ssl http2 default_server;
    listen [::]:8448 ssl http2 default_server;

    access_log  /var/log/nginx/synapse.access.log;
    error_log   /var/log/nginx/synapse.error.log;

    # TLS configuration
    ssl_certificate /etc/letsencrypt/live/matrix.xmsx.dpdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/matrix.xmsx.dpdns.org/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/matrix.xmsx.dpdns.org/chain.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    location /_matrix {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
        # Nginx by default only allows file uploads up to 1M in size
        # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
        client_max_body_size 10M;
    }
}

# This is used for Matrix Federation
# which is using default TCP port '8448'
server {
    listen 8448 ssl;
    server_name matrix.xmsx.dpdns.org;

    ssl_certificate /etc/letsencrypt/live/matrix.xmsx.dpdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/matrix.xmsx.dpdns.org/privkey.pem;

    location / {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
    }
}
EOF
```

Save and close the file, then reload Nginx to apply the changes.

```
systemctl restart nginx
```

You can now verify the Matrix Synapse installation using the URL **<https://matrix.xmsx.dpdns.org:8448/_matrix/static/>** on your web browser. You should see the following screen:

Congratulations! You have successfully installed Matrix Synapse on Ubuntu 24.04

Use shell script for  add 、del、list、select

```
cat << 'EOF' >> matrix_user.sh
#!/bin/bash
# matrix_user.sh
# 用法: matrix_user.sh add|del|mod|list 用户名 密码 角色
# 角色: 1=管理员, 0=普通用户
# homeserver.db 路径

DB="/var/lib/matrix-synapse/homeserver.db"
CONFIG="/etc/matrix-synapse/homeserver.yaml"

action=$1
username=$2
password=$3
admin_flag=$4

case "$action" in
  add)
    if [ -z "$username" ] || [ -z "$password" ]; then
      echo "Usage: $0 add <username> <password> [admin_flag]"
      exit 1
    fi
    # 使用官方命令注册用户，确保密码可用
    register_new_matrix_user -c "$CONFIG" "http://localhost:8008" <<EOF
$username
$password
EOF

    # 设置管理员标记（如果 admin_flag=1）
    if [ "$admin_flag" = "1" ]; then
      sqlite3 "$DB" "UPDATE users SET admin=1 WHERE name='@${username}:$(grep 'server_name:' $CONFIG | awk '{print $2}')';"
    fi
    echo "User $username added."
    ;;

  del)
    if [ -z "$username" ]; then
      echo "Usage: $0 del <username>"
      exit 1
    fi
    sqlite3 "$DB" "DELETE FROM users WHERE name LIKE '%$username%';"
    echo "User $username deleted."
    ;;

  mod)
    if [ -z "$username" ] || [ -z "$password" ]; then
      echo "Usage: $0 mod <username> <new_password>"
      exit 1
    fi
    # 官方命令修改密码
    register_new_matrix_user -c "$CONFIG" "http://localhost:8008" --reset-password <<EOF
$username
$password
EOF
    echo "Password for $username updated."
    ;;

  list)
    sqlite3 "$DB" "SELECT name, admin FROM users;"
    ;;

  *)
    echo "Usage: $0 {add|del|mod|list} ..."
    exit 1
    ;;
esac
# 添加普通用户
# bash matrix_user.sh add bob mypassword 0
# # 添加管理员
# bash matrix_user.sh add alice mypassword 1
# # 修改密码
# bash matrix_user.sh mod bob newpassword
# # 删除用户
# bash matrix_user.sh del alice
# # 列出用户
# bash matrix_user.sh list
EOF
```

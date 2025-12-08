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
sudo systemctl status coturn
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
      - names: [client]
        compress: false

  - port: 8448
    tls: true
    type: http
    bind_addresses: ['::', '0.0.0.0']
    resources:
      - names: [federation]
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

enable_registration: false
registration_shared_secret: "WQtYKxi8bZBJVzxE7vI8R0glY7E2BY5Y"

turn_uris: ["turn:matrix.xmsx.dpdns.org:3478?transport=udp"]
turn_shared_secret: "a28ba88cd6660d00da7260e95753671bc4252ede01714c8bb076afbeca8e8c2a"
turn_user_lifetime: 86400

# Federation TLS Certificates (REQUIRED for port 8448)
tls_certificate_path: "/etc/matrix-synapse/certs/fullchain.pem"
tls_private_key_path: "/etc/matrix-synapse/certs/privkey.pem"

allowed_push_gateways:
  - "ntfy.xmsx.dpdns.org"
EOF
```

 Install the Certbot Let’s Encrypt client using the following commands.

```
sudo snap install core
sudo snap install --classic certbot
certbot --version
```

create certs

```
sudo apt install python3-certbot-dns-cloudflare 
sudo mkdir /etc/ssl/cloudflare

cat << 'EOF' >> /etc/ssl/cloudflare/xmsx.dpdns.org.ini
dns_cloudflare_api_token = z4Bl2u4iySQJulJAe-3fsO8o3dM6Os_CaRQ5u0Wk
EOF

chmod 600 /etc/ssl/cloudflare/xmsx.dpdns.org.ini

sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/ssl/cloudflare/xmsx.dpdns.org.ini \
  -d xmsx.dpdns.org -d '*.xmsx.dpdns.org'
```

Copy certificate

```
mkdir /etc/matrix-synapse/certs
cp /etc/letsencrypt/live/xmsx.dpdns.org/* /etc/matrix-synapse/certs
chown :matrix-synapse  /etc/matrix-synapse/certs/*
chmod 640 /etc/matrix-synapse/certs/privkey.pem
```

generate the dhparam using the following command.

```
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparam.pem 4096
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

## Step 6 – Configure Nginx for Matrix Synapse

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
# 1. HTTP to HTTPS Redirection (Port 80)
server {
    listen 80;
    listen [::]:80;
    server_name matrix.xmsx.dpdns.org;

    # Redirect all HTTP traffic to HTTPS (Port 443)
    return 301 https://$host$request_uri;
}

# 2. Main Synapse Server (Client API - Port 443)
server {
    server_name matrix.xmsx.dpdns.org;

    # Client port (HTTPS)
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on; # Moved http2 on as a separate directive

    access_log  /var/log/nginx/synapse.access.log;
    error_log   /var/log/nginx/synapse.error.log;

    # TLS config
    ssl_certificate /etc/letsencrypt/live/xmsx.dpdns.org/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/xmsx.dpdns.org/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/xmsx.dpdns.org/chain.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_dhparam /etc/ssl/certs/dhparam.pem;

    # Client API Proxy to Synapse 8008
    location /_matrix {
        proxy_pass http://localhost:8008;
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header Host $host;
        client_max_body_size 10M;
    }

    # Well-known for client discovery (Correct and Necessary)
    location /.well-known/matrix/client {
        return 200 '{"m.homeserver": {"base_url": "https://matrix.xmsx.dpdns.org"}}';
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }

    # Well-known for federation discovery (Correct and Necessary)
    location /.well-known/matrix/server {
        return 200 '{"m.server": "matrix.xmsx.dpdns.org"}';
        default_type application/json;
        add_header Access-Control-Allow-Origin *;
    }
}
EOF
```

Save and close the file, then reload Nginx to apply the changes.

```
systemctl restart nginx
```

You can now verify the Matrix Synapse installation using the URL **<https://matrix.xmsx.dpdns.org:8448/_matrix/static/>** on your web browser. You should see the following screen:

Also can test in this website [federationtester](https://federationtester.matrix.org/)

Congratulations! You have successfully installed Matrix Synapse on Ubuntu 24.04

add user

```
register_new_matrix_user -c /etc/matrix-synapse/homeserver.yaml http://localhost:8008
```

select user

```
sqlite3 /var/lib/matrix-synapse/homeserver.db "SELECT name, admin FROM users;"
```

delete user

```
sqlite3 /var/lib/matrix-synapse/homeserver.db "DELETE FROM users WHERE name LIKE '%test%';"
```

# certbot 申请证书

## 安装certbot

举例，在ubuntu 24.04中的安装步骤

```shell
# 移除旧的 certbot 安装
sudo apt remove certbot
# 安装 snapd
sudo snap install core
sudo snap refresh core
# 安装 Certbot
sudo snap install --classic certbot
```

测试安装域名 `example.dpdns.org` 的泛域名证书

## 生成泛域名证书 

在生成泛域名证书的时候，如果是域名挂载在cloudflare，那么可以使用cloudflare的插件，并且可以开启小黄伞。

### 步骤一：登录cloudflare官网，生成A记录： Type A  , Name @ ，IPv4 address

| Type | Name |  IPv4 address   |
| :--: | :--: | :-------------: |
|  A   |  @   | 150.230.215.187 |



### 步骤二：获取 Cloudflare API 密钥

1. 登录你的 **Cloudflare 账户**。
2. 点击右上角的用户图标，进入 **My Profile**（我的资料）。
3. 切换到 **API Tokens**（API 令牌）标签页。
4. 点击 **Create Token**,在*API token templates*里面选择*Edit zone DNS*,点击*Use Template*
5. 记录生成的token ,例如本次生成的是 `te6sst-JthcoR0E3H0yEOWdxJfLZjVAbJUcYQVPj`

### 步骤三：创建 INI 凭证文件

在你的服务器上创建一个新的ini文件，将token内容粘贴到文件中，

```
mkdir /etc/ssl/cloudflare
cat << 'EOF' >> /etc/ssl/cloudflare/example.dpdns.org.ini
dns_cloudflare_api_token = te6sst-JthcoR0E3H0yEOWdxJfLZjVAbJUcYQVPj
EOF
```

设置文件权限：只有文件所有者有读写权限

```
chmod 600 /etc/ssl/cloudflare/example.dpdns.org.ini
```

```shell
# 1. 安装插件
sudo apt install python3-certbot-dns-cloudflare 

# 2. 运行命令
sudo certbot certonly \
  --dns-cloudflare \
  --dns-cloudflare-credentials /etc/ssl/cloudflare/example.dpdns.org.ini \
  -d example.dpdns.org -d '*.example.dpdns.org'
```

得到如下输出：

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Requesting a certificate for example.dpdns.org and *.example.dpdns.org
Waiting 10 seconds for DNS changes to propagate

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/example.dpdns.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/example.dpdns.org/privkey.pem
This certificate expires on 2026-03-07.
These files will be updated when the certificate renews.
Certbot has set up a scheduled task to automatically renew this certificate in the background.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

## 删除证书

如果想了解使用certbot已经生成了多少证书，需要查询可以使用命令

```
sudo certbot certificates
```

得到如下结果

```
Saving debug log to /var/log/letsencrypt/letsencrypt.log

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Found the following certs:
  Certificate Name: example.dpdns.org
    Serial Number: 50e24455e74231bc758d6a007f47b394812
    Key Type: ECDSA
    Domains: example.dpdns.org *.example.dpdns.org
    Expiry Date: 2026-03-07 23:34:29+00:00 (VALID: 89 days)
    Certificate Path: /etc/letsencrypt/live/example.dpdns.org/fullchain.pem
    Private Key Path: /etc/letsencrypt/live/example.dpdns.org/privkey.pem
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
```

然后可以卸载多余的证书

```
sudo certbot delete --cert-name example.dpdns.org
```








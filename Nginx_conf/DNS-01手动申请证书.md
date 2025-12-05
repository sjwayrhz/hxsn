# DNS-01手动申请证书

这样启动了一个nginx项目

```
docker run --rm -d \
  --name nginx-mini \
  -p 80:80 \
  -v /etc/nginx/conf.d:/etc/nginx/conf.d \
  -v /usr/share/nginx/html:/usr/share/nginx/html \
  nginx:1.29.3-alpine
```

由于这个物理机没有公网IP，于是考虑手动DNS-01的方式生成证书，采用acme.sh的方法

```
# 安装 acme.sh
curl https://get.acme.sh | sh
# 注册
acme.sh --register-account -m sjwayrhz@gmail.com
# 加载环境变量
export PATH="$HOME/.acme.sh:$PATH"
```

安装完成后，可以使用 acme.sh 命令。

```
 acme.sh --issue --dns -d test.taoistmonk.dpdns.org --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

得到的输出如下：

```
[Thu Nov 27 17:07:37 CST 2025] Using CA: https://acme.zerossl.com/v2/DV90
[Thu Nov 27 17:07:37 CST 2025] Creating domain key
[Thu Nov 27 17:07:38 CST 2025] The domain key is here: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/test.taoistmonk.dpdns.org.key
[Thu Nov 27 17:07:38 CST 2025] Single domain='test.taoistmonk.dpdns.org'
[Thu Nov 27 17:07:41 CST 2025] Getting webroot for domain='test.taoistmonk.dpdns.org'
[Thu Nov 27 17:07:41 CST 2025] Add the following TXT record:
[Thu Nov 27 17:07:41 CST 2025] Domain: '_acme-challenge.test.taoistmonk.dpdns.org'
[Thu Nov 27 17:07:41 CST 2025] TXT value: 'zEmrhG_VAKx5ElUwep6NA6-_hAP7xO4MWtzRJN4hm4g'
[Thu Nov 27 17:07:41 CST 2025] Please make sure to prepend '_acme-challenge.' to your domain
[Thu Nov 27 17:07:41 CST 2025] so that the resulting subdomain is: _acme-challenge.test.taoistmonk.dpdns.org
[Thu Nov 27 17:07:41 CST 2025] Please add the TXT records to the domains, and re-run with --renew.
[Thu Nov 27 17:07:41 CST 2025] Please add '--debug' or '--log' to see more information.
[Thu Nov 27 17:07:41 CST 2025] See: https://github.com/acmesh-official/acme.sh/wiki/How-to-debug-acme.sh
```

再次运行命令，后面添加--renew

```
acme.sh --issue --dns -d test.taoistmonk.dpdns.org --yes-I-know-dns-manual-mode-enough-go-ahead-please --renew
```

得到的成功输出如下：

```
[Thu Nov 27 17:13:56 CST 2025] The domain 'test.taoistmonk.dpdns.org' seems to already have an ECC cert, let's use it.
[Thu Nov 27 17:13:56 CST 2025] Renewing: 'test.taoistmonk.dpdns.org'
[Thu Nov 27 17:13:56 CST 2025] Renewing using Le_API=https://acme.zerossl.com/v2/DV90
[Thu Nov 27 17:13:57 CST 2025] Using CA: https://acme.zerossl.com/v2/DV90
[Thu Nov 27 17:13:57 CST 2025] Single domain='test.taoistmonk.dpdns.org'
[Thu Nov 27 17:13:57 CST 2025] Verifying: test.taoistmonk.dpdns.org
[Thu Nov 27 17:14:00 CST 2025] Processing. The CA is processing your order, please wait. (1/30)
[Thu Nov 27 17:14:04 CST 2025] Success
[Thu Nov 27 17:14:04 CST 2025] Verification finished, beginning signing.
[Thu Nov 27 17:14:04 CST 2025] Let's finalize the order.
[Thu Nov 27 17:14:04 CST 2025] Le_OrderFinalize='https://acme.zerossl.com/v2/DV90/order/jf5R4apRGBXx1lQii4HqFw/finalize'
[Thu Nov 27 17:14:06 CST 2025] Order status is 'processing', let's sleep and retry.
[Thu Nov 27 17:14:06 CST 2025] Sleeping for 15 seconds then retrying
[Thu Nov 27 17:14:22 CST 2025] Polling order status: https://acme.zerossl.com/v2/DV90/order/jf5R4apRGBXx1lQii4HqFw
[Thu Nov 27 17:14:23 CST 2025] Downloading cert.
[Thu Nov 27 17:14:23 CST 2025] Le_LinkCert='https://acme.zerossl.com/v2/DV90/cert/5uIrqR_kaXG8UvjoEB1DSQ'
[Thu Nov 27 17:14:25 CST 2025] Cert success.
-----BEGIN CERTIFICATE-----
MIIECjCCA5GgAwIBAgIRALZQTZK4KfeY4U5S7aMoERcwCgYIKoZIzj0EAwMwSzEL
MAkGA1UEBhMCQVQxEDAOBgNVBAoTB1plcm9TU0wxKjAoBgNVBAMTIVplcm9TU0wg
RUNDIERvbWFpbiBTZWN1cmUgU2l0ZSBDQTAeFw0yNTExMjcwMDAwMDBaFw0yNjAy
MjUyMzU5NTlaMCQxIjAgBgNVBAMTGXRlc3QudGFvaXN0bW9uay5kcGRucy5vcmcw
WTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARU9nu9/pnJTbqxMpIZSGMRbFXqW2Sk
2jMuXwA54iEQ+Lu+0FVPXziBD/Lu5rPxOGzgqha2yK39I8RSRmj97I2Uo4ICezCC
AncwHwYDVR0jBBgwFoAUD2vmS845R672fpAeefAwkZLIX6MwHQYDVR0OBBYEFBFT
DK5W153HWFRoODkiHim+ilAmMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAA
MBMGA1UdJQQMMAoGCCsGAQUFBwMBMEkGA1UdIARCMEAwNAYLKwYBBAGyMQECAk4w
JTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNvbS9DUFMwCAYGZ4EMAQIB
MIGIBggrBgEFBQcBAQR8MHowSwYIKwYBBQUHMAKGP2h0dHA6Ly96ZXJvc3NsLmNy
dC5zZWN0aWdvLmNvbS9aZXJvU1NMRUNDRG9tYWluU2VjdXJlU2l0ZUNBLmNydDAr
BggrBgEFBQcwAYYfaHR0cDovL3plcm9zc2wub2NzcC5zZWN0aWdvLmNvbTCCAQQG
CisGAQQB1nkCBAIEgfUEgfIA8AB3AA5XlLzzrqk+MxssmQez95Dfm8I9cTIl3SGp
JaxhxU4hAAABmsSXacIAAAQDAEgwRgIhALzLySdNt7yVmsjdSpaO0O+4oEOytOCL
5JOCoVC3GQOiAiEAxkJomD2f9oBJe7AITj1C+Q3zL+VeB8OcFyW5Om2nBBoAdQDR
bqmlaAd+ZjWgPzel3bwDpTxBEhTUiBj16TGzI8uVBAAAAZrEl2qHAAAEAwBGMEQC
ICLbADuRJevx79g18vNelR5cJ5PikMmVWnQ1E4qSW+sLAiBrO5Q5viqBYUvK7eX6
nJE9T50OwGFR6HM3b2peEW0vSzAkBgNVHREEHTAbghl0ZXN0LnRhb2lzdG1vbmsu
ZHBkbnMub3JnMAoGCCqGSM49BAMDA2cAMGQCMG/JTi1Nddh2Pw4fZZfWX8oYngVW
LxAp/ctnDRMgPKFIVlNz07UKLRRdhP67wRLfVgIwHIx93lQPMVEPYE0pKeX1g7Ul
vIoGAvNY/82lkjiWB1f90kIsAQ4Qa8QDjFyAHnoP
-----END CERTIFICATE-----
[Thu Nov 27 17:14:25 CST 2025] Your cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/test.taoistmonk.dpdns.org.cer
[Thu Nov 27 17:14:25 CST 2025] Your cert key is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/test.taoistmonk.dpdns.org.key
[Thu Nov 27 17:14:25 CST 2025] The intermediate CA cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/ca.cer
[Thu Nov 27 17:14:25 CST 2025] And the full-chain cert is in: /root/.acme.sh/test.taoistmonk.dpdns.org_ecc/fullchain.cer
```

90天后手动续期

```
acme.sh --renew -d test.taoistmonk.dpdns.org --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

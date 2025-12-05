# acme.sh申请泛域名

举个例子，本次希望申请*.hsitj.dpdns.org的泛域名
先下载acme.sh

```
curl https://get.acme.sh | sh && source ~/.bashrc
```

注册操作者邮箱

```
acme.sh --register-account -m sjwayrhz@gmail.com
```

申请命令

```
acme.sh --issue --dns -d hsitj.dpdns.org -d *.hsitj.dpdns.org --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

acme.sh 会生成两条 TXT 记录（分别对应根域名和泛域名的验证），需全部添加到 DNS 解析中，否则验证失败,输入如下内容

```
[Fri Nov 28 08:10:16 UTC 2025] Using CA: https://acme.zerossl.com/v2/DV90
[Fri Nov 28 08:10:16 UTC 2025] Creating domain key
[Fri Nov 28 08:10:16 UTC 2025] The domain key is here: /root/.acme.sh/hsitj.dpdns.org_ecc/hsitj.dpdns.org.key
[Fri Nov 28 08:10:16 UTC 2025] Multi domain='DNS:hsitj.dpdns.org,DNS:*.hsitj.dpdns.org'
[Fri Nov 28 08:10:22 UTC 2025] Getting webroot for domain='hsitj.dpdns.org'
[Fri Nov 28 08:10:22 UTC 2025] Getting webroot for domain='*.hsitj.dpdns.org'
[Fri Nov 28 08:10:23 UTC 2025] Add the following TXT record:
[Fri Nov 28 08:10:23 UTC 2025] Domain: '_acme-challenge.hsitj.dpdns.org'
[Fri Nov 28 08:10:23 UTC 2025] TXT value: 'h_92fiTIHZ4re7PXYPPqYVysOUEPjqW6Zh1Bhlz6-m0'
[Fri Nov 28 08:10:23 UTC 2025] Please make sure to prepend '_acme-challenge.' to your domain
[Fri Nov 28 08:10:23 UTC 2025] so that the resulting subdomain is: _acme-challenge.hsitj.dpdns.org
[Fri Nov 28 08:10:23 UTC 2025] Add the following TXT record:
[Fri Nov 28 08:10:23 UTC 2025] Domain: '_acme-challenge.hsitj.dpdns.org'
[Fri Nov 28 08:10:23 UTC 2025] TXT value: 'Sg5C4_kk9cZROIUJ6gVNlnWN-UbUzPUZLvb7M5q1ds4'
[Fri Nov 28 08:10:23 UTC 2025] Please make sure to prepend '_acme-challenge.' to your domain
[Fri Nov 28 08:10:23 UTC 2025] so that the resulting subdomain is: _acme-challenge.hsitj.dpdns.org
[Fri Nov 28 08:10:23 UTC 2025] Please add the TXT records to the domains, and re-run with --renew.
[Fri Nov 28 08:10:23 UTC 2025] Please add '--debug' or '--log' to see more information.
[Fri Nov 28 08:10:23 UTC 2025] See: https://github.com/acmesh-official/acme.sh/wiki/How-to-debug-acme.sh
```

也就是生成两个DNS记录

```
{
    _acme-challenge: h_92fiTIHZ4re7PXYPPqYVysOUEPjqW6Zh1Bhlz6-m0
    _acme-challenge: Sg5C4_kk9cZROIUJ6gVNlnWN-UbUzPUZLvb7M5q1ds4
}
```

在linux中使用dig探寻记录是否有效

```
dig TXT _acme-challenge.hsitj.dpdns.org
```

得到如下输出代表有效

```
; <<>> DiG 9.18.39-0ubuntu0.24.04.2-Ubuntu <<>> TXT _acme-challenge.hsitj.dpdns.org
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 56928
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 65494
;; QUESTION SECTION:
;_acme-challenge.hsitj.dpdns.org. IN    TXT

;; ANSWER SECTION:
_acme-challenge.hsitj.dpdns.org. 300 IN TXT     "Sg5C4_kk9cZROIUJ6gVNlnWN-UbUzPUZLvb7M5q1ds4"
_acme-challenge.hsitj.dpdns.org. 300 IN TXT     "h_92fiTIHZ4re7PXYPPqYVysOUEPjqW6Zh1Bhlz6-m0"

;; Query time: 935 msec
;; SERVER: 127.0.0.53#53(127.0.0.53) (UDP)
;; WHEN: Fri Nov 28 08:13:32 UTC 2025
;; MSG SIZE  rcvd: 172
```

但是，这里要注意的是，虽然dig成功，但是还是不会立马申请证书就有效，dig成功后还得等5分钟左右，再次申请证书即可。

```
acme.sh --issue --dns -d hsitj.dpdns.org -d *.hsitj.dpdns.org --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

得到如下的结果：

```
[Fri Nov 28 08:15:42 UTC 2025] Using CA: https://acme.zerossl.com/v2/DV90
[Fri Nov 28 08:15:43 UTC 2025] Multi domain='DNS:hsitj.dpdns.org,DNS:*.hsitj.dpdns.org'
[Fri Nov 28 08:15:49 UTC 2025] Getting webroot for domain='hsitj.dpdns.org'
[Fri Nov 28 08:15:49 UTC 2025] Getting webroot for domain='*.hsitj.dpdns.org'
[Fri Nov 28 08:15:49 UTC 2025] hsitj.dpdns.org is already verified, skipping dns-01.
[Fri Nov 28 08:15:50 UTC 2025] *.hsitj.dpdns.org is already verified, skipping dns-01.
[Fri Nov 28 08:15:50 UTC 2025] Verification finished, beginning signing.
[Fri Nov 28 08:15:50 UTC 2025] Let's finalize the order.
[Fri Nov 28 08:15:50 UTC 2025] Le_OrderFinalize='https://acme.zerossl.com/v2/DV90/order/46RhozCGz8MH3Yj5aZ1Z5w/finalize'
[Fri Nov 28 08:15:51 UTC 2025] Order status is 'processing', let's sleep and retry.
[Fri Nov 28 08:15:51 UTC 2025] Sleeping for 15 seconds then retrying
[Fri Nov 28 08:16:07 UTC 2025] Polling order status: https://acme.zerossl.com/v2/DV90/order/46RhozCGz8MH3Yj5aZ1Z5w
[Fri Nov 28 08:16:08 UTC 2025] Downloading cert.
[Fri Nov 28 08:16:08 UTC 2025] Le_LinkCert='https://acme.zerossl.com/v2/DV90/cert/L9zvFfAal4Z-6lzn1nh9HQ'
[Fri Nov 28 08:16:10 UTC 2025] Cert success.
-----BEGIN CERTIFICATE-----
MIIEBzCCA46gAwIBAgIQb1Zkz8ZK17hhOEivQtqDkjAKBggqhkjOPQQDAzBLMQsw
CQYDVQQGEwJBVDEQMA4GA1UEChMHWmVyb1NTTDEqMCgGA1UEAxMhWmVyb1NTTCBF
Q0MgRG9tYWluIFNlY3VyZSBTaXRlIENBMB4XDTI1MTEyODAwMDAwMFoXDTI2MDIy
NjIzNTk1OVowGjEYMBYGA1UEAxMPaHNpdGouZHBkbnMub3JnMFkwEwYHKoZIzj0C
AQYIKoZIzj0DAQcDQgAE39zy4nrZTlptF2Fd1jPFRngXSVc9osX9bsd7VMlEoSph
XSmkBCZJWbvtRExuCUdOYaOdclM7JizOx+epodE6Q6OCAoMwggJ/MB8GA1UdIwQY
MBaAFA9r5kvOOUeu9n6QHnnwMJGSyF+jMB0GA1UdDgQWBBRHC3on1rdlmUwK68tE
iaF4ZpvnLDAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAK
BggrBgEFBQcDATBJBgNVHSAEQjBAMDQGCysGAQQBsjEBAgJOMCUwIwYIKwYBBQUH
AgEWF2h0dHBzOi8vc2VjdGlnby5jb20vQ1BTMAgGBmeBDAECATCBiAYIKwYBBQUH
AQEEfDB6MEsGCCsGAQUFBzAChj9odHRwOi8vemVyb3NzbC5jcnQuc2VjdGlnby5j
b20vWmVyb1NTTEVDQ0RvbWFpblNlY3VyZVNpdGVDQS5jcnQwKwYIKwYBBQUHMAGG
H2h0dHA6Ly96ZXJvc3NsLm9jc3Auc2VjdGlnby5jb20wggEDBgorBgEEAdZ5AgQC
BIH0BIHxAO8AdQAOV5S8866pPjMbLJkHs/eQ35vCPXEyJd0hqSWsYcVOIQAAAZrJ
iJ0nAAAEAwBGMEQCIExZ+nCKIT5lFkNRxqky6gplKuwnif3hEfFtEei/VcM1AiBe
7JhjWD+0wmUe22/ZOoh2kDZgEgRAdHhSqIhTMMFWRQB2ANFuqaVoB35mNaA/N6Xd
vAOlPEESFNSIGPXpMbMjy5UEAAABmsmIndsAAAQDAEcwRQIhAJbQQtfSBsP//l/h
+mTwlKbK7XGKwKdd8lZ81A9ASXB8AiBK3esQvN0PCgFmXjOqpzfQNAuf1FIkXASC
1tBdVLc2hDAtBgNVHREEJjAkgg9oc2l0ai5kcGRucy5vcmeCESouaHNpdGouZHBk
bnMub3JnMAoGCCqGSM49BAMDA2cAMGQCMHRN6eAH4UcyRZdg5y0KgQ13zOe+Cnqo
K2qHH1dFOZ3Um5bYuT8B0sWlkuK49+zsFgIwIkzWV/1LZT9iykiRxxHBnWla45kM
oDSbccoVN05FpNykEBE0DgmHRA5uNVnP8fdI
-----END CERTIFICATE-----
[Fri Nov 28 08:16:10 UTC 2025] Your cert is in: /root/.acme.sh/hsitj.dpdns.org_ecc/hsitj.dpdns.org.cer
[Fri Nov 28 08:16:10 UTC 2025] Your cert key is in: /root/.acme.sh/hsitj.dpdns.org_ecc/hsitj.dpdns.org.key
[Fri Nov 28 08:16:10 UTC 2025] The intermediate CA cert is in: /root/.acme.sh/hsitj.dpdns.org_ecc/ca.cer
[Fri Nov 28 08:16:10 UTC 2025] And the full-chain cert is in: /root/.acme.sh/hsitj.dpdns.org_ecc/fullchain.cer
```

生成的文件配置到nginx里面有用的是：

```
# 证书文件
ssl_certificate /root/.acme.sh/hsitj.dpdns.org_ecc/fullchain.cer;
# 私钥文件
ssl_certificate_key /root/.acme.sh/hsitj.dpdns.org_ecc/hsitj.dpdns.org.key;
```

然后可以看到定时任务里面已经有了自动更新

```
crontab -l
27 18 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```

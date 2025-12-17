## 生成ssh_key工具

可以借助网站[8gwifi.org](https://8gwifi.org/sshfunctions.jsp)生成ssh_key  

## 私钥末尾要换行

这个非常重要  
假设有一组ED25519的密钥

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
QyNTUxOQAAACBwykb3b02RvfawzL9VWdQL3FgfA9wShjIN+pbw+2D2owAAAIhteCMzbXgj
MwAAAAtzc2gtZWQyNTUxOQAAACBwykb3b02RvfawzL9VWdQL3FgfA9wShjIN+pbw+2D2ow
AAAECp/RfPO9az/mYAhtPVx0FfgW8TOaRSa9FSeZpEemvIC3DKRvdvTZG99rDMv1VZ1Avc
WB8D3BKGMg36lvD7YPajAAAAAAECAwQF
-----END OPENSSH PRIVATE KEY-----

```

注意看，上述私钥是必须要以换行符结尾，否则私钥不能生效。
公钥

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHDKRvdvTZG99rDMv1VZ1AvcWB8D3BKGMg36lvD7YPaj
```

公钥不需要换行，而且公钥后面空格之后可以写备注

# 静态IP地址配置

## 方法一，修改interfaces
```
vi /etc/network/interfaces
```
例如改为如下
```
# 设置网卡开机自启
auto ens33
# 将 inet 后面改为 static
iface ens33 inet static
    address 192.168.6.12
    netmask 255.255.255.0
    gateway 192.168.6.1
    dns-nameservers 8.8.8.8 1.1.1.1
```
立即生效
```
sudo ifdown ens33 && sudo ifup ens33
```

## 方法二，使用systemd-networkd

首先，停止systemd-networkd，检查状态
```
systemctl status systemd-networkd
```
停止
```
systemctl disable --now networking
```

创建静态 IP 配置文件
在 /etc/systemd/network/ 下创建一个以 .network 结尾的文件（例如 10-static.network）：
```
vim /etc/systemd/network/10-static.network
```
内容为
```
[Match]
Name=ens33 

[Network]
Address=192.168.6.12/24
Gateway=192.168.6.1
DNS=8.8.8.8
DNS=1.1.1.1
```

启用并启动服务
```
systemctl enable --now systemd-networkd
```
还需要修改文件
```
 vi /etc/network/interfaces
```
注释这两行
```
allow hotplug ens33
iface ens33 inet dhcp
```

# 静态IP地址配置

## 方法一，修改interfaces
```
vi /etc/network/interfaces
```
例如改为如下
```
auto ens33
iface ens33 inet static
    address 192.168.6.12
    netmask 255.255.255.0
    gateway 192.168.6.2
    dns-nameservers 8.8.8.8 1.1.1.1
```
一般vmware虚拟机里面的网关可能是192.168.6.2，然后esxi系统可能就是192.168.6.1，注意输入正确的网关地址。
立即生效
```
sudo ifdown ens33 && sudo ifup ens33
```

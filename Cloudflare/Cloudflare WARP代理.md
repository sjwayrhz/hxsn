在甲骨文（Oracle Cloud）上使用 Cloudflare WARP 主要是为了改变服务器的**出口 IP**。因为 WARP 的 IP 属于 Cloudflare，谷歌对其限制非常宽松，可以完美解决甲骨文原生 IP 被拒（403/429）的问题。

以下是针对 Linux 服务器最稳妥的操作步骤：

---

### 第一步：安装 Cloudflare WARP 官方客户端

我们推荐使用官方的 `warp-cli`，因为它最稳定。

1. **添加仓库并安装**（以 Ubuntu/Debian 为例）：
```bash
# 添加 GPG key
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg

# 添加源
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list

# 更新并安装
sudo apt update && sudo apt install cloudflare-warp

```


2. **注册设备**：
```bash
warp-cli registration new

```



---

### 第二步：配置代理模式（关键：防止断开连接）

**注意：** 如果你直接打开 WARP（虚拟网卡模式），甲骨文的路由表会被更改，导致你无法通过 SSH 连接服务器。
**为了安全，建议使用 Proxy 模式**，这会启动一个本地 SOCKS5 代理。

1. **切换到代理模式**：
```bash
warp-cli mode proxy
```


2. **开启连接**：
```bash
warp-cli connect
```


3. **测试代理是否生效**：
```bash
curl -x socks5://127.0.0.1:40000 https://www.cloudflare.com/cdn-cgi/trace
```


*如果在输出中看到 `warp=on`，说明代理已在本地 40000 端口成功运行。*

---

### 第三步：配置 Rclone 使用 WARP 代理

现在你只需要让 rclone 通过这个本地代理去访问谷歌即可。

直接修改配置文件（通常在~/.config/rclone/rclone.conf）：
```bash
vim ~/.config/rclone/rclone.conf
```
在你的 [gdrive] 配置块下面添加3行：
在执行命令前加入代理参数：

```bash
retries = 10
retries_sleep = 10s
proxy_url = socks5://127.0.0.1:40000
```

---

### 进阶：使用脚本一键安装 (更简单)

如果你觉得官方命令太繁琐，社区有很多优秀的开源脚本（如 `warp-go`），可以自动处理分流和安装：

```bash
# 使用 P3TERX 的单栈/双栈脚本 (非常流行)
wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh
```

在菜单中选择 **“安装 WARP 代理模式”**，它会自动帮你把端口配置好。

---

### 为什么这个方案有效？

通过这种方式，你的上传流量路径变成了：
**甲骨文服务器 -> Cloudflare 网络 (WARP IP) -> 谷歌网盘**。
谷歌看到的访问来源是 Cloudflare，从而避开了对甲骨文 IP 段的针对性封控。

---

### 避坑小贴士

* **端口冲突**：WARP 默认代理端口是 `40000`。如果被占用，可以用 `warp-cli proxy port 端口号` 修改。
* **始终连接**：如果你希望服务器重启后 WARP 自动连接，可以运行 `warp-cli enable-always-on`。

**你要尝试安装官方客户端，还是需要我提供那个一键脚本的详细选项说明？**
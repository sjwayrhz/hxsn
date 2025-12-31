### 1.安装

安装地址参考[ntfy](https://docs.ntfy.sh/install/#debianubuntu-repository)
这里介绍ubuntu系统

```bash
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/ntfy.gpg https://archive.ntfy.sh/apt/keyring.gpg
sudo apt install apt-transport-https
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/ntfy.gpg] https://archive.ntfy.sh/apt stable main" \
    | sudo tee /etc/apt/sources.list.d/ntfy.list
sudo apt update
sudo apt install ntfy
```

但是安装之后无法直接启动，因为 /etc/ntfy/server.yml 里面的内容全是注释的，实际上没有有效的配置。

```bash
cat << 'EOF' >> /etc/ntfy/server.yml
base-url: "https://ntfy.hsafj.dpdns.org"
listen-http: "127.0.0.1:2586"
cache-file: "/var/cache/ntfy/cache.db"
cache-duration: "12h"
attachment-cache-dir: "/var/cache/ntfy/attachments"
attachment-total-size-limit: "5G"
attachment-file-size-limit: "15M"
attachment-expiry-duration: "3h"
auth-file: "/var/lib/ntfy/user.db"
auth-default-access: "deny-all"
log-level: "info"
EOF
```
可以使用nginx代理127.0.0.1:2586或者使用cloudflare tunnel映射到公网

### 2. 使用命令行添加用户

修改并保存配置文件后，你需要运行 `ntfy` 的管理命令来创建用户。

* **创建管理员用户（拥有所有权限）：**
```bash
ntfy user add --role admin your_username
```


* **创建普通用户：**
```bash
ntfy user add your_username
```

*(执行后会提示你输入并确认密码)*

### 3. 如何管理 Topic 的权限？

在 `ntfy` 中，你不需要手动“创建” Topic，Topic 是在使用时自动生成的。你只需要通过命令**分配权限**即可：

* **允许用户 `tom` 对名为 `mytopic` 的 Topic 有读写权限：**
```bash
ntfy access tom mytopic rw
```


* **允许匿名用户（所有人）只读某个 Topic：**
```bash
ntfy access everyone public_news read
```


### 4. 可以尝试启动
检查配置是否正确

```
ntfy serve --config /etc/ntfy/server.yml
```
正式启动命令
```
nohup ntfy serve -c /etc/ntfy/server.yml > /var/log/ntfy.log 2>&1 &
```

启动cloudflare tunnel

```
nohup cloudflared tunnel run --token eyJhIjoiYjE5OTY2YmVjODMzMTEyZGZjY2JjNjAyYzkyM2NmY2YiLCJ0IjoiNDQ5OTY0YzAtYjhkZC00NDJlLTgzNmYtYTBjYmM4OWY0YWNjIiwicyI6IlpqaG1NREE1WVdJdE0yUXdaaTAwT0RreUxUaG1ZamN0WVdKbU5tSmlNbUkxT0dOaCJ9 > /var/log/cloudflared.log 2>&1 &
```


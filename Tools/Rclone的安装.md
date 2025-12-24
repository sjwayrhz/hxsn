## 安装rclone

使用 Rclone 连接 Google Drive（谷歌网盘）主要分为**安装**、**基础配置**和**身份授权**三个步骤。

根据你操作系统的不同，步骤略有差异，但核心流程如下：

------

## 第一步：安装 Rclone

如果你还没安装，请根据系统执行命令：

- **Windows**: 下载 [rclone.exe](https://rclone.org/downloads/) 并将其路径添加到系统环境变量。
- **Linux/macOS**: 终端输入 `sudo -v ; curl https://rclone.org/install.sh | sudo bash`。

------

## 第二步：进入配置向导

在终端（或 CMD/PowerShell）输入：

Bash

```
rclone config
```

按照以下提示操作：

1. **n) New remote**: 输入 `n` 新建链接。
2. **name**: 给你的网盘起个名字（例如 `gdrive`）。
3. **Storage**: 输入 `drive` 或找到对应 **Google Drive** 的数字编号。
4. **client_id & client_secret**:
   - **建议：** 直接回车留空（使用 Rclone 默认 ID）。
   - **进阶：** 如果你追求更稳定的速度，可以去 [Google API Console](https://console.developers.google.com/) 申请自己的 API 密钥。
5. **scope**: 选择 `1` (Full access)，即赋予 Rclone 读写权限。
6. **service_account_file**: 直接回车留空。
7. **Edit advanced config?**: 输入 `n` (No)。
8. **Use auto config?**:
   - 如果你在**本地电脑**（有浏览器），输入 `y`。它会自动弹出浏览器让你登录 Google 账号。
   - 如果你在**远程服务器**（无浏览器，如 VPS），输入 `n`。你需要按照屏幕提示，在本地电脑运行 `rclone authorize "drive"` 获取验证码再贴回服务器。

------

## 第三步：完成验证

1. 在弹出的浏览器窗口中，选择你的 Google 账号，点击“允许”。
2. 回到终端，你会看到 `Configure this as a Shared Drive (Team Drive)?`。如果你用的是个人盘，选 `n`；如果是团队盘，选 `y` 并选择对应的盘。
3. 最后输入 `y` (Yes this is OK) 保存，按 `q` 退出配置。

------

## 第四步：常用操作测试

配置完成后，你可以尝试以下命令：

| **目标**           | **命令示例**                                                 |
| ------------------ | ------------------------------------------------------------ |
| **列出根目录文件** | `rclone ls gdrive:/`                                         |
| **上传文件**       | `rclone copy /本地路径 gdrive:/远程路径`                     |
| **同步文件夹**     | `rclone sync /本地目录 gdrive:/远程目录 --progress`          |
| **挂载为本地磁盘** | `rclone mount gdrive:/ /本地挂载点` (需要安装 fuse 或 winfsp) |

------

### 💡 核心提示

- **防火墙问题**：在境内使用时，Rclone 需要通过代理才能连接谷歌服务器。你可以通过设置环境变量来解决：
  - Windows: `$env:https_proxy="http://127.0.0.1:端口"`
  - Linux: `export https_proxy="http://127.0.0.1:端口"`
- **数据安全**：如果网盘里有敏感数据，建议在配置完 `gdrive` 后，再叠加一层 `crypt`（加密）配置。
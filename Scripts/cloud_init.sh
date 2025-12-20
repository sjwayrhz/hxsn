#!/bin/bash

# ==========================================
# Oracle Cloud Ubuntu 24.04 初始化脚本 (Docker CE 版)
# ==========================================

# check root
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以 root 身份运行" 1>&2
   exit 1
fi

# 定义公钥变量
MY_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiPkGdbLCgNbJnnQ3mLRo1pSVqoCjbO0/3MIGNHKPSJ"

# 1. 设置 iptables 策略，打通所有端口
# ------------------------------------------
echo ">>> [1/5] 配置防火墙..."
# 禁用 UFW
ufw disable

# 清空 iptables 规则
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X

# 设置默认策略为 ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 持久化规则 (如果有安装 netfilter-persistent)
netfilter-persistent save 2>/dev/null || echo "iptables-persistent not installed, skipping save."

# 2. 安装 Vim 并安装官方 Docker CE
# ------------------------------------------
echo ">>> [2/5] 更新系统并安装 Docker CE..."
export DEBIAN_FRONTEND=noninteractive

# 更新源并安装必要的依赖工具
apt-get update -y
apt-get install -y ca-certificates curl gnupg vim

# --- 开始 Docker CE 安装流程 ---
# 1. 创建 keyrings 目录
install -m 0755 -d /etc/apt/keyrings

# 2. 下载 Docker 官方 GPG 密钥 (如果有旧的先覆盖)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# 3. 设置 Docker 仓库 (自动识别 Ubuntu 代号，如 noble)
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# 4. 更新源并安装 Docker CE 及相关插件
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# -----------------------------

# 配置 Root 用户的 .vimrc
cat > /root/.vimrc <<EOF
set number
set cursorline
set syntax=on
set ruler
set mouse=a
set tabstop=4
set shiftwidth=4
set expandtab
EOF

# 3. 启动 Docker 保活镜像
# ------------------------------------------
echo ">>> [3/5] 启动 Docker 保活容器..."
systemctl enable --now docker

echo "启动 Oracle Keepalive 容器..."
# 检查 Docker 是否正常运行
if systemctl is-active --quiet docker; then
    docker pull sjwayrhz/oracle-alive:latest
    docker run -d --name oracle-keepalive --restart always sjwayrhz/oracle-alive:latest
else
    echo "警告: Docker 未能正常启动，跳过保活容器部署。"
fi

# 4. 配置 SSH 公钥 (Root 和 Ubuntu 用户)
# ------------------------------------------
echo ">>> [4/5] 配置 SSH 公钥..."

# --- 配置 Root 用户 ---
ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTH_FILE="$ROOT_SSH_DIR/authorized_keys"

mkdir -p "$ROOT_SSH_DIR"
chmod 700 "$ROOT_SSH_DIR"

# 解锁文件（如果之前被锁过）
[ -f "$ROOT_AUTH_FILE" ] && chattr -i "$ROOT_AUTH_FILE"

# 写入公钥到 Root (覆盖或置顶)
if [ -f "$ROOT_AUTH_FILE" ]; then
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE.tmp"
    cat "$ROOT_AUTH_FILE" >> "$ROOT_AUTH_FILE.tmp"
    mv "$ROOT_AUTH_FILE.tmp" "$ROOT_AUTH_FILE"
else
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE"
fi

chmod 600 "$ROOT_AUTH_FILE"
# 锁定 Root 的 authorized_keys 文件
chattr +i "$ROOT_AUTH_FILE"


# --- 配置 Ubuntu 用户 ---
UBUNTU_USER="ubuntu"
UBUNTU_HOME="/home/$UBUNTU_USER"
UBUNTU_SSH_DIR="$UBUNTU_HOME/.ssh"
UBUNTU_AUTH_FILE="$UBUNTU_SSH_DIR/authorized_keys"

if id "$UBUNTU_USER" &>/dev/null; then
    mkdir -p "$UBUNTU_SSH_DIR"
    
    if ! grep -q "$MY_SSH_KEY" "$UBUNTU_AUTH_FILE" 2>/dev/null; then
        echo "$MY_SSH_KEY" >> "$UBUNTU_AUTH_FILE"
    fi

    chown -R $UBUNTU_USER:$UBUNTU_USER "$UBUNTU_SSH_DIR"
    chmod 700 "$UBUNTU_SSH_DIR"
    chmod 600 "$UBUNTU_AUTH_FILE"
else
    echo "警告: 用户 $UBUNTU_USER 不存在，跳过该用户配置。"
fi


# 5. 修改 sshd_config 允许 Root 登录
# ------------------------------------------
echo ">>> [5/5] 配置 SSHD..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# 删除 #PermitRootLogin prohibit-password 前的注释并确保配置正确
if grep -q "^PermitRootLogin" "$SSHD_CONFIG"; then
    sed -i 's/^PermitRootLogin.*/PermitRootLogin prohibit-password/' "$SSHD_CONFIG"
else
    echo "PermitRootLogin prohibit-password" >> "$SSHD_CONFIG"
fi

# 确保 PubkeyAuthentication 开启
sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' "$SSHD_CONFIG"

# 重启 SSH 服务
systemctl restart ssh

echo "初始化脚本执行完毕！Docker CE 已安装。"
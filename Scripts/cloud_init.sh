#!/bin/bash

# ==========================================
# Oracle Cloud Ubuntu 24.04 初始化脚本
# ==========================================

# 定义公钥变量（方便复用）
MY_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiPkGdbLCgNbJnnQ3mLRo1pSVqoCjbO0/3MIGNHKPSJ"

# 1. 设置 iptables 策略，打通所有端口
# ------------------------------------------
echo "配置防火墙..."
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

# 2. APT Update, 安装 Vim 并配置 Root 个性化
# ------------------------------------------
echo "更新软件源并安装基础软件..."
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y vim docker.io

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
echo "配置 Docker..."
systemctl enable --now docker

echo "启动 Oracle Keepalive 容器..."
docker pull sjwayrhz/oracle-alive:latest
docker run -d --name oracle-keepalive --restart always sjwayrhz/oracle-alive:latest

# 4. 配置 SSH 公钥 (Root 和 Ubuntu 用户)
# ------------------------------------------
echo "配置 SSH 公钥..."

# --- 配置 Root 用户 ---
ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTH_FILE="$ROOT_SSH_DIR/authorized_keys"

mkdir -p "$ROOT_SSH_DIR"
chmod 700 "$ROOT_SSH_DIR"

# 解锁文件（如果之前被锁过）
[ -f "$ROOT_AUTH_FILE" ] && chattr -i "$ROOT_AUTH_FILE"

# 写入公钥到 Root (覆盖或置顶)
if [ -f "$ROOT_AUTH_FILE" ]; then
    # 将新Key和旧内容合并，新Key放第一行
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE.tmp"
    cat "$ROOT_AUTH_FILE" >> "$ROOT_AUTH_FILE.tmp"
    mv "$ROOT_AUTH_FILE.tmp" "$ROOT_AUTH_FILE"
else
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE"
fi

chmod 600 "$ROOT_AUTH_FILE"
# 锁定 Root 的 authorized_keys 文件，防止删除/修改
chattr +i "$ROOT_AUTH_FILE"


# --- 配置 Ubuntu 用户 (新增部分) ---
UBUNTU_USER="ubuntu"
UBUNTU_HOME="/home/$UBUNTU_USER"
UBUNTU_SSH_DIR="$UBUNTU_HOME/.ssh"
UBUNTU_AUTH_FILE="$UBUNTU_SSH_DIR/authorized_keys"

# 确保目录存在
mkdir -p "$UBUNTU_SSH_DIR"

# 追加公钥到 Ubuntu 用户 (如果文件中不存在该 key 才添加，避免重复)
if ! grep -q "$MY_SSH_KEY" "$UBUNTU_AUTH_FILE" 2>/dev/null; then
    echo "$MY_SSH_KEY" >> "$UBUNTU_AUTH_FILE"
fi

# 修正权限 (非常重要：必须归属于 ubuntu 用户)
chown -R $UBUNTU_USER:$UBUNTU_USER "$UBUNTU_SSH_DIR"
chmod 700 "$UBUNTU_SSH_DIR"
chmod 600 "$UBUNTU_AUTH_FILE"


# 5. 修改 sshd_config 允许 Root 登录
# ------------------------------------------
echo "配置 SSHD..."
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

echo "初始化脚本执行完毕！"#!/bin/bash

# ==========================================
# Oracle Cloud Ubuntu 24.04 初始化脚本
# ==========================================

# 定义公钥变量（方便复用）
MY_SSH_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFiPkGdbLCgNbJnnQ3mLRo1pSVqoCjbO0/3MIGNHKPSJ"

# 1. 设置 iptables 策略，打通所有端口
# ------------------------------------------
echo "配置防火墙..."
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

# 2. APT Update, 安装 Vim 并配置 Root 个性化
# ------------------------------------------
echo "更新软件源并安装基础软件..."
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y vim docker.io

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
echo "配置 Docker..."
systemctl enable --now docker

echo "启动 Oracle Keepalive 容器..."
docker pull sjwayrhz/oracle-alive:latest
docker run -d --name oracle-keepalive --restart always sjwayrhz/oracle-alive:latest

# 4. 配置 SSH 公钥 (Root 和 Ubuntu 用户)
# ------------------------------------------
echo "配置 SSH 公钥..."

# --- 配置 Root 用户 ---
ROOT_SSH_DIR="/root/.ssh"
ROOT_AUTH_FILE="$ROOT_SSH_DIR/authorized_keys"

mkdir -p "$ROOT_SSH_DIR"
chmod 700 "$ROOT_SSH_DIR"

# 解锁文件（如果之前被锁过）
[ -f "$ROOT_AUTH_FILE" ] && chattr -i "$ROOT_AUTH_FILE"

# 写入公钥到 Root (覆盖或置顶)
if [ -f "$ROOT_AUTH_FILE" ]; then
    # 将新Key和旧内容合并，新Key放第一行
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE.tmp"
    cat "$ROOT_AUTH_FILE" >> "$ROOT_AUTH_FILE.tmp"
    mv "$ROOT_AUTH_FILE.tmp" "$ROOT_AUTH_FILE"
else
    echo "$MY_SSH_KEY" > "$ROOT_AUTH_FILE"
fi

chmod 600 "$ROOT_AUTH_FILE"
# 锁定 Root 的 authorized_keys 文件，防止删除/修改
chattr +i "$ROOT_AUTH_FILE"


# --- 配置 Ubuntu 用户 (新增部分) ---
UBUNTU_USER="ubuntu"
UBUNTU_HOME="/home/$UBUNTU_USER"
UBUNTU_SSH_DIR="$UBUNTU_HOME/.ssh"
UBUNTU_AUTH_FILE="$UBUNTU_SSH_DIR/authorized_keys"

# 确保目录存在
mkdir -p "$UBUNTU_SSH_DIR"

# 追加公钥到 Ubuntu 用户 (如果文件中不存在该 key 才添加，避免重复)
if ! grep -q "$MY_SSH_KEY" "$UBUNTU_AUTH_FILE" 2>/dev/null; then
    echo "$MY_SSH_KEY" >> "$UBUNTU_AUTH_FILE"
fi

# 修正权限 (非常重要：必须归属于 ubuntu 用户)
chown -R $UBUNTU_USER:$UBUNTU_USER "$UBUNTU_SSH_DIR"
chmod 700 "$UBUNTU_SSH_DIR"
chmod 600 "$UBUNTU_AUTH_FILE"


# 5. 修改 sshd_config 允许 Root 登录
# ------------------------------------------
echo "配置 SSHD..."
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

echo "初始化脚本执行完毕！"
# 去除防火墙代码

```
cat << 'EOF' >> remove_iptables.sh
#!/bin/bash
set -e  # 遇到错误立即退出

# 检查是否为 root 用户
if [ "$(id -u)" -ne 0 ]; then
    echo "❌ 请以 root 用户执行（使用 sudo -i 或 su -）"
    exit 1
fi

# 步骤 1：备份现有规则（可选，建议保留）
BACKUP_FILE="/etc/iptables.backup.$(date +%Y%m%d%H%M%S)"
echo "📦 正在备份现有 iptables 规则到 $BACKUP_FILE"
iptables-save > "$BACKUP_FILE"
echo "✅ 备份完成"

# 步骤 2：清空所有规则和自定义链
echo "🧹 正在清空现有 iptables 规则..."
iptables -F  # 清空 filter 表规则
iptables -X  # 删除 filter 表自定义链
iptables -t nat -F  # 清空 nat 表规则
iptables -t nat -X  # 删除 nat 表自定义链
echo "✅ 规则清空完成"

# 步骤 3：设置默认策略为 ACCEPT
echo "🔧 正在设置默认策略为 ACCEPT..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
echo "✅ 默认策略设置完成"

# 步骤 4：保留已建立连接的优化规则（非必需，但推荐）
echo "📌 正在添加已建立连接优化规则..."
iptables -A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
echo "✅ 优化规则添加完成"

# 步骤 5：卸载 netfilter-persistent（避免重启恢复旧规则）
echo "🔍 检查并卸载 netfilter-persistent..."
if dpkg -l | grep -q "netfilter-persistent"; then
    echo "🗑️ 正在卸载 netfilter-persistent..."
    apt purge -y netfilter-persistent
    rm -rf /etc/iptables  # 删除残留规则文件
    echo "✅ 卸载完成"
else
    echo "ℹ️ netfilter-persistent 未安装，跳过卸载"
fi

# 步骤 6：验证配置
echo "✅ 所有端口已开放，当前 iptables 规则如下："
iptables -L -n

# 安全提示
echo -e "\n⚠️  警告：开放所有端口存在安全风险！建议："
echo "1. 禁用 SSH 密码登录，仅允许密钥登录（编辑 /etc/ssh/sshd_config，设置 PasswordAuthentication no）"
echo "2. 定期更新系统：apt update && apt upgrade -y"
echo "3. 生产环境仅开放必需端口（如 80、443、22）"
EOF
```

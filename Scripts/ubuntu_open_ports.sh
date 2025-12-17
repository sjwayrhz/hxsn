#!/bin/bash

# 检查是否以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo "请使用 sudo 运行此脚本: sudo bash $0"
  exit
fi

echo "======================================================="
echo "正在开始配置 iptables 为全开模式..."
echo "======================================================="

# 1. 先将默认策略设置为 ACCEPT (允许所有)
# 这是防止在清除规则时 SSH 连接中断的关键步骤
echo "[+] 设置默认策略为 ACCEPT..."
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# 2. 刷新 (清空) 所有链的规则
echo "[+] 清空所有规则..."
iptables -F
iptables -t nat -F
iptables -t mangle -F

# 3. 删除所有自定义链 (包括 Oracle 的 InstanceServices)
echo "[+] 删除自定义链..."
iptables -X
iptables -t nat -X
iptables -t mangle -X

echo "[+] 当前 iptables 状态 (应为空且策略为 ACCEPT):"
iptables -L -n

# 4. 持久化保存规则 (确保重启后不恢复原样)
echo "======================================================="
echo "正在保存规则以确保重启后生效..."

# 检查是否安装了 iptables-persistent (Ubuntu 常用)
if dpkg -s iptables-persistent &> /dev/null; then
    netfilter-persistent save
    echo "[OK] 规则已通过 netfilter-persistent 保存。"
else
    echo "[-] 未检测到 iptables-persistent，正在安装..."
    # 避免安装过程中的交互弹窗
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y iptables-persistent netfilter-persistent
    netfilter-persistent save
    echo "[OK] 安装完成并已保存规则。"
fi

# 5. 解决甲骨文云可能的后台强制刷新问题
# 甲骨文有些镜像会有定时任务恢复防火墙，彻底清理一下
if [ -f /etc/iptables/rules.v4 ]; then
    iptables-save > /etc/iptables/rules.v4
fi

echo "======================================================="
echo "配置完成！操作系统防火墙已全开。"
echo "请务必检查甲骨文云网页后台的【安全列表】是否放行了流量。"
echo "======================================================="
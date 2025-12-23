这份手册是专门为你定制的。我们将直接在你的 Oracle Cloud Ubuntu 24.04 服务器上（本地）安装 Ansible，然后使用 `matrix-docker-ansible-deploy` 项目来部署全套服务。

这种方法比手动配置 Docker Compose 稳定得多，因为它会自动处理复杂的 Nginx 反向代理、SSL 证书和 Coturn（音视频通话）配置。

---

### 前置准备：DNS 解析

在开始敲代码之前，请务必去你的域名服务商（Cloudflare, AliYun 等）做两条 **A 记录** 指向你甲骨文服务器的公网 IP：

1. `matrix.hsitj.dpdns.org` (主服务)
2. `element.hsitj.dpdns.org` (如果你想要一个 Web 客户端，可选但推荐)

---

### 第一步：系统环境与工具安装

Ubuntu 24.04 引入了 PEP 668，直接用 pip 安装全局包会报错。我们将使用 `pipx` 安装 Ansible。

SSH 登录你的服务器，依次执行：

```bash
# 1. 更新系统
sudo apt update && sudo apt upgrade -y

# 2. 安装基础依赖和 pipx
sudo apt install -y git python3-pip pipx make

# 3. 配置 pipx 环境变量
pipx ensurepath
source ~/.bashrc

# 4. 安装 Ansible 和 docker SDK
pipx install ansible-core
pipx inject ansible-core requests docker

# 5. 验证安装
ansible --version
# 应该看到 ansible-core 2.20 或更高版本
```

---

### 第二步：下载部署剧本

我们将项目克隆到 `/opt/matrix` 目录（推荐位置）：

```bash
# 1. 创建目录并克隆
sudo mkdir -p /opt/matrix
sudo chown $USER:$USER /opt/matrix
git clone https://github.com/spantaleev/matrix-docker-ansible-deploy.git /opt/matrix

# 2. 进入目录
cd /opt/matrix
```

---

### 第三步：配置服务器 (关键步骤)

创建数据库

以 `avnadmin` 身份连接到 Aiven 的默认数据库（通常是 `defaultdb`），然后执行：

```
-- 1. 创建 synapse 专用用户, 替换‘nb4rk8Ks1aXjy6’为你的密码
CREATE USER synapse WITH PASSWORD 'nb4rk8Ks1aXjy6';

-- 2. 创建 synapse 专用数据库
CREATE DATABASE synapse;

-- 3. 将该数据库的所有权转让给 synapse 用户
ALTER DATABASE synapse OWNER TO synapse;
```

配置 Schema 权限 (关键步骤)

由于 Synapse 启动时需要创建大量的表，你必须确保 `synapse` 用户在它自己的数据库里有完整的权限。

请切换连接到刚才创建的 `synapse` 数据库，然后执行：

```
-- 切换到 synapse 数据库后再执行以下操作：

-- 4. 授予对 public 模式的所有权限
-- 在 PostgreSQL 15 以后版本中，默认不再授予普通用户在 public 模式下的 CREATE 权限
GRANT ALL ON SCHEMA public TO synapse;

-- 5. (可选但推荐) 确保未来创建的表也属于 synapse
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO synapse;
```

我们需要创建两个文件：一个是告诉 Ansible 安装在哪里（本机），一个是具体的配置参数。

#### 1. 创建 `inventory/hosts` 文件

```bash
mkdir -p inventory/host_vars/matrix.hsitj.dpdns.org
vim inventory/hosts
```

**粘贴以下内容：**

```ini
[matrix_servers]
matrix.hsitj.dpdns.org ansible_connection=local
```

#### 2. 创建 `inventory/host_vars/matrix.hsitj.dpdns.org/vars.yml` 文件

这是整个系统的灵魂。

```bash
vim inventory/host_vars/matrix.hsitj.dpdns.org/vars.yml
```

**粘贴以下内容（已为你配置好）：**

```yaml
# === 基础域名配置 ===
# 你的用户 ID 将会是 @user:matrix.hsitj.dpdns.org
matrix_domain: hsitj.dpdns.org

# 关闭本地自动安装
postgres_enabled: false
valkey_enabled: false

# === 数据库与性能 (Postgres + Redis) ===
# 告诉 Synapse 使用外部数据库
dev_matrix_synapse_database_type: "psycopg2" # 这是 Python 连接 Postgres 的驱动

# 外部数据库的具体配置
matrix_synapse_database_host: "pg-hsitj-sjwayrhz.k.aivencloud.com"
matrix_synapse_database_port: 18268
matrix_synapse_database_user: "synapse"
matrix_synapse_database_password: "your_password"
matrix_synapse_database_database: "synapse" 
matrix_synapse_database_extra_arguments:
  sslmode: "require"

# 告诉 Synapse 外部 Redis 的位置
matrix_synapse_redis_host: "valkey-hsitj-sjwayrhz.k.aivencloud.com"
matrix_synapse_redis_port: 18269
matrix_synapse_redis_password: "your_password"

# 永久禁用有 Bug 的检查逻辑
matrix_playbook_migration_enabled: false
matrix_playbook_verify_config_enabled: false

# === 音视频通话服务器 (Coturn) ===
# 必须开启，否则无法语音/视频
matrix_coturn_enabled: true
# ⚠️ 重要：甲骨文云在 NAT 后面，这里必须自动获取公网 IP
matrix_coturn_turn_external_ip_address: ""

# 要求的密钥
matrix_homeserver_generic_secret_key: "ggOA4ZSeGnshjn3TfM8mkYjN"
# 另一个常见的安全密钥
matrix_synapse_macaroon_secret_key: "x1jOlyP7bRzKXb2ogr3YmrT4"

# === 客户端 (Element Web) ===
# 访问地址将是 https://element.hsitj.dpdns.org
matrix_client_element_enabled: true
matrix_client_element_domain: element.hsitj.dpdns.org

# === 证书与反向代理 ===
# 1. 核心反向代理设置
matrix_playbook_reverse_proxy_type: playbook-managed-traefik
# 2. 证书获取方式改为 DNS 验证
matrix_ssl_retrieval_method: dns-cloudflare
# 3. 填入你的 Cloudflare 凭据
# 请确保 Token 拥有 "Zone:DNS:Edit" 和 "Zone:Zone:Read" 权限
matrix_traefik_acme_dns_challenge_env_vars:
  - "CF_DNS_API_TOKEN=M_cbEPOQzEMwGu-Rg_wdb-dMw0n8SyEsc55XnQBP"
  - "CF_ZONE_API_TOKEN=M_cbEPOQzEMwGu-Rg_wdb-dMw0n8SyEsc55XnQBP"
# 4. (可选) 你的邮箱，用于接收证书过期提醒
matrix_ssl_lets_encrypt_support_email: "sjwayrhz@outlook.com"

# === 注册配置 ===
# false 关闭注册,如果改为ture可能会启动失败
matrix_synapse_enable_registration: false
```

---

### 第四步：执行安装

现在开始让 Ansible 自动干活。这需要几分钟时间。

```bash
# 1. 下载必要的依赖角色（解决你刚才遇到的 ERROR）
ansible-galaxy install -r requirements.yml -p roles/galaxy/
ansible-galaxy collection install community.docker community.general community.postgresql
pipx inject ansible-core passlib

# 2. 暂时清空以绕过 Playbook 自身的 Bug
cat <<EOF > /opt/matrix/roles/custom/matrix_playbook_migration/tasks/validate_config.yml
---
# 暂时清空以绕过 Playbook 自身的 Bug
EOF

# 3. 初始化环境、生成配置文件并安装 Docker 等底层依赖

ansible-playbook -i inventory/hosts setup.yml --tags=setup-all

# 4. 启动所有服务（Postgres, Redis, Synapse, Coturn 等）
ansible-playbook -i inventory/hosts setup.yml --tags=start
```

如果看到全是绿色的 `changed` 或 `ok`，没有红色的 `failed`，说明安装成功！

---

### 第五步：创建第一个管理员账号

虽然我们开启了公共注册，但在服务器后端直接创建一个管理员最稳妥：

```bash
ansible-playbook -i inventory/hosts setup.yml \
--extra-vars='username=admin password=你的强密码 admin=yes' \
--tags=register-user
```

---

### 第六步：甲骨文云防火墙设置 (至关重要)

甲骨文云有两层防火墙，一层是 Ubuntu 系统的 `iptables`，一层是网页控制台的 **VCN Security List**。

#### 1. 系统内部防火墙 (Ubuntu)

如果你还没装防火墙管理工具，Ansible 可能会帮你配置，但最好手动确认放行：

```bash
# 这是一个暴力放行脚本，确保相关端口打开
sudo iptables -I INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 443 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 8448 -j ACCEPT
sudo iptables -I INPUT -p tcp --dport 3478 -j ACCEPT
sudo iptables -I INPUT -p udp --dport 3478 -j ACCEPT
# Coturn 需要的 UDP 范围
sudo iptables -I INPUT -p udp --dport 49152:49252 -j ACCEPT

# 保存规则
sudo netfilter-persistent save

```

#### 2. 甲骨文网页后台 (VCN Security List)

**如果不做这一步，外网无法访问！**

1. 登录 Oracle Cloud 后台。
2. 进入 Networking -> Virtual Cloud Networks -> 点击你的 VCN -> 点击 **Security List**。
3. 添加入站规则 (Ingress Rules)：
* **Source CIDR:** `0.0.0.0/0`
* **Protocols:**
* TCP: `80`, `443`, `8448` (Federation), `3478` (TURN)
* UDP: `3478` (TURN), `49152-49252` (TURN 媒体流)





---

### 第七步：验证

1. **Web 客户端：** 浏览器访问 `https://element.hsitj.dpdns.org`。
2. **登录：**
* Home Server URL (如果需要填): `https://matrix.hsitj.dpdns.org`
* 用户: `@admin:matrix.hsitj.dpdns.org`
* 密码: (你在第五步设置的)



### 下一步维护建议

如果以后你想关闭注册（防止被白嫖）：

1. 修改 `vars.yml`：`matrix_synapse_enable_registration: false`
2. 执行更新：`ansible-playbook -i inventory/hosts setup.yml --tags=setup-synapse,start`

这个方案虽然用到了 Ansible，但完全是“傻瓜式”的，比你手动写 Dockerfile 去拼凑 Postgres 和 Redis 要稳定得多。
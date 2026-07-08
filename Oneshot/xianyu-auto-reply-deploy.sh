#!/bin/bash
# ==========================================
# 闲鱼自动回复系统 - 一键部署脚本 (重构优化版)
# 用法： bash xianyu-auto-reply-deploy.sh
# ==========================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

WORK_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$WORK_DIR/xianyu_auto_reply"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.yml"
ENV_FILE="$PROJECT_DIR/.env"

echo "=========================================="
echo "  闲鱼自动回复系统 - 一键部署"
echo "=========================================="
echo ""

# ========== 1. 严格的环境检查 ==========
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker 未安装，请先执行官方安装脚本。${NC}"
    echo "curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
    exit 1
fi

# 检查 Docker 进程是否真正在运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker 服务未启动或当前用户无权限。${NC}"
    echo "请尝试运行: sudo systemctl start docker"
    echo "或将当前用户加入 docker 组: sudo usermod -aG docker \$USER"
    exit 1
fi

if docker compose version &> /dev/null; then
    DC="docker compose"
elif command -v docker-compose &> /dev/null; then
    DC="docker-compose"
else
    echo -e "${RED}错误: Docker Compose 未安装。${NC}"
    exit 1
fi

# 移除原脚本中硬编码的全局 export，改用标准环境变量传递
DC_CMD="$DC -f $COMPOSE_FILE --env-file $ENV_FILE"

echo -e "${CYAN}[信息] Docker: $(docker --version | awk '{print $3}' | tr -d ',')${NC}"
echo -e "${CYAN}[信息] Compose: $($DC version | awk '{print $4}')${NC}"
echo -e "${CYAN}[信息] 项目目录: $PROJECT_DIR${NC}"
echo ""

# ========== 2. 创建项目目录结构 ==========
mkdir -p "$PROJECT_DIR"
mkdir -p \
    "$PROJECT_DIR/mysql/data" \
    "$PROJECT_DIR/redis/data" \
    "$PROJECT_DIR/logs/backend_web" \
    "$PROJECT_DIR/logs/websocket" \
    "$PROJECT_DIR/logs/scheduler" \
    "$PROJECT_DIR/static" \
    "$PROJECT_DIR/backups" \
    "$PROJECT_DIR/browser_data"

# ========== 3. 生成 .env 配置文件 ==========
if [ ! -f "$ENV_FILE" ]; then
    echo -e "${YELLOW}[提示] 首次部署，生成默认配置文件...${NC}"
    cat > "$ENV_FILE" << 'ENVEOF'
# ==========================================
# 闲鱼自动回复系统 - 环境变量配置
# ==========================================

# 核心修正：将项目名称固化在配置中，与目录名保持一致
COMPOSE_PROJECT_NAME=xianyu_auto_reply

# MySQL数据库配置
MYSQL_ROOT_PASSWORD=xianyu@2026
MYSQL_DATABASE=xianyu_data
MYSQL_USER=xianyu
MYSQL_PASSWORD=xianyu@2026

# Redis缓存配置
REDIS_PASSWORD=xianyu@2026
REDIS_DB=0

# 端口配置
FRONTEND_PORT=9000
BACKEND_WEB_PORT=8089
WEBSOCKET_PORT=8090
SCHEDULER_PORT=8091

# 镜像配置
IMAGE_REGISTRY=registry.cn-shanghai.aliyuncs.com/zhinian-software
IMAGE_TAG=latest
MYSQL_IMAGE=registry.cn-shanghai.aliyuncs.com/zhinian-software/xianyu-mysql:8.0
REDIS_IMAGE=registry.cn-shanghai.aliyuncs.com/zhinian-software/xianyu-redis:7-alpine

# 应用配置
LOG_LEVEL=INFO
SQL_ECHO=true
ACCESS_TOKEN_EXPIRE_MINUTES=1440
REFRESH_TOKEN_EXPIRE_MINUTES=10080
REDELIVERY_INTERVAL=5
RATE_INTERVAL=20
MAX_CAPTCHA_CONCURRENT=3
ENVEOF
    echo -e "${GREEN}✓ 已生成 $ENV_FILE${NC}"
    echo ""
fi

# ========== 4. 生成 docker-compose.yml ==========
echo "[信息] 生成 docker-compose.yml..."
cat > "$COMPOSE_FILE" << 'COMPOSEEOF'
services:
  mysql:
    image: ${MYSQL_IMAGE:-registry.cn-shanghai.aliyuncs.com/zhinian-software/xianyu-mysql:8.0}
    container_name: xianyu-mysql
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - TZ=Asia/Shanghai
    command:
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_unicode_ci
      - --max-connections=500
      - --default-time-zone=+08:00
    volumes:
      - ./mysql/data:/var/lib/mysql
    networks:
      - xianyu-network
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-u", "root", "-p${MYSQL_ROOT_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 10
      start_period: 30s

  redis:
    image: ${REDIS_IMAGE:-registry.cn-shanghai.aliyuncs.com/zhinian-software/xianyu-redis:7-alpine}
    container_name: xianyu-redis
    restart: unless-stopped
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --maxmemory 256mb
      --maxmemory-policy allkeys-lru
      --appendonly yes
    environment:
      - TZ=Asia/Shanghai
    volumes:
      - ./redis/data:/data
    networks:
      - xianyu-network
    healthcheck:
      test: ["CMD", "redis-cli", "-a", "${REDIS_PASSWORD}", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 10s

  backend-web:
    image: ${IMAGE_REGISTRY:-registry.cn-shanghai.aliyuncs.com/zhinian-software}/xianyu-backend-web:${IMAGE_TAG:-latest}
    container_name: xianyu-backend-web
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_DB=${REDIS_DB}
      - BACKEND_WEB_PORT=8089
      - HOST=0.0.0.0
      - JWT_ALGORITHM=HS256
      - ACCESS_TOKEN_EXPIRE_MINUTES=${ACCESS_TOKEN_EXPIRE_MINUTES}
      - REFRESH_TOKEN_EXPIRE_MINUTES=${REFRESH_TOKEN_EXPIRE_MINUTES}
      - CORS_ORIGINS=*
      - WEBSOCKET_SERVICE_URL=http://websocket:8090
      - SCHEDULER_SERVICE_URL=http://scheduler:8091
      - STATIC_DIR=/app/static
      - BACKUP_DIR=/app/backups
      - BROWSER_HEADLESS=true
      - LOG_LEVEL=${LOG_LEVEL}
      - SQL_ECHO=${SQL_ECHO}
      - TZ=Asia/Shanghai
    volumes:
      - ./logs/backend_web:/app/backend-web/logs
      - ./static:/app/static
      - ./backups:/app/backups
    ports:
      - "${BACKEND_WEB_PORT:-8089}:8089"
    networks:
      - xianyu-network
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  websocket:
    image: ${IMAGE_REGISTRY:-registry.cn-shanghai.aliyuncs.com/zhinian-software}/xianyu-websocket:${IMAGE_TAG:-latest}
    container_name: xianyu-websocket
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_DB=${REDIS_DB}
      - WEBSOCKET_PORT=8090
      - HOST=0.0.0.0
      - MAX_CAPTCHA_CONCURRENT=${MAX_CAPTCHA_CONCURRENT}
      - BROWSER_HEADLESS=true
      - BACKEND_WEB_SERVICE_URL=http://backend-web:8089
      - STATIC_DIR=/app/static
      - LOG_LEVEL=${LOG_LEVEL}
      - SQL_ECHO=${SQL_ECHO}
      - TZ=Asia/Shanghai
    volumes:
      - ./logs/websocket:/app/websocket/logs
      - ./static:/app/static
      - ./browser_data:/app/browser_data
    ports:
      - "${WEBSOCKET_PORT:-8090}:8090"
    networks:
      - xianyu-network
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  scheduler:
    image: ${IMAGE_REGISTRY:-registry.cn-shanghai.aliyuncs.com/zhinian-software}/xianyu-scheduler:${IMAGE_TAG:-latest}
    container_name: xianyu-scheduler
    restart: unless-stopped
    environment:
      - ENVIRONMENT=production
      - MYSQL_HOST=mysql
      - MYSQL_PORT=3306
      - MYSQL_USER=${MYSQL_USER}
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=${MYSQL_DATABASE}
      - REDIS_HOST=redis
      - REDIS_PORT=6379
      - REDIS_PASSWORD=${REDIS_PASSWORD}
      - REDIS_DB=${REDIS_DB}
      - SCHEDULER_PORT=8091
      - HOST=0.0.0.0
      - REDELIVERY_INTERVAL=${REDELIVERY_INTERVAL}
      - RATE_INTERVAL=${RATE_INTERVAL}
      - WEBSOCKET_SERVICE_URL=http://websocket:8090
      - BACKEND_WEB_SERVICE_URL=http://backend-web:8089
      - STATIC_DIR=/app/static
      - BACKUP_DIR=/app/backups
      - LOG_LEVEL=${LOG_LEVEL}
      - SQL_ECHO=${SQL_ECHO}
      - TZ=Asia/Shanghai
    volumes:
      - ./logs/scheduler:/app/scheduler/logs
      - ./static:/app/static:ro
      - ./backups:/app/backups
    ports:
      - "${SCHEDULER_PORT:-8091}:8091"
    networks:
      - xianyu-network
    depends_on:
      mysql:
        condition: service_healthy
      redis:
        condition: service_healthy

  frontend:
    image: ${IMAGE_REGISTRY:-registry.cn-shanghai.aliyuncs.com/zhinian-software}/xianyu-frontend:${IMAGE_TAG:-latest}
    container_name: xianyu-frontend
    restart: unless-stopped
    environment:
      - TZ=Asia/Shanghai
    ports:
      - "${FRONTEND_PORT:-9000}:80"
    networks:
      - xianyu-network

networks:
  xianyu-network:
    driver: bridge
COMPOSEEOF
echo -e "${GREEN}✓ 配置文件已生成${NC}"
echo ""

# ========== 5. 部署执行 ==========
echo -e "${YELLOW}步骤 1/3: 清理潜在旧环境...${NC}"
$DC_CMD down 2>/dev/null || true
echo -e "${GREEN}✓ 环境清理就绪${NC}"

echo ""
echo -e "${YELLOW}步骤 2/3: 拉取最新镜像...${NC}"
$DC_CMD pull
echo -e "${GREEN}✓ 镜像拉取完成${NC}"

echo ""
echo -e "${YELLOW}步骤 3/3: 启动服务...${NC}"
$DC_CMD up -d
echo -e "${GREEN}✓ 服务已触发启动指令${NC}"

echo ""
echo "[信息] 检查服务运行状态..."
sleep 5
$DC_CMD ps

# 读取端口用于回显
frontend_port=$(grep -E "^FRONTEND_PORT=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | tr -d '\r' || echo "9000")
backend_web_port=$(grep -E "^BACKEND_WEB_PORT=" "$ENV_FILE" 2>/dev/null | cut -d '=' -f2 | tr -d '\r' || echo "8089")

echo ""
echo -e "${GREEN}=========================================="
echo "  部署流水线执行完毕！"
echo "==========================================${NC}"
echo ""
echo "面板访问地址："
echo "  前端界面: http://服务器IP:${frontend_port}"
echo "  后端接口: http://服务器IP:${backend_web_port}"
echo ""
echo -e "${CYAN}💡 运维提示：${NC}"
echo "  1. 以后管理项目，直接进入目录： cd xianyu_auto_reply"
echo "  2. 停止并移除容器： docker compose down"
echo "  3. 重启整个项目： docker compose restart"
echo "  4. 实时查看日志： docker compose logs -f"
echo ""

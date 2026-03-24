#!/bin/bash
set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== BX Framework 初始化脚本 ===${NC}"

# 检查是否需要初始化（通过检查 install.lock）
if [ -f "/var/www/html/install/install.lock" ]; then
    echo -e "${GREEN}✓ 已检测到 install.lock，跳过初始化${NC}"
else
    echo -e "${YELLOW}→ 首次启动，开始初始化...${NC}"

    # 从环境变量读取配置
    DB_HOST=${DB_HOST:-mysql}
    DB_PORT=${DB_PORT:-3306}
    DB_USER=${DB_USER:-root}
    DB_PASSWORD=${DB_PASSWORD:-}
    DB_NAME=${DB_NAME:-bx}
    DB_PREFIX=${DB_PREFIX:-bx_}

    echo -e "${YELLOW}→ 数据库配置:${NC}"
    echo "  Host: $DB_HOST"
    echo "  Port: $DB_PORT"
    echo "  User: $DB_USER"
    echo "  Database: $DB_NAME"
    echo "  Prefix: $DB_PREFIX"

    # 等待数据库就绪
    echo -e "${YELLOW}→ 等待数据库连接...${NC}"
    max_retries=30
    retries=0
    while ! mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASSWORD" -e "SELECT 1" >/dev/null 2>&1; do
        retries=$((retries + 1))
        if [ $retries -ge $max_retries ]; then
            echo -e "${RED}✗ 数据库连接超时，请检查配置${NC}"
            exit 1
        fi
        echo "  等待数据库... ($retries/$max_retries)"
        sleep 5
    done
    echo -e "${GREEN}✓ 数据库连接成功${NC}"

    # 检查数据库是否存在，不存在则创建
    echo -e "${YELLOW}→ 检查数据库...${NC}"
    mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\` CHARACTER SET utf8 COLLATE utf8_general_ci;" 2>/dev/null || true
    echo -e "${GREEN}✓ 数据库准备就绪${NC}"

    # 检查表是否已存在
    TABLE_COUNT=$(mysql --skip-ssl -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASSWORD" -N -e "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = '$DB_NAME' AND table_name = '${DB_PREFIX}menber'" 2>/dev/null || echo "0")

    if [ "$TABLE_COUNT" -gt 0 ]; then
        echo -e "${GREEN}✓ 数据库表已存在，跳过 SQL 导入${NC}"
    else
        # 执行 SQL 文件
        echo -e "${YELLOW}→ 导入数据库结构...${NC}"
        if [ -f "/var/www/html/docker-compose/docker-install.sql" ]; then
            mysql --skip-ssl --default-character-set=utf8 -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USER" --password="$DB_PASSWORD" "$DB_NAME" < /var/www/html/docker-compose/docker-install.sql 2>&1
            echo -e "${GREEN}✓ SQL 导入完成${NC}"
        else
            echo -e "${RED}✗ 未找到 docker-compose/docker-install.sql${NC}"
            exit 1
        fi
    fi

    # 创建锁文件
    echo -e "${YELLOW}→ 创建安装锁文件...${NC}"
    echo "lock" > /var/www/html/install/install.lock
    echo "lock" > /var/www/html/install/update.lock
    echo -e "${GREEN}✓ 锁文件创建成功${NC}"

    echo -e "${GREEN}=== 初始化完成 ===${NC}"
    echo -e "${GREEN}默认账号: admin${NC}"
    echo -e "${GREEN}默认密码: admin${NC}"
fi

# 设置权限
echo -e "${YELLOW}→ 设置目录权限...${NC}"
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
chmod -R 777 /var/www/html/config 2>/dev/null || true
chmod -R 777 /var/www/html/install 2>/dev/null || true
chmod -R 777 /var/www/html/public 2>/dev/null || true
echo -e "${GREEN}✓ 权限设置完成${NC}"

# 启动 Apache
echo -e "${YELLOW}→ 启动 Apache...${NC}"
exec apache2-foreground

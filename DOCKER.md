# Docker 部署指南

## 项目概述
本项目使用 Docker 容器化部署，使用 PHP 8.2 + Apache 环境。

## 文件说明

| 文件 | 说明 |
|------|------|
| `Dockerfile` | PHP + Apache 镜像构建配置 |
| `docker-compose.yml` | Docker Compose 配置 |
| `.dockerignore` | 排除不需要打包的文件 |
| `.env` | 环境变量配置文件（数据库等） |

## 环境变量配置

项目支持通过 `.env` 文件配置数据库和应用参数：

```bash
# 数据库配置
DB_HOST=localhost          # 数据库主机地址
DB_PORT=3306               # 数据库端口
DB_USER=your_username      # 数据库用户名
DB_PASSWORD=your_password  # 数据库密码
DB_NAME=your_database      # 数据库名称
DB_PREFIX=bx_              # 表名前缀

# 应用配置
APP_DEBUG=false            # 调试模式（true/false）
APP_KEY=unlock             # 程序密钥
APP_TIMEZONE=PRC           # 时区设置
```

## 快速开始

### 1. 配置环境变量

复制示例配置并修改：

```bash
# 编辑 .env 文件，填入你的数据库配置
vim .env
```

### 2. 启动容器

```bash
# 启动容器
docker-compose up -d

# 查看运行状态
docker-compose ps

# 查看日志
docker-compose logs -f
```

### 3. 运行安装向导

在浏览器中访问：
```
http://localhost:8080/install
```

按照安装向导完成数据库初始化。

### 4. 访问应用

- **前台页面**: http://localhost:8080
- **后台管理**: http://localhost:8080/admin
- **代理后台**: http://localhost:8080/agent
- **安装向导**: http://localhost:8080/install

默认管理员账号：`admin` / `admin`

## 常用命令

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 进入 PHP 容器
docker exec -it bx_wlyz bash

# 查看容器日志
docker logs bx_wlyz
```

## 配置原理

`config/config.php` 使用 `getenv()` 函数读取环境变量：

```php
'db' => [
    'host' => getenv('DB_HOST') ?: 'localhost',
    'port' => getenv('DB_PORT') ?: '3306',
    'user' => getenv('DB_USER') ?: '',
    'pw'   => getenv('DB_PASSWORD') ?: '',
    'name' => getenv('DB_NAME') ?: '',
    'tablepre' => getenv('DB_PREFIX') ?: 'bx_',
],
```

如果环境变量未设置，则使用默认值。这使得配置既可以通过 `.env` 文件管理，也可以直接在宿主机上运行。

## 生产环境部署

### 构建镜像并推送到仓库

```bash
# 构建镜像
docker build -t your-registry/bx-framework:latest .

# 推送镜像（可选）
docker push your-registry/bx-framework:latest
```

### 使用独立容器运行

```bash
# 运行应用，通过 -e 参数传入环境变量
docker run -d \
  --name bx_wlyz \
  -p 8080:80 \
  -e DB_HOST=your_db_host \
  -e DB_PORT=3306 \
  -e DB_USER=your_user \
  -e DB_PASSWORD=your_password \
  -e DB_NAME=your_database \
  -v $(pwd):/var/www/html \
  your-registry/bx-framework:latest
```

## 目录权限说明

容器内使用 `www-data` 用户运行 Apache，以下目录需要写入权限：
- `config/` - 配置文件目录
- `install/` - 安装向导目录
- `template/` - 模板缓存目录（如果有）

## 故障排查

### 1. 数据库连接失败
```bash
# 检查环境变量是否正确加载
docker exec bx_wlyz env | grep DB_

# 确认 config.php 能正确读取环境变量
docker exec bx_wlyz php -r "var_dump(getenv('DB_HOST'));"
```

### 2. 403/500 错误
```bash
# 检查目录权限
docker exec bx_wlyz ls -la /var/www/html

# 重置权限
docker exec bx_wlyz chown -R www-data:www-data /var/www/html
```

### 3. mod_rewrite 未生效
```bash
# 检查模块是否启用
docker exec bx_wlyz apache2ctl -M | grep rewrite

# 重启 Apache
docker-compose restart
```

## 安全建议

1. **生产环境**请修改默认数据库密码和 APP_KEY
2. `.env` 文件包含敏感信息，**不要提交到版本控制**
3. 生产环境建议使用 Docker Secrets 或环境变量注入
4. 移除或保护 `install/` 目录（安装完成后）

## 自定义配置

### 修改 PHP 配置
创建 `php.ini` 并挂载到容器：
```yaml
volumes:
  - ./php.ini:/usr/local/etc/php/php.ini
```

### 修改 Apache 配置
编辑 `Dockerfile` 中的虚拟主机配置部分。

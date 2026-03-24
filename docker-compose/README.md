# Docker Compose 配置说明

## 概述

本配置用于部署 BX_wlyz PHP Web 应用程序。

## 服务详情

### bx_wlyz

| 属性 | 值 |
|------|------|
| 容器名称 | bx_wlyz |
| 镜像 | bx_wlyz:latest |
| 重启策略 | unless-stopped |
| 端口映射 | 8080:80 |

## 配置说明

### 端口映射
- **主机 8080** → **容器 80**：HTTP 访问端口

### 环境变量
- 从 `.env` 文件加载环境变量
- Apache 运行用户：`www-data`
- Apache 运行组：`www-data`

### 数据卷
- `./logs:/var/log/apache2` - Apache 日志目录映射

### 网络
- 使用外部网络 `default_network`（桥接模式）
- 需要预先创建该网络：`docker network create default_network`

## 使用方法

### 前置要求

1. 确保已构建镜像 `bx_wlyz:latest`
2. 创建 `.env` 文件配置必要的环境变量（见下方说明）
3. 创建 Docker 网络（首次运行）：
   ```bash
   docker network create default_network
   ```

### 环境变量配置 (.env)

在项目根目录创建 `.env` 文件，配置以下变量：

```bash
# 数据库配置
DB_HOST=mysql-5.7        # 数据库主机地址（需与数据库容器在同一网络，可填写容器名）
DB_PORT=3306             # 数据库端口
DB_USER=bx               # 数据库用户名
DB_PASSWORD=your_pass    # 数据库密码
DB_NAME=bx               # 数据库名称
DB_PREFIX=bx_            # 表名前缀

# 应用配置
APP_DEBUG=false          # 调试模式 (true/false)
APP_KEY=unlock           # 程序密钥
APP_TIMEZONE=PRC         # 时区设置
```

**配置说明：**
- `DB_HOST`: MySQL 数据库地址，如果使用独立的数据库容器，填写容器名称
- `DB_PREFIX`: 数据表前缀，默认 `bx_`，修改后需重新安装程序
- `APP_DEBUG`: 生产环境建议设置为 `false`
- `APP_KEY`: 程序加密密钥，建议修改为随机字符串

## 首次启动自动安装

容器在**首次启动**时会自动执行安装流程,无需访问host/install手动安装：

### 自动安装流程

1. **等待数据库连接**：容器会等待 MySQL 数据库就绪（最多 30 次重试，每次 5 秒）
2. **创建数据库**：如果数据库不存在，自动创建并设置字符集为 UTF-8
3. **导入表结构**：自动执行 `docker-compose/docker-install.sql` 创建所有数据表
4. **创建锁文件**：在 `install/` 目录生成 `install.lock` 和 `update.lock`，防止重复安装
5. **设置权限**：自动设置 `/config`、`/install`、`/public` 目录权限
6. **启动服务**：启动 Apache Web 服务

### 安装后信息

- **默认管理员账号**: `admin`
- **默认管理员密码**: `admin`
- **访问地址**: http://localhost:8080/admin/Home/show

### 重新安装

如需重新安装，请执行以下操作：

```bash
# 1. 进入容器
docker exec -it bx_wlyz bash

# 2. 删除锁文件
rm /var/www/html/install/install.lock
rm /var/www/html/install/update.lock

# 3. 重启容器
docker-compose restart
```

> ⚠️ **注意**: 重新安装会清空现有数据，请提前备份！

### 启动服务

```bash
docker-compose up -d
```

首次启动时会自动执行数据库初始化，等待日志中出现 `=== 初始化完成 ===` 即表示安装成功。

### 停止服务

```bash
docker-compose down
```

### 查看日志

```bash
docker-compose logs -f bx_wlyz
```

## 访问应用

首次启动初始化完成后，通过以下地址访问：

- **代理后台**: http://localhost:8080/agent/Home/show
- **管理后台**: http://localhost:8080/admin/Home/show
  - 账号: `admin`
  - 密码: `admin`

> 💡 **提示**: 建议在首次登录后立即修改默认密码。

## 文件结构

```
docker-compose/
├── docker-compose.yml    # Docker Compose 配置
├── docker-install.sql    # Docker专用SQL文件
├── .env                  # 环境变量文件（需自行创建）
└── logs/                 # Apache 日志目录
```

**说明：**
- `docker-install.sql`: Docker容器首次启动时自动导入的SQL文件，表前缀已固定为 `bx_`
- `install/install.sql`: 供网页安装使用的原始SQL文件，使用 `{ABC}` 占位符供安装时动态替换

## 注意事项

- 确保端口 8080 未被占用
- 日志文件将保存在主机的 `./logs` 目录中
- 使用外部网络便于与其他容器通信

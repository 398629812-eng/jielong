# 部署指南

## 环境要求

- Node.js 18+
- MySQL 8.0+
- Flutter 3.x SDK（客户端开发/构建）
- Nginx（可选，生产环境推荐）
- PM2（可选，生产环境进程管理）

---

## 后端部署

### 1. 环境准备

```bash
# Ubuntu/Debian 示例
sudo apt update
sudo apt install -y nodejs npm mysql-server

# 或安装 MySQL 8.0
sudo apt install -y mysql-server-8.0
sudo mysql_secure_installation
```

### 2. 数据库初始化

```bash
# 创建数据库
mysql -u root -p -e "CREATE DATABASE jielong CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 导入表结构和初始数据
mysql -u root -p jielong < backend/scripts/init_db.sql
```

> init_db.sql 已包含：
> - 8 张数据表（users, gold_records, withdrawals, ad_records, game_records, configs, announcements, admin_users）
> - 初始配置数据（金币比例、广告奖励、提现门槛等）
> 初始化脚本不会创建固定管理员或测试用户。请在部署后通过受控流程创建账号，禁止使用默认密码。
> - 示例公告数据

### 3. 配置环境变量

```bash
cd backend
cp .env.example .env
nano .env
```

```env
PORT=3000
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=jielong
JWT_SECRET=your_random_jwt_secret_here_change_in_production
JWT_EXPIRES_IN=7d
ADMIN_JWT_SECRET=your_admin_jwt_secret_here_different_from_user
```

> ⚠️ 生产环境务必修改 JWT_SECRET 和 ADMIN_JWT_SECRET，且两者必须不同！

### 4. 安装依赖并启动

```bash
cd backend
npm install

# 开发模式
npm run dev

# 生产模式（使用 PM2）
npm install -g pm2
pm2 start server.js --name "jielong-api"
pm2 save
pm2 startup
```

### 5. Nginx 反向代理（推荐）

```nginx
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

> 配置 HTTPS 后，建议启用 HSTS 和安全头。

---

## 管理后台部署

### 1. 开发模式运行

```bash
cd admin
npm install
npm run dev
# 打开 http://localhost:5173
```

### 2. 生产构建

```bash
cd admin
npm run build
# 输出到 dist/ 目录
```

### 3. 部署到 Nginx

```bash
# 将构建产物复制到 Nginx 目录
sudo cp -r dist/* /var/www/jielong-admin/
```

```nginx
server {
    listen 80;
    server_name admin.yourdomain.com;
    root /var/www/jielong-admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

> 管理后台是单页应用（SPA），需要配置 `try_files` 支持前端路由。

---

## 客户端部署

### 1. 开发调试

```bash
cd mobile
flutter pub get
flutter run
```

### 2. 修改 API 地址

编辑 `mobile/lib/utils/constants.dart`：

```dart
const String API_BASE_URL = 'http://your-server-domain:3000/api';
// 生产环境改为真实域名
```

### 3. Android 构建

```bash
cd mobile
flutter build apk --release
# 输出：build/app/outputs/flutter-apk/app-release.apk
```

### 4. HarmonyOS 构建（需 flutter_harmony 适配）

```bash
# 确保已安装 flutter_harmony 工具链
flutter build hap --release
# 输出：build/harmony/outputs/...
```

> 鸿蒙构建需要额外的 flutter_harmony 配置，详见 [flutter_harmony 文档](https://gitee.com/openharmony-sig/flutter_harmony)。

### 5. 广告 SDK 接入（生产环境）

编辑 `mobile/lib/services/ad_service.dart`：

1. 将 `TEST_MODE = false`
2. 实现 `_showTencentAd()` 方法（优量汇 Android SDK）
3. 实现 `_showHuaweiAd()` 方法（华为 Ads Kit）
4. 在 `pubspec.yaml` 中添加对应 SDK 依赖

```yaml
# 优量汇（Android）
dependencies:
  gdt_ads: ^1.0.0

# 华为 Ads Kit（HarmonyOS）
dependencies:
  huawei_ads: ^1.0.0
```

---

## 云服务器推荐配置

| 组件 | 最低配置 | 推荐配置 |
|------|---------|---------|
| 后端 | 1核2GB 1Mbps | 2核4GB 3Mbps |
| 数据库 | 1核1GB（RDS） | 2核4GB（RDS） |
| 存储 | 20GB SSD | 50GB SSD |
| 客户端 | 无服务器成本 | CDN 加速 APK 分发 |

---

## 安全建议

1. **HTTPS 强制**：生产环境必须使用 HTTPS，证书可用 Let's Encrypt
2. **JWT 密钥**：生产环境必须更换随机长字符串，且用户和管理员密钥不同
3. **数据库**：root 密码强加密，创建独立应用账号，限制访问IP
4. **防刷**：已内置广告频率限制、游戏金币上限、设备指纹检测，但生产环境建议配合 WAF
5. **提现审核**：生产环境建议全部走人工审核，避免自动化打款被利用
6. **日志**：开启 Nginx 和 Node.js 访问日志，定期审计异常请求

---

## 监控与运维

### 使用 PM2 监控

```bash
pm2 monit              # 实时监控
pm2 logs jielong-api    # 查看日志
pm2 reload jielong-api  # 热重启
```

### 数据库备份

```bash
# 每日备份脚本（加入 crontab）
mysqldump -u root -p jielong > /backup/jielong-$(date +%Y%m%d).sql
```

### 日志轮转

```bash
# 使用 logrotate 配置
/var/log/jielong/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 0644 www-data www-data
}
```

---

## 更新部署

```bash
# 拉取最新代码
git pull origin main

# 后端更新
cd backend
npm install
pm2 reload jielong-api

# 管理后台更新
cd admin
npm install
npm run build
sudo cp -r dist/* /var/www/jielong-admin/

# 数据库迁移（如有 schema 变更）
mysql -u root -p jielong < backend/scripts/migrate.sql
```

# 腾讯云生产部署指南

本文档用于把项目部署到腾讯云服务器。目标是让后端 API、管理后台和数据库在正式环境稳定运行，并为后续接入短信、广告 SDK、提现通道留好位置。

## 1. 推荐资源

测试期可以先用一台轻量服务器：

| 资源 | 建议 |
| --- | --- |
| 系统 | Ubuntu 22.04 LTS |
| CPU/内存 | 2 核 4 GB 起步 |
| 磁盘 | 50 GB SSD 起步 |
| 带宽 | 3 Mbps 起步 |
| 数据库 | 前期可同机 MySQL，正式运营建议迁移到腾讯云数据库 |

正式对外运营前，建议准备两个域名：

- `api.example.com`：后端 API
- `admin.example.com`：管理后台

域名、备案、短信服务、广告平台、提现商户号应由运营公司主体申请和持有。

## 2. 服务器初始化

登录服务器后执行：

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl git nginx mysql-server
```

安装 Node.js 20：

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

安装 PM2：

```bash
sudo npm install -g pm2
pm2 -v
```

初始化 MySQL 安全设置：

```bash
sudo mysql_secure_installation
```

## 3. 创建数据库和应用账号

登录 MySQL：

```bash
sudo mysql
```

执行以下 SQL。请把密码替换为强密码，不要使用示例值：

```sql
CREATE DATABASE jielong CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'jielong_app'@'localhost' IDENTIFIED BY 'replace_with_a_strong_password';
GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, ALTER, INDEX ON jielong.* TO 'jielong_app'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

导入数据库结构：

```bash
cd /var/www/jielong
mysql -u jielong_app -p jielong < backend/scripts/init_db.sql
```

如果是从旧版本升级，还需要按时间顺序执行迁移脚本：

```bash
mysql -u jielong_app -p jielong < backend/scripts/migrate_20260620_daily_tasks.sql
mysql -u jielong_app -p jielong < backend/scripts/migrate_20260620_reward_integrity.sql
mysql -u jielong_app -p jielong < backend/scripts/migrate_20260625_spin_limit.sql
mysql -u jielong_app -p jielong < backend/scripts/migrate_20260625_ad_revenue_fields.sql
```

全新数据库只导入 `init_db.sql` 即可。

## 4. 上传代码

推荐目录：

```bash
sudo mkdir -p /var/www
sudo chown -R $USER:$USER /var/www
cd /var/www
git clone git@github.com:your-org-or-user/jielong.git jielong
cd jielong
```

如果服务器没有 GitHub SSH key，也可以由负责人下载压缩包上传到 `/var/www/jielong`。

## 5. 配置后端环境变量

```bash
cd /var/www/jielong/backend
cp .env.production.example .env
nano .env
```

必须修改：

- `DB_PASSWORD`
- `JWT_SECRET`
- `ADMIN_JWT_SECRET`
- `CORS_ORIGINS`

生成随机密钥示例：

```bash
openssl rand -base64 48
```

注意：

- `.env` 不允许提交到 Git。
- `JWT_SECRET` 和 `ADMIN_JWT_SECRET` 必须不同。
- 生产环境 `NODE_ENV` 必须是 `production`。
- `CORS_ORIGINS` 只写正式后台域名，不要保留测试地址。

## 6. 启动后端

安装依赖：

```bash
cd /var/www/jielong/backend
npm ci
```

创建管理员账号。密码只临时放在当前命令环境中，用完立即清除：

```bash
export ADMIN_INITIAL_PASSWORD='replace_with_a_strong_admin_password'
npm run create:admin
unset ADMIN_INITIAL_PASSWORD
```

使用 PM2 启动：

```bash
pm2 start ecosystem.config.example.js --env production
pm2 save
pm2 startup
```

检查状态：

```bash
pm2 status
pm2 logs jielong-api
curl http://127.0.0.1:3000/health
```

## 7. 构建管理后台

```bash
cd /var/www/jielong/admin
cp .env.production.example .env.production
nano .env.production
npm ci
npm run build
```

后台构建产物在 `admin/dist`。

## 8. 配置 Nginx

创建后台目录：

```bash
sudo mkdir -p /var/www/jielong-admin
sudo rsync -av --delete /var/www/jielong/admin/dist/ /var/www/jielong-admin/
```

创建 Nginx 配置：

```bash
sudo nano /etc/nginx/sites-available/jielong.conf
```

写入：

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

server {
    listen 80;
    server_name admin.example.com;
    root /var/www/jielong-admin;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

启用配置：

```bash
sudo ln -s /etc/nginx/sites-available/jielong.conf /etc/nginx/sites-enabled/jielong.conf
sudo nginx -t
sudo systemctl reload nginx
```

## 9. 配置 HTTPS

域名解析完成后安装证书工具：

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d api.example.com -d admin.example.com
```

检查自动续期：

```bash
sudo certbot renew --dry-run
```

## 10. 构建 Android 测试包

在开发电脑执行：

```bash
cd mobile
flutter pub get
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com/api \
  --dart-define=TEST_MODE=false
```

测试期如果广告 SDK 尚未正式接入，可以使用：

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.example.com/api \
  --dart-define=TEST_MODE=true
```

正式对外发布前必须确认：

- 短信验证码为真实服务。
- 广告奖励以服务端回调为准。
- 测试模式没有误开。
- 隐私政策、用户协议、SDK 清单已经准备。

## 11. 日常维护命令

查看后端状态：

```bash
pm2 status
pm2 logs jielong-api
```

重启后端：

```bash
pm2 reload jielong-api
```

更新代码：

```bash
cd /var/www/jielong
git pull

cd backend
npm ci
pm2 reload jielong-api

cd ../admin
npm ci
npm run build
sudo rsync -av --delete dist/ /var/www/jielong-admin/
sudo systemctl reload nginx
```

数据库备份：

```bash
mkdir -p /var/backups/jielong
mysqldump -u jielong_app -p jielong > /var/backups/jielong/jielong-$(date +%F).sql
```

## 12. 上线前检查

- 后端 `/health` 返回正常。
- 管理后台可以登录。
- 手机号登录可以收到真实验证码。
- 用户金币、签到、转盘和后台账本同步。
- 广告收益记录能进入后台。
- 提现必须走人工审核。
- Nginx 只暴露 80/443，MySQL 不开放公网。
- `.env`、私钥、数据库密码没有进入仓库。

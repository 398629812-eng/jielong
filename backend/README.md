# 成语接龙后端服务

Node.js + Express + MySQL 后端 API，支持成语接龙游戏、广告变现、金币提现、管理后台等完整功能。

## 技术栈

- Node.js 18+ / Express 4.x
- MySQL 8.0 + mysql2 (Promise-based)
- JWT 认证（用户 + 管理员双密钥）
- bcryptjs 密码加密
- express-rate-limit 频率限制
- helmet + cors 安全中间件

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，配置数据库密码和 JWT 密钥
```

### 3. 初始化数据库

```bash
mysql -u root -p
CREATE DATABASE jielong CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE jielong;
SOURCE scripts/init_db.sql;
```

### 4. 启动服务

```bash
npm start      # 生产模式
npm run dev    # 开发模式（nodemon 热重载）
```

服务默认运行在 `http://localhost:3000`。

## 测试账号

| 账号 | 密码 | 说明 |
|------|------|------|
仓库不预置固定管理员、手机号或密码。部署后请生成 bcrypt 哈希并通过受控流程创建管理员。

## 目录结构

```
backend/
├── server.js                 # 入口
├── .env.example              # 环境变量模板
├── scripts/
│   └── init_db.sql           # 数据库初始化脚本
├── src/
│   ├── config/
│   │   └── db.js             # MySQL 连接池
│   ├── middleware/
│   │   ├── auth.js           # JWT 用户认证
│   │   ├── adminAuth.js      # 管理员权限
│   │   └── rateLimiter.js    # 频率限制
│   ├── routes/
│   │   ├── auth.js           # 认证（登录/注册/短信）
│   │   ├── user.js           # 用户资料/流水
│   │   ├── gold.js           # 金币/广告/签到/转盘
│   │   ├── game.js           # 游戏逻辑
│   │   ├── withdraw.js       # 提现申请
│   │   ├── config.js         # 配置/公告
│   │   └── admin.js          # 管理后台
│   ├── models/
│   │   └── index.js          # 数据库操作封装
│   ├── services/
│   │   ├── idiomValidator.js # 成语接龙验证算法（核心）
│   │   ├── antiCheat.js      # 防作弊检测
│   │   └── adReward.js       # 广告奖励发放
│   └── utils/
│       ├── jwt.js             # JWT 工具
│       └── response.js        # 统一响应格式
```

## API 接口概览

| 前缀 | 功能 | 认证 |
|------|------|------|
| `/api/auth` | 登录/注册/短信/微信/游客 | 否 |
| `/api/user` | 用户资料、金币/游戏/提现历史 | 是 |
| `/api/gold` | 广告奖励、签到、转盘、提示 | 是 |
| `/api/game` | 开始游戏、验证接龙、提示、结束、排行榜 | 是 |
| `/api/withdraw` | 提现申请、配置 | 是 |
| `/api/config` | 前端配置、公告 | 否 |
| `/api/admin` | 仪表盘、用户管理、审核、配置 | 管理员 |

## 核心算法说明

### 成语接龙验证（idiomValidator.js）

加载 `shared/data/idioms.json` 到内存 Map，构建首字/尾字拼音索引：
- **validateIdiom**：检查存在性、首字拼音匹配、是否已使用
- **findNextIdioms**：根据难度（easy/normal/hard）筛选后续可接成语
- **getRandomStartIdiom**：随机选择尾字有后续的起始成语

### 防作弊（antiCheat.js）

- 广告次数每日上限（默认 50 次）
- 游戏金币每日上限（默认 1000）
- 同设备检测（device_id）
- IP 频率限制（内存存储，每小时自动清理）
- User-Agent 模拟器/脚本检测

## 统一响应格式

```json
{
  "code": 0,
  "message": "ok",
  "data": { ... }
}
```

code 为 0 表示成功，非 0 表示错误。认证接口需在 Header 中携带 `Authorization: Bearer <token>`。

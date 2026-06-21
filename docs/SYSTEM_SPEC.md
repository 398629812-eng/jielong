# 成语接龙休闲游戏 — 系统设计规范

## 项目概述

一个以成语接龙为核心玩法的休闲益智游戏，当前支持 Android 与 Web 测试运行，包含广告、金币和提现的模拟业务闭环。

---

## 目录结构

```
jielong/
├── docs/SYSTEM_SPEC.md        # 本文件：系统设计规范
├── README.md                  # 项目总说明
├── backend/                   # Node.js + Express + MySQL 后端
│   ├── package.json
│   ├── server.js
│   ├── src/
│   │   ├── config/
│   │   ├── routes/
│   │   ├── models/
│   │   ├── middleware/
│   │   ├── services/
│   │   └── utils/
│   └── scripts/
├── admin/                     # React + Ant Design 管理后台
│   ├── package.json
│   ├── public/
│   └── src/
│       ├── components/
│       ├── pages/
│       ├── api/
│       └── App.tsx
├── mobile/                    # Flutter 客户端（Android + Web）
│   ├── pubspec.yaml
│   └── lib/
│       ├── main.dart
│       ├── screens/
│       ├── widgets/
│       ├── services/
│       ├── models/
│       └── utils/
├── shared/                    # 共享数据与工具
│   └── data/
│       └── idioms.json        # 10000+ 成语数据
└── docs/                      # 文档
    ├── API.md
    └── DEPLOY.md
```

---

## 技术栈

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| 客户端 | Flutter 3.x | 一套代码覆盖 Android + Web |
| 后端 | Node.js + Express + MySQL 8.0 | RESTful API，JWT 认证 |
| 管理后台 | React 18 + Ant Design 5.x | 单页面应用，调用后端 API |
| 广告适配层 | 当前为可替换的模拟实现 | 激励视频测试流程 |
| 部署 | 云服务器 + PM2 + Nginx | 标准部署 |

---

## 数据库 Schema (MySQL)

### 用户表 `users`
```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  phone VARCHAR(20) UNIQUE,
  openid VARCHAR(64) UNIQUE,          -- 微信 openid
  nickname VARCHAR(50),
  avatar VARCHAR(255),
  gold INT DEFAULT 0,                   -- 金币余额
  total_withdrawn INT DEFAULT 0,       -- 累计已提现金币
  hints INT DEFAULT 3,                 -- 提示次数
  is_guest TINYINT DEFAULT 1,          -- 是否游客
  is_banned TINYINT DEFAULT 0,
  last_sign_in_date DATE,
  consecutive_sign_in INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 金币流水表 `gold_records`
```sql
CREATE TABLE gold_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  amount INT NOT NULL,                 -- 正数=增加，负数=消耗
  type ENUM('ad_watch','game','record','sign_in','spin','task','withdraw','hint') NOT NULL,
  description VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 提现记录表 `withdrawals`
```sql
CREATE TABLE withdrawals (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  gold_amount INT NOT NULL,            -- 消耗金币数
  rmb_amount DECIMAL(10,2) NOT NULL,   -- 人民币金额
  method ENUM('wechat','alipay') NOT NULL,
  account_info VARCHAR(100),           -- 支付宝账号/微信openid
  status ENUM('pending','approved','rejected','paid') DEFAULT 'pending',
  reject_reason VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

### 广告观看记录表 `ad_records`
```sql
CREATE TABLE ad_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  ad_type VARCHAR(20) NOT NULL,        -- hint / continue / sign_in / spin / task
  platform VARCHAR(20),                -- tencent / huawei
  transaction_id VARCHAR(255),          -- 广告平台回调ID
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 游戏记录表 `game_records`
```sql
CREATE TABLE game_records (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  difficulty ENUM('easy','normal','hard') NOT NULL,
  rounds INT NOT NULL,                  -- 成功轮数
  idiom_chain JSON NOT NULL,            -- 成语链条
  is_record TINYINT DEFAULT 0,         -- 是否刷新纪录
  score INT DEFAULT 0,                 -- 获得金币
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 系统配置表 `configs`
```sql
CREATE TABLE configs (
  id INT AUTO_INCREMENT PRIMARY KEY,
  key VARCHAR(50) UNIQUE NOT NULL,
  value TEXT NOT NULL,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
-- 初始配置：
-- ad_gold_reward: 500
-- gold_to_rmb: 10000
-- withdraw_min: 10000
-- withdraw_max: 50000
-- daily_ad_limit: 50
-- game_gold_per_round: 10
-- game_gold_daily_cap: 1000
-- record_gold_reward: 2000
-- sign_in_base: 50
```

### 系统公告表 `announcements`
```sql
CREATE TABLE announcements (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  content TEXT NOT NULL,
  is_active TINYINT DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## RESTful API 接口规范

### 认证相关
- `POST /api/auth/send-sms` — 发送手机验证码
- `POST /api/auth/phone-login` — 手机号验证码登录
- `POST /api/auth/wechat-login` — 微信授权登录
- `GET /api/auth/refresh` — 刷新 JWT Token

### 用户相关
- `GET /api/user/profile` — 获取个人资料（金币、提示、昵称等）
- `PUT /api/user/profile` — 更新昵称/头像
- `GET /api/user/gold-history` — 金币流水（分页）
- `GET /api/user/game-history` — 游戏历史记录（分页）
- `GET /api/user/withdraw-history` — 提现记录

### 金币/广告相关
- `POST /api/gold/ad-reward` — 广告观看完成奖励
  - Body: `{ ad_type: string, transaction_id?: string }`
  - 后端校验：当日上限、频率、防刷
- `POST /api/gold/game-reward` — 游戏结算金币奖励
  - Body: `{ rounds: number, is_record: boolean }`
- `POST /api/gold/sign-in` — 每日签到（含翻倍逻辑）
- `POST /api/gold/spin` — 转盘抽奖
- `POST /api/gold/use-hint` — 消耗提示次数

### 提现相关
- `POST /api/withdraw/apply` — 提交提现申请
  - Body: `{ amount: number, method: 'wechat'|'alipay', account_info: string }`
- `GET /api/withdraw/config` — 获取提现配置（门槛、比例、限制）

### 游戏相关
- `GET /api/game/start` — 开始新游戏，返回起始成语
  - Query: `difficulty=easy|normal|hard`
- `POST /api/game/validate` — 验证玩家接龙
  - Body: `{ game_id: string, idiom: string, previous_idiom: string }`
  - Response: `{ valid: boolean, next_idiom?: string, message?: string }`
- `POST /api/game/hint` — 获取提示（可接成语）
  - Body: `{ game_id: string, current_idiom: string }`
- `POST /api/game/end` — 结束游戏，保存记录
  - Body: `{ game_id: string, rounds: number, chain: string[], reason: string }`
- `GET /api/game/leaderboard` — 排行榜（按轮数/分数）

### 配置/公告
- `GET /api/config` — 获取前端配置（广告ID、金币比例、公告等）
- `GET /api/announcements` — 获取活跃公告列表

### 管理后台接口（前缀 `/api/admin`，需管理员权限）
- `GET /api/admin/dashboard` — 仪表盘数据
- `GET /api/admin/users` — 用户列表/搜索
- `PUT /api/admin/users/:id/ban` — 封禁/解封用户
- `GET /api/admin/gold-records` — 金币流水查询
- `GET /api/admin/withdrawals` — 提现申请列表
- `PUT /api/admin/withdrawals/:id/approve` — 通过提现
- `PUT /api/admin/withdrawals/:id/reject` — 拒绝提现
- `PUT /api/admin/configs` — 更新系统配置
- `GET /api/admin/idioms` — 成语库管理（增删改查）
- `POST /api/admin/idioms/import` — 导入JSON
- `POST /api/admin/idioms/export` — 导出JSON
- `GET /api/admin/announcements` — 公告管理
- `POST /api/admin/announcements` — 发布公告
- `DELETE /api/admin/announcements/:id` — 删除公告

---

## 接口统一响应格式

```json
{
  "code": 0,           // 0=成功，非0=错误码
  "message": "ok",
  "data": { ... }
}
```

认证：HTTP Header `Authorization: Bearer <JWT>`

---

## 防作弊机制

1. **广告验证**：后端记录广告平台回调（transaction_id），频率限制
2. **每日上限**：每用户每日广告观看上限（默认50次），后端计数
3. **游戏金币上限**：每日通过游戏获得金币上限（默认1000）
4. **同设备检测**：设备指纹 + IP 监控，后端记录 device_id 和 IP
5. **模拟器检测**：User-Agent 特征检测（后端辅助，客户端为主）
6. **提现风控**：最低门槛、单笔上限、每日次数限制、人工审核

---

## 各模块职责边界

### 后端模块 (backend/)
- 实现所有 RESTful API
- MySQL 数据库连接、模型定义、初始化脚本
- JWT 认证中间件
- 防刷/频率限制中间件
- 成语验证算法（后端也要有，防客户端伪造）
- 导出：完整的 Node.js 项目，可 `npm install && npm start` 运行

### 管理后台模块 (admin/)
- React + Ant Design 单页应用
- 调用 backend API（管理后台前缀）
- 仪表盘、用户管理、金币流水、提现审核、成语库、配置、公告
- 导出：完整的 React 项目，可独立运行

### 客户端模块 (mobile/)
- Flutter 项目骨架
- 首页、游戏界面、个人中心、提现、签到、转盘、任务中心
- HTTP 客户端封装，调用 backend API
- 本地成语数据库加载（JSON 文件）
- 广告 SDK 接入接口封装（留出插件接口）
- 导出：Flutter 项目，可 `flutter run` 运行

### 数据模块 (shared/)
- 生成 10000+ 成语数据 JSON
- 每个成语包含：成语、拼音（带声调）、释义、首字拼音、尾字拼音
- 导出：idioms.json 及生成脚本

---

## 客户端页面结构（Flutter）

1. **Splash/启动页** → 自动登录或选择登录方式
2. **主界面** (HomeScreen)
   - 顶部：金币余额、提示次数、头像
   - 中部：开始游戏（简单/普通/困难）
   - 底部导航：签到、提现、排行榜、我的
3. **游戏界面** (GameScreen)
   - 成语链条展示（聊天气泡式）
   - 输入框 + 确认按钮
   - 计时器（进度条）
   - 提示按钮、续命按钮
   - 结算弹窗（轮数、金币、纪录）
4. **个人中心** (ProfileScreen)
   - 头像、昵称、金币、累计收益、提示次数
   - 菜单：提现、金币明细、提现记录、联系客服、设置
5. **提现界面** (WithdrawScreen)
   - 余额展示、输入金额、选择方式、提交
6. **签到/转盘/任务** (RewardScreen)
   - 日历签到、转盘抽奖、每日任务列表

---

## 设计风格

- 中国风 + 简洁现代
- 主色调：淡雅水墨风格，白色/浅灰背景，黑色/深灰文字
- 强调色：金色（金币、红包）、红色（按钮、激励）
- 字体：系统默认中文字体，标题可加粗
- 元素：圆角卡片、轻微阴影、水墨纹理背景（可选）
- 图标：使用 Material Icons / Fluent Icons

---

## 交付要求

1. 所有代码包含中文注释，核心逻辑（接龙算法、防作弊）详细注释
2. 提供 `README.md` 说明各端运行方式
3. 提供数据库初始化脚本（`scripts/init_db.sql`）
4. 通过受控流程创建临时演示账号，禁止仓库内固定用户名或默认密码
5. 广告 SDK 接入保留测试模式配置

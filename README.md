# 成语接龙 — 休闲益智游戏项目

> 一款支持 Android + HarmonyOS 双平台的成语接龙休闲游戏，通过激励视频广告变现，用户赚取金币可提现。

---

## 项目概览

| 模块 | 技术栈 | 说明 |
|------|--------|------|
| 客户端 (Android + HarmonyOS) | Flutter 3.x | 一套代码双平台运行，支持鸿蒙适配层 |
| 后端 API | Node.js + Express + MySQL | RESTful API，JWT 认证，防刷机制 |
| 管理后台 | React 18 + Ant Design 5 + Vite | 运营管理系统，数据可视化 |
| 成语数据库 | JSON + Python | 10,010 条常用成语，100% 接龙覆盖率 |

---

## 快速开始

### 1. 后端服务

```bash
cd backend
cp .env.example .env
# 编辑 .env，配置数据库连接
npm install
# 初始化数据库（MySQL 8.0+）
mysql -u root -p < scripts/init_db.sql
npm start
# 服务运行在 http://localhost:3000
```

### 2. 管理后台

```bash
cd admin
npm install
npm run dev
# 打开 http://localhost:5173
# 管理员账号需在部署后通过受控流程创建
```

### 3. Flutter 客户端

```bash
cd mobile
# 确保已安装 Flutter SDK (3.x+)
flutter pub get
# 安卓调试
flutter run
# 构建 APK
flutter build apk --release
```

---

## 测试账号

| 类型 | 账号 | 密码 | 初始状态 |
|------|------|------|---------|
仓库不提供固定管理员、测试手机号或默认密码。请在本地数据库初始化后，通过受控流程创建测试账号。

> 游客模式可直接试玩，无需登录，但提现需绑定手机号。

---

## 项目结构

```
jielong/
├── AGENT_SPEC.md          # 架构设计与接口规范
├── README.md              # 本文件
├── backend/               # Node.js 后端
│   ├── server.js
│   ├── .env.example
│   ├── scripts/
│   │   └── init_db.sql    # 数据库初始化（8张表 + 测试数据）
│   └── src/
│       ├── config/        # 数据库连接
│       ├── middleware/    # 认证、频率限制
│       ├── routes/        # 所有 API 路由
│       ├── models/        # 数据库操作封装
│       ├── services/      # 核心：成语验证、防作弊、广告奖励
│       └── utils/         # JWT、统一响应
├── admin/                 # React 管理后台
│   ├── src/
│   │   ├── api/           # Axios 封装
│   │   ├── components/    # 布局组件
│   │   ├── pages/         # 仪表盘、用户、提现、成语库等
│   │   └── utils/         # 认证工具
│   └── package.json
├── mobile/                # Flutter 客户端
│   ├── lib/
│   │   ├── screens/       # 10+ 页面（游戏/登录/提现/排行榜等）
│   │   ├── widgets/       # 复用组件（气泡/计时器/按钮等）
│   │   ├── services/      # API/广告/成语库/认证
│   │   ├── models/        # 数据模型
│   │   └── utils/         # 常量/拼音/验证
│   ├── assets/
│   │   └── idioms.json    # 10,010 条本地成语库
│   └── pubspec.yaml
├── shared/
│   └── data/              # 成语数据生成与验证脚本
│       ├── idioms.json
│       ├── generate_idioms.py
│       └── validate_idioms.py
└── docs/
    ├── API.md             # 接口详细文档
    └── DEPLOY.md          # 部署指南
```

---

## 核心功能

### 游戏玩法
- 三种难度：简单（60秒）、普通（30秒）、困难（15秒）
- AI 智能接龙：简单随机、普通生僻尾字、困难压缩可选范围
- 实时验证：本地成语库 O(1) 查询，首字拼音匹配（支持同音不同调）
- 提示系统：消耗提示次数显示可接成语，次数需看广告获取
- 续命机制：失败后可看广告继续，每局限1次

### 经济系统
- 金币：观看广告 +500/次，每轮接龙 +10，刷新纪录 +2000
- 提现：10000 金币 = 1 元，最低 1 元起提，后台审核
- 每日签到、转盘抽奖、任务中心

### 防作弊
- 广告观看次数上限（每日可配置）
- 游戏金币每日上限
- 同设备多账号检测
- 提现风控：人工审核 + 状态管理

---

## 广告 SDK 接入说明

客户端已预留广告 SDK 接口，测试模式直接模拟播放：

| 平台 | SDK | 文件 | 说明 |
|------|-----|------|------|
| Android | 优量汇（腾讯） | `mobile/lib/services/ad_service.dart` | 预留接口，替换模拟实现即可 |
| HarmonyOS | 华为 Ads Kit | `mobile/lib/services/ad_service.dart` | 预留接口，替换模拟实现即可 |

修改 `mobile/lib/utils/constants.dart` 中 `TEST_MODE = false` 启用真实广告。

---

## 后端 API 概览

### 认证
- `POST /api/auth/phone-login` — 手机号登录
- `POST /api/auth/guest-login` — 游客登录
- `POST /api/auth/wechat-login` — 微信登录（预留）

### 游戏
- `GET /api/game/start?difficulty=easy` — 开始游戏
- `POST /api/game/validate` — 验证接龙
- `POST /api/game/hint` — 获取提示
- `POST /api/game/end` — 结束结算

### 金币/广告
- `POST /api/gold/ad-reward` — 广告奖励上报
- `POST /api/game/end` — 按服务端局内状态结算游戏金币
- `POST /api/gold/sign-in` — 每日签到
- `POST /api/game/hint` — 校验当前游戏并消耗提示

### 提现
- `POST /api/withdraw/apply` — 提交申请
- `GET /api/withdraw/config` — 提现配置

### 管理后台（需管理员权限）
- `POST /api/admin/login` — 管理员登录
- `GET /api/admin/dashboard` — 仪表盘数据
- `GET /api/admin/users` — 用户管理
- `GET /api/admin/withdrawals` — 提现审核
- `PUT /api/admin/configs` — 系统配置
- `GET/POST /api/admin/idioms` — 成语库 CRUD

详见 `docs/API.md`。

---

## 部署指南

详见 `docs/DEPLOY.md`。

---

## 开发团队

本项目由多智能体并行协作开发完成，包含：
- 后端 API（Node.js + MySQL）
- Flutter 客户端（Android + HarmonyOS）
- React 管理后台（Ant Design）
- 成语数据库（10,010 条，覆盖率 100%）

---

## 许可证

MIT License

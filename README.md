# 成语接龙 — 休闲益智游戏项目

> 一款面向 Android 和 Web 的成语接龙休闲游戏，当前提供广告、金币与提现的完整测试流程。

---

## 项目概览

| 模块 | 技术栈 | 说明 |
|------|--------|------|
| 客户端 (Android + Web) | Flutter 3.x | 一套代码覆盖移动端与浏览器测试 |
| 后端 API | Node.js + Express + MySQL | RESTful API，JWT 认证，防刷机制 |
| 管理后台 | React 18 + Ant Design 5 + Vite | 运营管理系统，数据可视化 |
| 成语数据库 | JSON + Python | 10,010 条常用成语，100% 接龙覆盖率 |

---

## 交付与部署入口

正式交付或部署前，建议先阅读以下文档：

| 文档 | 用途 |
|------|------|
| `docs/DEPLOY_TENCENT_CLOUD.md` | 腾讯云生产部署步骤 |
| `docs/HANDOVER_CHECKLIST.md` | 源码、配置、账号、验收交付清单 |
| `docs/SECURITY_CHECKLIST.md` | 密钥、隐私、服务器、提现和广告安全检查 |
| `docs/THIRD_PARTY_INTEGRATION.md` | 短信、广告 SDK、提现通道接入边界 |
| `docs/DEPLOY.md` | 通用部署说明 |

仓库只提交示例配置文件，不提交真实 `.env`、私钥、短信密钥、广告平台密钥、支付或提现密钥。

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
# 管理员账号需在部署后执行 npm run create:admin 创建
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

> 金币、签到和提现均要求手机号登录，所有余额以服务端记录为准。

---

## 项目结构

```
jielong/
├── docs/SYSTEM_SPEC.md    # 系统设计与接口规范
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
    ├── DEPLOY.md          # 通用部署指南
    ├── DEPLOY_TENCENT_CLOUD.md
    ├── HANDOVER_CHECKLIST.md
    ├── SECURITY_CHECKLIST.md
    └── THIRD_PARTY_INTEGRATION.md
```

---

## 核心功能

### 游戏玩法
- 三种难度：简单（60秒）、普通（30秒）、困难（15秒）
- 系统自动接龙：简单随机、普通生僻尾字、困难压缩可选范围
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

构建时使用 `--dart-define=TEST_MODE=false` 关闭模拟流程；接入并验收真实广告 SDK 后才可用于生产。

---

## 后端 API 概览

### 认证
- `POST /api/auth/phone-login` — 手机号登录
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

通用部署详见 `docs/DEPLOY.md`。腾讯云生产部署和交付验收详见 `docs/DEPLOY_TENCENT_CLOUD.md` 与 `docs/HANDOVER_CHECKLIST.md`。

---

## 许可证

MIT License

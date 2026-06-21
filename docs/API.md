# API 接口文档

> 后端服务地址：`http://localhost:3000`
> 所有接口（除登录/注册外）需在 Header 中携带 `Authorization: Bearer <JWT>`

---

## 统一响应格式

```json
{
  "code": 0,        // 0=成功，非0=错误码
  "message": "ok",
  "data": { ... }
}
```

---

## 认证接口

### POST /api/auth/send-sms
发送手机验证码（模拟实现，直接返回固定验证码）

**请求**
```json
{ "phone": "<测试手机号>" }
```

**响应**
```json
{ "code": 0, "message": "测试验证码已生成", "data": { "test_code": "<四位测试验证码>" } }
```

---

### POST /api/auth/phone-login
手机号验证码登录

**请求**
```json
{ "phone": "<测试手机号>", "code": "<四位验证码>" }
```

**响应**
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbG...",
    "user": { "id": 1, "phone": "<已脱敏手机号>", "nickname": "测试用户", "gold": 0, "hints": 3, "is_guest": false }
  }
}
```

---

### POST /api/auth/guest-login
游客登录（无需输入，自动生成临时ID）

**响应**
```json
{
  "code": 0,
  "data": {
    "token": "eyJhbG...",
    "user": { "id": 999, "nickname": "游客999", "gold": 0, "hints": 3, "is_guest": true }
  }
}
```

---

### POST /api/auth/wechat-login
微信授权登录（预留接口，目前返回未实现）

**请求**
```json
{ "code": "wx_auth_code" }
```

---

### POST /api/auth/bind-phone
游客绑定手机号

**请求**
```json
{ "phone": "<测试手机号>", "code": "<四位验证码>" }
```

---

## 用户接口

### GET /api/user/profile
获取个人资料

**响应**
```json
{
  "code": 0,
  "data": {
    "id": 1,
    "nickname": "用户1",
    "phone": "<已脱敏手机号>",
    "avatar": "",
    "gold": 100000,
    "hints": 5,
    "total_withdrawn": 0,
    "is_guest": false,
    "consecutive_sign_in": 3,
    "last_sign_in_date": "2025-06-18"
  }
}
```

---

### PUT /api/user/profile
更新个人资料

**请求**
```json
{ "nickname": "新昵称", "avatar": "url" }
```

---

### GET /api/user/gold-history
金币流水（分页）

**查询参数**
- `page` — 页码（默认1）
- `pageSize` — 每页数量（默认20）

**响应**
```json
{
  "code": 0,
  "data": {
    "list": [
      { "id": 1, "amount": 500, "type": "ad_watch", "description": "观看广告", "created_at": "2025-06-18 10:00:00" }
    ],
    "total": 100,
    "page": 1,
    "pageSize": 20
  }
}
```

---

### GET /api/user/game-history
游戏历史记录（分页）

---

### GET /api/user/withdraw-history
提现记录

---

## 金币/广告接口

### POST /api/gold/ad-reward
广告观看完成奖励

**请求**
```json
{
  "ad_type": "hint",           // hint / continue / sign_in_double / spin / task
  "transaction_id": "tx_123"   // 可选，广告平台回调ID
}
```

**防刷校验**
- 检查当日广告次数是否达上限（configs.daily_ad_limit）
- 检查 transaction_id 是否重复（如提供）
- 通过后才发放金币

**响应**
```json
{ "code": 0, "message": "奖励已发放", "data": { "gold_added": 500, "new_balance": 100500 } }
```

---

> `POST /api/gold/game-reward` 已停用并返回 HTTP 410。游戏奖励统一由 `POST /api/game/end` 根据服务端局内状态结算。

---

### POST /api/gold/sign-in
每日签到

**响应**
```json
{ "code": 0, "data": { "base_reward": 50, "can_double": true, "new_balance": 100050 } }
```

> 签到后若观看广告可使当日金币翻倍（调用 `ad-reward` 类型 `sign_in_double`）

---

### POST /api/gold/spin
转盘抽奖

**响应**
```json
{ "code": 0, "data": { "reward": 500, "new_balance": 100500 } }
```

---

> `POST /api/gold/use-hint` 已停用并返回 HTTP 410。提示统一使用 `POST /api/game/hint`，并校验服务端当前游戏状态。

---

## 游戏接口

### GET /api/game/start
开始新游戏

**查询参数**
- `difficulty` — `easy` / `normal` / `hard`

**响应**
```json
{
  "code": 0,
  "data": {
    "game_id": "uuid-123",
    "start_idiom": {
      "idiom": "一心一意",
      "pinyin": "yī xīn yī yì",
      "meaning": "心思、意念专一。"
    }
  }
}
```

---

### POST /api/game/validate
验证玩家接龙

**请求**
```json
{
  "game_id": "uuid-123",
  "idiom": "意味深长",
  "previous_idiom": "一心一意"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "valid": true,
    "next_idiom": {
      "idiom": "长治久安",
      "pinyin": "cháng zhì jiǔ ān",
      "meaning": "国家长期安定、巩固。"
    }
  }
}
```

> `valid=false` 时返回 `message` 说明原因（不存在/首字不匹配/已重复）

---

### POST /api/game/hint
获取提示（可接成语）

**请求**
```json
{
  "game_id": "uuid-123",
  "current_idiom": "意味深长"
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "hint": {
      "idiom": "长治久安",
      "pinyin": "cháng zhì jiǔ ān",
      "meaning": "国家长期安定、巩固。"
    }
  }
}
```

---

### POST /api/game/end
结束游戏，保存记录

**请求**
```json
{
  "game_id": "uuid-123",
  "rounds": 15,
  "chain": ["一心一意", "意味深长", "长治久安"],
  "reason": "timeout"   // timeout / wrong / quit
}
```

**响应**
```json
{
  "code": 0,
  "data": {
    "rounds": 15,
    "is_record": true,
    "gold_reward": 2150,   // 15*10 + 2000
    "new_balance": 102150
  }
}
```

---

### GET /api/game/leaderboard
排行榜

**查询参数**
- `type` — `rounds` / `score` / `weekly`
- `limit` — 返回数量（默认50）

---

## 提现接口

### POST /api/withdraw/apply
提交提现申请

**请求**
```json
{
  "amount": 10,            // 元（整数）
  "method": "wechat",      // wechat / alipay
  "account_info": "openid_or_account"
}
```

**校验规则**
- 金币余额 >= amount * gold_to_rmb
- amount >= withdraw_min / gold_to_rmb
- amount <= withdraw_max / gold_to_rmb
- 每日次数限制

**响应**
```json
{ "code": 0, "data": { "withdrawal_id": 1, "status": "pending" } }
```

---

### GET /api/withdraw/config
获取提现配置

**响应**
```json
{
  "code": 0,
  "data": {
    "gold_to_rmb": 10000,
    "min_amount": 1,
    "max_amount": 5,
    "daily_limit": 3
  }
}
```

---

## 配置/公告接口

### GET /api/config
获取前端动态配置

**响应**
```json
{
  "code": 0,
  "data": {
    "ad_gold_reward": 500,
    "gold_to_rmb": 10000,
    "withdraw_min": 10000,
    "withdraw_max": 50000,
    "daily_ad_limit": 50,
    "game_gold_per_round": 10,
    "game_gold_daily_cap": 1000,
    "record_gold_reward": 2000,
    "sign_in_base": 50,
    "announcements": [
      { "id": 1, "title": "欢迎", "content": "欢迎来到成语接龙！" }
    ]
  }
}
```

---

### GET /api/announcements
获取公告列表

---

## 管理后台接口

所有管理接口前缀 `/api/admin`，需管理员 JWT（`Authorization: Bearer <admin_token>`）

### POST /api/admin/login
管理员登录

**请求**
```json
{ "username": "<管理员用户名>", "password": "<强密码>" }
```

**响应**
```json
{ "code": 0, "data": { "token": "eyJhbG...", "admin": { "id": 1, "username": "admin" } } }
```

---

### GET /api/admin/dashboard
仪表盘数据

**响应**
```json
{
  "code": 0,
  "data": {
    "today_active": 150,
    "today_new_users": 20,
    "today_ad_watches": 800,
    "today_gold_issued": 400000,
    "today_withdraw": 150.00
  }
}
```

---

### GET /api/admin/users
用户列表

**查询参数**
- `page`, `pageSize`
- `keyword` — 搜索手机号/昵称

---

### PUT /api/admin/users/:id/ban
封禁/解封用户

**请求**
```json
{ "is_banned": 1 }   // 1=封禁, 0=解封
```

---

### GET /api/admin/gold-records
金币流水查询

**查询参数**
- `user_id`, `type`, `page`, `pageSize`

---

### GET /api/admin/withdrawals
提现申请列表

**查询参数**
- `status` — `pending` / `approved` / `rejected` / `paid`
- `page`, `pageSize`

---

### PUT /api/admin/withdrawals/:id/approve
通过提现

**响应**
```json
{ "code": 0, "message": "提现已通过" }
```

---

### PUT /api/admin/withdrawals/:id/reject
拒绝提现

**请求**
```json
{ "reason": "余额异常，疑似刷量" }
```

---

### GET /api/admin/configs
获取系统配置

---

### PUT /api/admin/configs
更新系统配置

**请求**
```json
{
  "ad_gold_reward": 500,
  "gold_to_rmb": 10000,
  "withdraw_min": 10000,
  "withdraw_max": 50000,
  "daily_ad_limit": 50,
  "game_gold_per_round": 10,
  "game_gold_daily_cap": 1000,
  "record_gold_reward": 2000,
  "sign_in_base": 50
}
```

---

### GET /api/admin/idioms
成语列表

**查询参数**
- `keyword` — 按成语搜索
- `page`, `pageSize`

---

### POST /api/admin/idioms
新增成语

**请求**
```json
{
  "idiom": "新成语",
  "pinyin": "xīn chéng yǔ",
  "meaning": "释义",
  "first_pinyin": "xīn",
  "last_pinyin": "yǔ"
}
```

---

### PUT /api/admin/idioms/:id
修改成语

---

### DELETE /api/admin/idioms/:id
删除成语

---

### POST /api/admin/idioms/import
导入 JSON

**请求**
```json
[
  { "idiom": "...", "pinyin": "...", "meaning": "...", "first_pinyin": "...", "last_pinyin": "..." }
]
```

---

### POST /api/admin/idioms/export
导出 JSON

**响应**
```json
{
  "code": 0,
  "data": { "idioms": [ ... ], "total": 10010 }
}
```

---

### GET /api/admin/announcements
公告列表

---

### POST /api/admin/announcements
发布公告

**请求**
```json
{ "title": "标题", "content": "内容" }
```

---

### DELETE /api/admin/announcements/:id
删除公告

---

## 错误码

| 错误码 | 说明 |
|--------|------|
| 0 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（Token 无效或过期） |
| 403 | 无权限（非管理员） |
| 404 | 资源不存在 |
| 429 | 请求过于频繁（防刷触发） |
| 1001 | 金币不足 |
| 1002 | 提示次数不足 |
| 1003 | 广告次数已达上限 |
| 1004 | 游戏金币已达日上限 |
| 1005 | 提现金额不足最低门槛 |
| 1006 | 提现金额超过单笔上限 |
| 1007 | 当日提现次数已达上限 |
| 1008 | 成语不存在 |
| 1009 | 接龙不合法（首字不匹配） |
| 1010 | 成语已重复 |
| 1011 | 同设备多账号检测异常 |
| 2001 | 验证码错误 |
| 2002 | 手机号已绑定 |
| 2003 | 游客模式不能提现 |

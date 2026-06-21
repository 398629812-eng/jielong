# Architecture

## 系统组成

```text
Flutter App
    |
    | HTTPS / JSON API
    v
Express Backend ---- MySQL
    ^
    |
React Admin
```

`shared/data/idioms.json` 是成语主数据。移动端副本用于离线体验，后端副本用于权威验证；更新时必须同步并运行验证脚本。

## 责任边界

### Flutter App

- 展示游戏、广告模拟、金币和提现界面。
- 收集用户操作并请求后端。
- 可做即时 UI 反馈，但不可权威修改可提现余额。

### Express Backend

- 认证、成语验证、游戏结算、奖励发放、提现状态管理。
- 维护余额与流水事务一致性。
- 执行频率限制、幂等校验和基础风险控制。

### React Admin

- 查询用户、流水、广告记录和提现申请。
- 修改运营配置并执行人工审核。
- 不直接连接数据库，只调用管理员 API。

## 外部能力适配层

```text
AdProvider:      MockAdProvider -> TencentAdProvider / HuaweiAdProvider
SmsProvider:     MockSmsProvider -> VendorSmsProvider
LoginProvider:   MockLoginProvider -> WeChatLoginProvider
PayoutProvider:  MockPayoutProvider -> WeChatPayoutProvider / AlipayPayoutProvider
```

当前只允许 Mock 实现。运行环境决定 Provider，业务代码不得散布平台 SDK 判断。

## 金币账本

- `users.gold` 是余额快照，`gold_records` 是审计流水。
- 一次奖励必须在同一数据库事务中更新余额、写入流水及业务记录。
- 每个奖励事件使用唯一幂等键；相同事件重试只能返回原结果。
- API 成功响应应返回服务端最新余额，由客户端覆盖本地缓存。
- 提现策略需在审计后确定为“申请即冻结”或“审核通过再扣减”，全系统只能保留一种规则。

## 环境隔离

- `development/test`：模拟广告、验证码和提现，界面明确标注测试环境。
- `production`：未配置真实 Provider 时拒绝启动相关能力，不允许自动回退为 Mock。
- 密钥只存在环境变量或密钥服务中，不提交到 Git。

## 待验证架构项

- 已修复：游戏开局、验证和结算使用服务端状态，客户端不再直接加游戏金币。
- 已修复：模拟广告先经后端幂等事务确认，再刷新客户端和执行 UI 回调。
- 已修复：Android API 地址由构建参数注入，Debug Manifest 单独允许本地 HTTP。
- 已修复：提现申请、拒绝退款、审核支付和累计提现使用事务与行锁。
- 已修复：旧 `/gold/game-reward` 与 `/gold/use-hint` 返回 HTTP 410，不再修改资产；分别由 `/game/end` 与 `/game/hint` 取代。
- 已修复：每日任务进度由服务端聚合，领取通过唯一键与事务幂等发奖。
- 已修复：管理后台正式运行路径已移除 Mock；仪表盘、成语库、配置和运营操作均读取管理 API。
- 已修复：`shared/data/idioms.json` 可通过 `npm run import:idioms` 幂等同步到 MySQL，游戏内存词库与后台管理词库保持同源。
- `device_id` 等风控字段是否与数据库 Schema 一致。

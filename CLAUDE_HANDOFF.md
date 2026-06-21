# Claude Handoff

## 角色约定

Codex 是项目负责人，维护目标、架构、任务边界和最终验收。Claude Code 是实现副手，负责被明确分配的小任务。未列入任务范围的重构不得顺手进行。

## 每次开工前

按顺序阅读：

1. `PROJECT_BRIEF.md`
2. `ROADMAP.md`
3. `ARCHITECTURE.md`
4. `DECISIONS.md`
5. `TASKS.md`
6. 本文件最新任务

然后执行 `git status --short`，确认已有用户或其他 agent 改动。不得覆盖、回滚或格式化无关文件。

## 任务模板

```text
Task ID:
Goal:
Allowed files:
Forbidden files/modules:
Inputs:
Expected outputs:
Acceptance tests:
Non-goals:
```

## 结果回报模板

```text
Task ID:
Status: completed / blocked
Changed files:
Behavior changed:
Tests run and exact results:
Known risks:
Suggested follow-up:
Commit hash: optional; only commit when explicitly requested
```

## 当前交接状态

建立本文件时存在的 Claude Code 交互窗口实际处于空闲状态，随后由用户关闭，没有新增代码产出。已观察到以下历史未提交修改：

- `backend/src/models/index.js`
- `backend/src/services/idiomValidator.js`
- Flutter 平台生成文件和锁文件
- 后端依赖及本地环境文件

这些改动尚未由 Codex 验收。Codex 将结合实际运行测试决定保留、调整和提交方式。

## 下一张任务票

当前允许派发新的小任务，但默认先使用只读或 `plan` 权限。编码任务必须由 Codex 明确列出允许修改的文件和验收测试。

## 会话记录

### CONTEXT-001（2026-06-20）

- 模式：新建非交互会话，只开放 `Read`。
- 结果：成功读取六份项目大脑，正确复述 V0.1 阶段、Claude 副手角色、三条硬边界和下一任务。
- 结论：项目上下文可通过仓库文档恢复，不依赖旧聊天记录。

### AUDIT-002-PRECHECK（2026-06-20）

- 模式：只读综合审计。
- 结果：124 秒无输出后终止。
- 处理：将任务拆分为上下文恢复和单文件审查，后续均成功。
- 经验：Kimi 驱动的 Claude 会话应保持任务窄、文件少、输出受限。

### AUDIT-002A（2026-06-20）

- 模式：`plan`，只开放 `Read` 与 `Bash`，只审查 `backend/src/models/index.js`。
- 结果：Claude 认为分页参数转字符串可能绕过 mysql2 prepared statement 报错，无 SQL 注入增量风险，但依赖 MySQL 隐式转换且缺少分页边界校验。
- 验收状态：仅静态审查通过，尚未在当前 MySQL 环境复现，不能认定修复完成。
- 后续：测试正常分页、偏移分页、零值、负值、非数字以及修改前后的真实驱动行为。

### AUDIT-002B（2026-06-20）

- 模式：`plan`，只开放 `Read` 与 `Bash`，只审查 `backend/src/services/idiomValidator.js`。
- Claude 结论：三级 `__dirname` 路径适配当前常规结构；`process.cwd()` 只能作为最后兜底；数据文件缺失时静默继续启动存在风险。
- Codex 验收：分别从 `E:\jielong` 和 `E:\jielong\backend` 加载模块，均成功构建 10,010 条成语索引。
- 验收状态：当前路径修复可保留。
- 后续任务：单独处理成语主数据缺失或解析失败时的 fail-fast 行为，并补充自动测试。

### MOBILE-001 至 MOBILE-005（2026-06-20）

- `MOBILE-001`：修复三处 `showRewardedAd` 位置参数调用；验收通过。
- `MOBILE-002`：为用户资料 fallback Map 补充 `Map<String, dynamic>` 类型；验收通过。
- `MOBILE-003`：移除缺失的 NotoSansSC 字体声明，V0.1 使用平台默认中文字体；验收通过。
- `MOBILE-004`：用 `JieLongApp` 根组件冒烟测试替换默认 Counter 测试。Claude 会话在回报前超时，代码已落盘。
- `MOBILE-005`：修复 `MaterialColor` 色阶缺少 50 导致 `ThemeData` 构建崩溃。Claude 会话在测试阶段超时，Codex 接管验收，测试通过。
- 最终证据：Flutter 全量 analyze 无 error（剩 warning/info）；`flutter test` 通过；`flutter build apk --debug` 成功。
- 协作经验：小修由 Codex 直接完成更快；Claude 主要承担跨文件、批量和可独立验收的实现任务。

### GAME-ONLINE-001（2026-06-20）

- 任务：仅修改 `mobile/lib/screens/game_screen.dart`，接通服务端开局和接龙验证。
- Claude 产出：完成异步开局、加载/错误/重试状态、服务端验证、服务端系统回复及本地成语详情映射。
- 会话状态：执行 184 秒后在回报阶段超时，代码已完整落盘；遗留 Claude 进程由 Codex 终止。
- Codex 修正：删除系统无词时客户端直接加币，接通 `/game/end` 服务端结算和失败重试；后端改为忽略客户端伪造轮数与链条。
- 验收：Flutter 无编译错误、测试通过、Debug APK 构建成功；浏览器实测游客登录、开局和一轮服务端接龙通过。
- 经验：Claude 适合完成此类跨方法主体改造，但核心资金边界和最终运行验收仍由 Codex 执行。

### TASKS-ONLINE-001A（2026-06-20）

- 任务：Claude 仅实现后端每日任务表、进度接口和幂等奖励。
- 会话状态：运行超过三分钟无输出后终止，未留下任务模块代码。
- Codex 接管：实现 `task_claims`、幂等迁移、四项进度聚合、领取事务及移动端接入。
- 验收：未完成领取拒绝；三次广告后可领取；两个并发请求仅一个成功；金币增加一次且流水只有一条；Flutter 测试和 APK 构建通过。
- 经验：Kimi 驱动的 Claude 在本机长任务中仍可能无产出卡住；后续只在预计收益明显时调用。

### ADMIN-SYNC-001（2026-06-20）

- 执行者：Codex 直接完成；未调用 Claude，原因是接口契约审计、连续运行验收和小步修复由同一上下文处理总耗时更低。
- 产出：管理后台七个页面全部接入真实 API；仪表盘新增 7 日趋势与最近流水；共享词库 10,010 条同步至 MySQL。
- 验收：后台生产构建通过；配置保存、公告增删、成语搜索/导出、仪表盘接口均通过真实 MySQL 测试。

### MOBILE-HISTORY-001 / LEADERBOARD-ONLINE-001（2026-06-20）

- 执行者：Codex 直接完成；均为现有接口上的连续小范围接线与验收。
- 产出：金币明细、提现记录使用真实分页；提现页移除示例记录；排行榜按用户最高成绩返回真实名次。
- 验收：真实令牌接口测试、目标文件 analyze、Flutter 组件测试和 Android Debug APK 构建通过。

### CLEANUP-001 检查点（2026-06-20）

- 执行者：Codex 直接完成；未调用 Claude。
- 已完成：移除未使用导入、字段、方法与旧广告弹窗；修复异步上下文检查；保留现有常量公共命名并关闭对应风格 lint；应用 Dart 安全 const 修复。
- 验收：`flutter analyze --no-pub` 为 `No issues found`，`flutter test` 全部通过。
- 下一步：下线可绕过权威游戏流程的旧资金接口并更新 API 文档。

### CLEANUP-001 完成（2026-06-20）

- 旧 `/gold/game-reward`、`/gold/use-hint` 已改为无副作用的 HTTP 410 兼容门；客户端封装和 API 文档已同步。
- 运行验收：伪造 999 轮与伪造提示均返回 410，金币和提示次数保持不变。
- 全量验收：Flutter analyze 0 项、测试通过、Debug APK 成功；后端 JavaScript 全量语法通过；管理后台生产构建通过。
- 下一阶段：执行 V0.1 关键流程 E2E 与视觉验收，再整理外部 Provider 边界。

### E2E-V01-001 API 阶段（2026-06-21）

- 执行者：Codex；未调用 Claude。
- 主链路：游客登录、开局、真实接龙、提示、服务端结算、金币流水、游戏历史、排行榜、每日任务与游客提现拒绝均通过。
- 漏洞修复：`/game/hint` 新增当前链尾校验及原子扣减；伪造提示不扣次数，5 并发仅 3 次成功且余额不为负。
- 恢复说明：受跨工作区补丁工具异常影响，`game.js` 曾短暂从工作树消失；已从 Git 基线恢复并重新应用权威结算、排行榜去重与提示修复，随后完成语法和运行复测。
- 构建：Flutter analyze 0 项、测试通过、Debug APK 成功；管理后台生产构建通过。
- 未完成：浏览器视觉控制受 Windows 沙箱启动失败阻塞；服务和 Web 页面本身均返回 HTTP 200。

## 禁止事项

- 不提交 `.env`、密钥、令牌或真实账号信息。
- 不提交 `node_modules`、构建产物或无关平台生成目录。
- 不把模拟广告替换成未经确认的第三方 SDK。
- 不在客户端直接确认可提现金币到账。
- 不以“代码看起来正确”代替测试结果。

# 成语接龙 - Flutter 客户端

基于 Flutter 3.x 的跨平台成语接龙游戏客户端，支持 Android 和 HarmonyOS。

## 功能特性

- 成语接龙核心玩法（简单/普通/困难三种难度）
- 本地成语数据库（10000+ 条成语）
- 金币系统与激励视频广告变现
- 微信/支付宝提现功能
- 签到、转盘、任务奖励系统
- 全服排行榜
- 中国风 UI 设计

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── screens/                   # 页面层
│   ├── splash_screen.dart     # 启动页
│   ├── login_screen.dart      # 登录页
│   ├── home_screen.dart       # 主界面
│   ├── game_screen.dart       # 游戏界面
│   ├── game_over_screen.dart  # 游戏结算
│   ├── profile_screen.dart    # 个人中心
│   ├── withdraw_screen.dart   # 提现
│   ├── rewards_screen.dart    # 奖励页（签到/转盘/任务）
│   ├── leaderboard_screen.dart # 排行榜
│   └── settings_screen.dart   # 设置
├── widgets/                   # 自定义组件
│   ├── idiom_bubble.dart      # 成语聊天气泡
│   ├── gold_display.dart      # 金币展示
│   ├── countdown_timer.dart   # 倒计时
│   ├── custom_button.dart     # 统一按钮
│   ├── difficulty_card.dart   # 难度卡片
│   ├── hint_dialog.dart       # 提示弹窗
│   ├── ad_reward_dialog.dart  # 广告奖励弹窗
│   └── continue_dialog.dart   # 续命弹窗
├── services/                  # 服务层
│   ├── api_service.dart       # HTTP API 封装
│   ├── auth_service.dart      # 登录状态管理
│   ├── idiom_service.dart     # 本地成语数据库
│   └── ad_service.dart        # 广告SDK封装
├── models/                    # 数据模型
│   ├── user.dart              # 用户模型
│   ├── idiom.dart             # 成语模型
│   ├── game_state.dart        # 游戏状态
│   ├── gold_record.dart       # 金币记录
│   └── leaderboard_entry.dart # 排行榜条目
└── utils/                     # 工具类
    ├── constants.dart         # 常量配置
    ├── pinyin_helper.dart     # 拼音处理
    └── validators.dart        # 输入验证
```

## 运行方式

```bash
cd mobile
flutter pub get
flutter run
```

## 技术栈

- Flutter 3.x
- http, shared_preferences, flutter_bloc, animated_text_kit, audioplayers
- Material Design 3 + 中国风主题

import 'package:flutter/material.dart';

/// 应用常量配置类
/// 集中管理所有颜色、字体、API地址、难度配置等常量
/// 方便全局统一修改和主题切换
class Constants {
  // ==================== 测试模式开关 ====================
  /// 测试模式开关：true时广告直接跳过播放，模拟成功
  /// 用于开发调试和商店审核测试，生产环境应设为false
  static const bool TEST_MODE = bool.fromEnvironment(
    'TEST_MODE',
    defaultValue: true,
  );

  // ==================== API 配置 ====================
  /// 后端 API 基础地址。可通过 --dart-define=API_BASE_URL=... 注入。
  /// 默认值用于本机 Web/桌面开发；Android 模拟器应使用 10.0.2.2。
  static const String API_BASE_URL = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  /// 连接超时时间（秒）
  static const int CONNECT_TIMEOUT = 10;

  /// 读取超时时间（秒）
  static const int READ_TIMEOUT = 15;

  // ==================== 颜色配置（中国风主题） ====================
  /// 主色：红色（用于按钮、强调、警告）
  static const Color PRIMARY_RED = Color(0xFFE53935);

  /// 深红色（用于按钮按下状态、渐变结束）
  static const Color PRIMARY_RED_DARK = Color(0xFFC62828);

  /// 金色（用于金币、奖励、高亮）
  static const Color GOLD = Color(0xFFFFD700);

  /// 深金色（用于渐变、边框）
  static const Color GOLD_DARK = Color(0xFFFFB300);

  /// 绿色（系统成语气泡、简单难度）
  static const Color SYSTEM_GREEN = Color(0xFF4CAF50);

  /// 绿色浅渐变（系统气泡背景）
  static const Color SYSTEM_GREEN_LIGHT = Color(0xFFE8F5E9);

  /// 红色（玩家成语气泡、困难难度）
  static const Color PLAYER_RED = Color(0xFFE53935);

  /// 红色浅渐变（玩家气泡背景）
  static const Color PLAYER_RED_LIGHT = Color(0xFFFFEBEE);

  /// 橙色（普通难度）
  static const Color ORANGE = Color(0xFFFF9800);

  /// 背景色：浅灰白（水墨风格底色）
  static const Color BACKGROUND = Color(0xFFF5F5F5);

  /// 卡片背景色：白色
  static const Color CARD_WHITE = Color(0xFFFFFFFF);

  /// 文字主色：深灰黑
  static const Color TEXT_PRIMARY = Color(0xFF212121);

  /// 文字次色：中灰
  static const Color TEXT_SECONDARY = Color(0xFF757575);

  /// 文字提示色：浅灰
  static const Color TEXT_HINT = Color(0xFFBDBDBD);

  /// 分割线颜色
  static const Color DIVIDER = Color(0xFFE0E0E0);

  /// 警告红色（倒计时低于5秒）
  static const Color WARNING_RED = Color(0xFFD32F2F);

  /// 微信绿色（提现方式选择）
  static const Color WECHAT_GREEN = Color(0xFF07C160);

  /// 支付宝蓝色（提现方式选择）
  static const Color ALIPAY_BLUE = Color(0xFF1677FF);

  // ==================== 字体配置 ====================
  /// 标题字体大小（AppBar标题、页面大标题）
  static const double FONT_TITLE = 20.0;

  /// 大标题字体大小（成语接龙标题）
  static const double FONT_HEADLINE = 28.0;

  /// 超大数字（结算页轮数）
  static const double FONT_HUGE = 72.0;

  /// 正文字体大小
  static const double FONT_BODY = 16.0;

  /// 小字字体大小（拼音、释义）
  static const double FONT_SMALL = 14.0;

  /// 超小字体大小（标签、角标）
  static const double FONT_TINY = 12.0;

  // ==================== 难度配置 ====================
  /// 简单难度：每轮60秒，系统随机选择可接成语
  static const int EASY_SECONDS = 60;
  static const String EASY_NAME = '简单';
  static const String EASY_DESC = '60秒/轮 · 轻松接龙';

  /// 普通难度：每轮30秒，系统优先选择尾字生僻的成语
  static const int NORMAL_SECONDS = 30;
  static const String NORMAL_NAME = '普通';
  static const String NORMAL_DESC = '30秒/轮 · 正常挑战';

  /// 困难难度：每轮15秒，系统计算后选择最难接的成语
  static const int HARD_SECONDS = 15;
  static const String HARD_NAME = '困难';
  static const String HARD_DESC = '15秒/轮 · 极限挑战';

  // ==================== 金币配置 ====================
  /// 每轮基础金币奖励
  static const int GOLD_PER_ROUND = 10;

  /// 刷新纪录额外奖励
  static const int RECORD_GOLD_REWARD = 2000;

  /// 金币转人民币比例（10000金币 = 1元）
  static const int GOLD_TO_RMB = 10000;

  /// 最低提现门槛（1元 = 10000金币）
  static const int WITHDRAW_MIN_GOLD = 10000;

  /// 默认提示次数（新用户赠送）
  static const int DEFAULT_HINTS = 3;

  // ==================== 广告配置 ====================
  /// 每日广告观看上限（后端防刷校验）
  static const int DAILY_AD_LIMIT = 50;

  /// 每日游戏金币上限
  static const int DAILY_GAME_GOLD_CAP = 1000;

  /// 激励视频广告模拟播放时长（毫秒，测试模式）
  static const int AD_SIMULATE_DURATION_MS = 2000;

  // ==================== 游戏配置 ====================
  /// 成语长度要求（必须是4字）
  static const int IDIOM_LENGTH = 4;

  /// 续命每局限1次
  static const bool LIMIT_CONTINUE_PER_GAME = true;

  /// 新纪录动画持续时间（毫秒）
  static const int RECORD_ANIMATION_DURATION_MS = 1500;

  // ==================== 间距和圆角 ====================
  /// 标准圆角（卡片、按钮）
  static const double BORDER_RADIUS = 16.0;

  /// 小圆角（输入框、标签）
  static const double BORDER_RADIUS_SMALL = 8.0;

  /// 标准内边距
  static const double PADDING = 16.0;

  /// 标准卡片阴影
  static const double CARD_ELEVATION = 2.0;

  // ==================== 存储键名（SharedPreferences） ====================
  /// 用户数据存储键
  static const String PREFS_USER_KEY = 'user_data';

  /// 设置项：音效开关
  static const String PREFS_SOUND_ENABLED = 'sound_enabled';

  /// 设置项：同音不同调开关
  static const String PREFS_ALLOW_DIFFERENT_TONE = 'allow_different_tone';

  /// 设置项：设备ID（防作弊唯一标识）
  static const String PREFS_DEVICE_ID = 'device_id';

  /// 设置项：上次签到日期
  static const String PREFS_LAST_SIGN_IN = 'last_sign_in_date';

  /// 设置项：本地最高纪录（轮数）
  static const String PREFS_LOCAL_RECORD = 'local_record_rounds';
}

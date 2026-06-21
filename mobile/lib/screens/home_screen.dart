import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/idiom_service.dart';
import '../utils/constants.dart';
import '../widgets/gold_display.dart';
import '../widgets/difficulty_card.dart';
import 'game_screen.dart';
import 'rewards_screen.dart';
import 'withdraw_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// 主界面（Home Screen）
/// 游戏的核心入口页面，包含：
/// 1. 顶部：金币余额（金色大字体）+ 提示次数（灯泡图标）+ 设置按钮
/// 2. 中部：水墨风格装饰 + "成语接龙" 大字标题
/// 3. 难度选择：3张卡片横排（简单绿色60秒/普通橙色30秒/困难红色15秒）
/// 4. 底部大按钮："开始游戏"（红色渐变，圆角）
/// 5. 底部导航栏：签到（日历）、提现（红包）、排行榜（奖杯）、我的（人）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// 当前选中的难度
  String _selectedDifficulty = 'normal';

  /// 金币数量（从 AuthService 获取）
  int _gold = 0;

  /// 提示次数（从 AuthService 获取）
  int _hints = 3;

  @override
  void initState() {
    super.initState();
    // 监听用户数据变化
    AuthService().userNotifier.addListener(_onUserChanged);
    _updateUserInfo();
  }

  @override
  void dispose() {
    AuthService().userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  /// 用户数据变化时更新UI
  void _onUserChanged() {
    if (mounted) {
      setState(() {
        _updateUserInfo();
      });
    }
  }

  /// 从 AuthService 读取最新用户信息
  void _updateUserInfo() {
    final user = AuthService().currentUser;
    if (user != null) {
      _gold = user.gold;
      _hints = user.hints;
    }
  }

  /// 获取当前难度的秒数
  int _getDifficultySeconds() {
    switch (_selectedDifficulty) {
      case 'easy':
        return Constants.EASY_SECONDS;
      case 'hard':
        return Constants.HARD_SECONDS;
      case 'normal':
      default:
        return Constants.NORMAL_SECONDS;
    }
  }

  /// 开始游戏（跳转游戏界面）
  void _startGame() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          difficulty: _selectedDifficulty,
          totalSeconds: _getDifficultySeconds(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '成语接龙',
          style: TextStyle(
            color: Constants.TEXT_PRIMARY,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // 金币显示
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: GoldDisplay(
                gold: _gold,
                iconSize: 20,
                fontSize: 16,
              ),
            ),
          ),
          // 提示次数
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: Constants.GOLD_DARK,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_hints',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Constants.GOLD_DARK,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // 设置按钮
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings, color: Constants.TEXT_SECONDARY),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 水墨风格装饰区 + 标题
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // 装饰文字
                  Text(
                    '成语接龙',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: Colors.grey[300]!,
                          offset: const Offset(2, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '传承中华文化，挑战智慧极限',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 数据库成语数量
                  Text(
                    '收录 ${IdiomService().totalIdiomCount} 条成语',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
            // 难度选择区域
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '选择难度',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Constants.TEXT_PRIMARY,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DifficultyCard(
                        difficulty: 'easy',
                        name: Constants.EASY_NAME,
                        description: Constants.EASY_DESC,
                        isSelected: _selectedDifficulty == 'easy',
                        onTap: () =>
                            setState(() => _selectedDifficulty = 'easy'),
                      ),
                      DifficultyCard(
                        difficulty: 'normal',
                        name: Constants.NORMAL_NAME,
                        description: Constants.NORMAL_DESC,
                        isSelected: _selectedDifficulty == 'normal',
                        onTap: () =>
                            setState(() => _selectedDifficulty = 'normal'),
                      ),
                      DifficultyCard(
                        difficulty: 'hard',
                        name: Constants.HARD_NAME,
                        description: Constants.HARD_DESC,
                        isSelected: _selectedDifficulty == 'hard',
                        onTap: () =>
                            setState(() => _selectedDifficulty = 'hard'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // 开始游戏按钮
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Constants.PRIMARY_RED, Color(0xFFEF5350)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Constants.PRIMARY_RED.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 64),
                  ),
                  child: const Text(
                    '开始游戏',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      // 底部导航栏
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.calendar_today, '签到', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RewardsScreen(initialTab: 0),
                    ),
                  );
                }),
                _buildNavItem(Icons.account_balance_wallet, '提现', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WithdrawScreen()),
                  );
                }),
                _buildNavItem(Icons.emoji_events, '排行榜', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LeaderboardScreen()),
                  );
                }),
                _buildNavItem(Icons.person, '我的', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileScreen()),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建底部导航项
  Widget _buildNavItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Constants.TEXT_SECONDARY,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Constants.TEXT_SECONDARY,
            ),
          ),
        ],
      ),
    );
  }
}

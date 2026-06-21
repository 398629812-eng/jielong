import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import 'withdraw_screen.dart';
import 'settings_screen.dart';
import 'history_screens.dart';

/// 个人中心页面（Profile Screen）
/// 展示用户信息：头像、昵称、金币、累计收益、提示次数
/// 菜单列表：提现、金币明细、提现记录、联系客服、设置
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _gold = 0;
  int _totalWithdrawn = 0;
  int _hints = 3;
  String _nickname = '成语达人';
  bool _isGuest = true;

  @override
  void initState() {
    super.initState();
    AuthService().userNotifier.addListener(_onUserChanged);
    _updateInfo();
  }

  @override
  void dispose() {
    AuthService().userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() => _updateInfo());
  }

  void _updateInfo() {
    final user = AuthService().currentUser;
    if (user != null) {
      _gold = user.gold;
      _totalWithdrawn = user.totalWithdrawn;
      _hints = user.hints;
      _nickname = user.nickname;
      _isGuest = user.isGuest;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('个人中心',
            style: TextStyle(
                color: Constants.TEXT_PRIMARY, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Constants.TEXT_PRIMARY),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 用户信息卡片
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Constants.PRIMARY_RED, Color(0xFFEF5350)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Constants.PRIMARY_RED.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6))
                ],
              ),
              child: Column(
                children: [
                  // 头像
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 12),
                  // 昵称
                  Text(
                    _nickname,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  if (_isGuest) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('游客',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ),
                  ],
                  const SizedBox(height: 20),
                  // 数据统计行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('$_gold', '金币'),
                      Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3)),
                      _buildStatItem('${_totalWithdrawn ~/ 10000}元', '累计提现'),
                      Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withOpacity(0.3)),
                      _buildStatItem('$_hints', '提示次数'),
                    ],
                  ),
                ],
              ),
            ),
            // 菜单列表
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildMenuItem(Icons.account_balance_wallet, '提现', onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WithdrawScreen()));
                  }),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(Icons.history, '金币明细', onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const GoldHistoryScreen()));
                  }),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(Icons.receipt_long, '提现记录', onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const WithdrawHistoryScreen()));
                  }),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(Icons.headset_mic, '联系客服', onTap: () {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(content: Text('客服功能开发中')));
                  }),
                  const Divider(height: 1, indent: 56),
                  _buildMenuItem(Icons.settings, '设置', onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 退出登录
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService().logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Constants.PRIMARY_RED,
                    backgroundColor: Colors.white,
                    elevation: 0,
                    side: const BorderSide(color: Constants.DIVIDER),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('退出登录',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        const SizedBox(height: 4),
        Text(label,
            style:
                TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Constants.PRIMARY_RED, size: 24),
      title: Text(title,
          style: const TextStyle(fontSize: 16, color: Constants.TEXT_PRIMARY)),
      trailing: const Icon(Icons.chevron_right, color: Constants.TEXT_HINT),
      onTap: onTap,
    );
  }
}

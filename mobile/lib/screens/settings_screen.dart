import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'legal_screen.dart';

/// 设置页面（Settings Screen）
/// 包含：
/// 1. 音效开关（控制游戏音效和背景音乐）
/// 2. 同音不同调开关（影响接龙匹配规则：严格匹配/同音不同调）
/// 3. 关于（应用版本、隐私政策、用户协议）
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// 音效开关（默认开启）
  bool _soundEnabled = true;

  /// 同音不同调开关（默认关闭，即严格匹配）
  bool _allowDifferentTone = false;

  /// 应用版本号
  final String _version = '1.0.0';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  /// 从本地存储加载设置
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool(Constants.PREFS_SOUND_ENABLED) ?? true;
      _allowDifferentTone =
          prefs.getBool(Constants.PREFS_ALLOW_DIFFERENT_TONE) ?? false;
    });
  }

  /// 保存设置到本地存储
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(Constants.PREFS_SOUND_ENABLED, _soundEnabled);
    await prefs.setBool(
        Constants.PREFS_ALLOW_DIFFERENT_TONE, _allowDifferentTone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '设置',
          style: TextStyle(
            color: Constants.TEXT_PRIMARY,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Constants.TEXT_PRIMARY),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 游戏设置
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '游戏设置',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Constants.TEXT_SECONDARY,
                      ),
                    ),
                  ),
                  // 音效开关
                  SwitchListTile(
                    title: const Text('音效'),
                    subtitle: const Text('开启游戏音效和背景音乐'),
                    value: _soundEnabled,
                    activeColor: Constants.PRIMARY_RED,
                    onChanged: (value) {
                      setState(() {
                        _soundEnabled = value;
                      });
                      _saveSettings();
                    },
                  ),
                  const Divider(height: 1, indent: 16),
                  // 同音不同调开关
                  SwitchListTile(
                    title: const Text('同音不同调'),
                    subtitle: const Text('允许拼音字母相同但声调不同的成语接龙（如 shí → shì）'),
                    value: _allowDifferentTone,
                    activeColor: Constants.PRIMARY_RED,
                    onChanged: (value) {
                      setState(() {
                        _allowDifferentTone = value;
                      });
                      _saveSettings();
                    },
                  ),
                ],
              ),
            ),
            // 关于
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      '关于',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Constants.TEXT_SECONDARY,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: Constants.PRIMARY_RED),
                    title: const Text('版本号'),
                    trailing: Text(
                      _version,
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip,
                        color: Constants.PRIMARY_RED),
                    title: const Text('隐私政策'),
                    trailing: const Icon(Icons.chevron_right,
                        color: Constants.TEXT_HINT),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LegalScreen.privacy),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.description,
                        color: Constants.PRIMARY_RED),
                    title: const Text('用户协议'),
                    trailing: const Icon(Icons.chevron_right,
                        color: Constants.TEXT_HINT),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => LegalScreen.agreement),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 测试模式提示
            if (Constants.TEST_MODE)
              Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Constants.ORANGE.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '【测试模式】广告已跳过，模拟成功',
                    style: TextStyle(
                      fontSize: 12,
                      color: Constants.ORANGE,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

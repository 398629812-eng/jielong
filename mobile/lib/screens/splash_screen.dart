import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/idiom_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// 启动页（Splash Screen）
/// 应用启动时显示Logo，同时执行以下初始化操作：
/// 1. 加载本地成语数据库（assets/idioms.json）
/// 2. 尝试自动恢复登录状态（SharedPreferences中读取Token）
/// 3. 根据登录状态决定跳转首页或登录选择页
/// 加载完成后自动跳转，无需用户点击
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// 加载进度文字（给用户反馈）
  String _loadingText = '正在加载...';

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化淡出动画
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // 启动初始化流程
    _initializeApp();
  }

  /// 应用初始化流程
  /// 依次加载成语数据库和恢复登录状态，然后跳转
  Future<void> _initializeApp() async {
    try {
      // 步骤1：加载成语数据库（耗时操作，优先执行）
      setState(() {
        _loadingText = '正在加载成语数据库...';
      });
      await IdiomService().loadIdioms();

      // 步骤2：恢复登录状态（异步加载SharedPreferences）
      setState(() {
        _loadingText = '正在恢复登录状态...';
      });
      // AuthService在构造时自动初始化，但需等待完成
      await Future.delayed(const Duration(milliseconds: 300));

      // 步骤3：标记加载完成
      setState(() {
        _loadingText = '加载完成';
      });

      // 延迟后淡出并跳转
      await Future.delayed(const Duration(milliseconds: 800));
      _fadeController.forward().then((_) {
        _navigateToNextScreen();
      });
    } catch (e) {
      // 加载失败时显示错误提示，但仍尝试跳转
      setState(() {
        _loadingText = '加载出错，请稍后重试';
      });
      await Future.delayed(const Duration(seconds: 2));
      _navigateToNextScreen();
    }
  }

  /// 根据登录状态决定跳转页面
  void _navigateToNextScreen() {
    final authService = AuthService();
    final isLoggedIn = authService.isLoggedIn;

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              isLoggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 应用Logo（成语接龙大字 + 装饰）
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text(
                    '成语\n接龙',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // 应用名称
              const Text(
                '成语接龙',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF212121),
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              // 副标题
              Text(
                '挑战你的成语储备',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 48),
              // 加载进度指示器
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.red[400]!,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 加载状态文字
              Text(
                _loadingText,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

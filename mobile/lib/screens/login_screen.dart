import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'home_screen.dart';

/// 登录页（Login Screen）
/// 提供多种登录方式：
/// 1. 手机号+验证码登录（主要方式）
/// 2. 游客登录（快速开始，无需输入）
/// 3. 微信登录（预留接口，按钮灰色占位）
/// 游客登录后可在个人中心绑定手机号
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  /// 手机号输入控制器
  final TextEditingController _phoneController = TextEditingController();

  /// 验证码输入控制器
  final TextEditingController _codeController = TextEditingController();

  /// 当前是否正在发送验证码
  bool _isSendingCode = false;

  /// 验证码倒计时剩余秒数
  int _countdown = 0;

  /// 是否正在登录中
  bool _isLoggingIn = false;

  /// 错误提示文字
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// 发送验证码
  /// 验证手机号格式，然后调用后端发送SMS
  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    final error = Validators.validatePhone(phone);
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _errorText = null;
    });

    try {
      final result = await ApiService().sendSms(phone);
      if (!mounted) return;
      setState(() {
        _countdown = 60;
        if (result is Map && result['test_code'] != null) {
          _codeController.text = result['test_code'].toString();
        }
      });
      if (result is Map && result['test_code'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试验证码已自动填入')),
        );
      }
      _startCountdown();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '发送失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSendingCode = false;
        });
      }
    }
  }

  /// 启动验证码倒计时
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _countdown--;
      });
      if (_countdown > 0) {
        _startCountdown();
      }
    });
  }

  /// 手机号+验证码登录
  Future<void> _phoneLogin() async {
    final phone = _phoneController.text.trim();
    final code = _codeController.text.trim();

    // 验证手机号
    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      setState(() {
        _errorText = phoneError;
      });
      return;
    }

    // 验证验证码
    final codeError = Validators.validateSmsCode(code);
    if (codeError != null) {
      setState(() {
        _errorText = codeError;
      });
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _errorText = null;
    });

    try {
      final user = await AuthService().phoneLogin(phone, code);
      if (user != null && mounted) {
        _navigateToHome();
      } else {
        setState(() {
          _errorText = '登录失败，请重试';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = '登录失败: $e';
      });
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  /// 游客登录（快速开始）
  Future<void> _guestLogin() async {
    setState(() {
      _isLoggingIn = true;
      _errorText = null;
    });

    try {
      final user = await AuthService().guestLogin();
      if (user != null && mounted) {
        _navigateToHome();
      } else {
        setState(() {
          _errorText = '游客登录失败，请重试';
        });
      }
    } catch (e) {
      setState(() {
        _errorText = '登录失败: $e';
      });
    } finally {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  /// 跳转首页
  void _navigateToHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // 应用Logo
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Constants.PRIMARY_RED,
                        Constants.PRIMARY_RED_DARK
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      '成语\n接龙',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  '欢迎回来',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Constants.TEXT_PRIMARY,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '登录后开始挑战成语接龙',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // 手机号输入
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 11,
                decoration: InputDecoration(
                  labelText: '手机号',
                  hintText: '请输入11位手机号',
                  prefixIcon: const Icon(Icons.phone_android),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Constants.DIVIDER),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // 验证码输入
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: '验证码',
                        hintText: '请输入6位验证码',
                        prefixIcon: const Icon(Icons.lock_outline),
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (_countdown > 0 || _isSendingCode)
                            ? null
                            : _sendCode,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Constants.PRIMARY_RED,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _countdown > 0 ? '$_countdown秒' : '获取验证码',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 错误提示
              if (_errorText != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorText!,
                  style: const TextStyle(
                    color: Constants.PRIMARY_RED,
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // 登录按钮
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _phoneLogin,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Constants.PRIMARY_RED,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoggingIn
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          '登录',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // 分割线
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '或',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
              const SizedBox(height: 16),
              // 微信登录按钮（预留，灰色占位）
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: null, // 预留接口，未接入SDK
                  icon: const Icon(Icons.wechat, color: Colors.grey),
                  label: const Text(
                    '微信登录（即将上线）',
                    style: TextStyle(color: Colors.grey),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 游客登录按钮
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: _isLoggingIn ? null : _guestLogin,
                  child: Text(
                    '游客登录（快速开始）',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.grey[400],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // 底部提示
              Center(
                child: Text(
                  '登录即表示同意《用户协议》和《隐私政策》',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

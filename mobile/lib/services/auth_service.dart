import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'api_service.dart';

/// 认证状态管理服务
/// 管理用户登录状态（Token + User Model），通过 ValueNotifier 通知UI更新
/// 使用 SharedPreferences 持久化存储，应用重启后自动恢复登录
class AuthService extends ChangeNotifier {
  /// 单例实例
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    // 初始化时尝试恢复登录状态
    _initFromStorage();
  }

  /// 当前用户数据（null 表示未登录）
  User? _currentUser;

  /// 用户数据变更通知器（用于监听金币、提示等变化）
  final ValueNotifier<User?> userNotifier = ValueNotifier<User?>(null);

  /// 获取当前用户（可能为null）
  User? get currentUser => _currentUser;

  /// 是否已登录（有有效用户数据）
  bool get isLoggedIn => _currentUser != null && _currentUser!.isValid;

  /// 获取当前Token（可能为null）
  String? get token => _currentUser?.token;

  /// SharedPreferences 实例（延迟初始化）
  SharedPreferences? _prefs;

  /// 存储键名（与 Constants.PREFS_USER_KEY 一致）
  static const String _userKey = 'user_data';

  /// 从本地存储初始化登录状态（应用启动时调用）
  /// 异步加载 SharedPreferences，如果之前有保存的用户数据则自动恢复
  Future<void> _initFromStorage() async {
    _prefs = await SharedPreferences.getInstance();
    final userJson = _prefs?.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final restoredUser = User.fromJson(userMap);
        if (restoredUser.isGuest) {
          await _prefs?.remove(_userKey);
          return;
        }
        _currentUser = restoredUser;
        // 恢复Token到API服务
        if (_currentUser?.token != null) {
          ApiService().setToken(_currentUser!.token);
        }
        userNotifier.value = _currentUser;
        notifyListeners();
      } catch (e) {
        // 数据损坏，清除旧数据
        await _prefs?.remove(_userKey);
      }
    }
  }

  /// 保存用户到本地存储（每次更新后调用）
  /// 将用户对象序列化为 JSON 字符串存入 SharedPreferences
  Future<void> _saveToStorage() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_currentUser != null) {
      final userJson = jsonEncode(_currentUser!.toJson());
      await _prefs!.setString(_userKey, userJson);
    } else {
      await _prefs!.remove(_userKey);
    }
  }

  /// 设置当前用户（登录成功后调用）
  /// 同时更新 API 服务的 Token 和通知器
  void setUser(User user) {
    _currentUser = user;
    if (user.token != null) {
      ApiService().setToken(user.token);
    }
    userNotifier.value = user;
    _saveToStorage();
    notifyListeners();
  }

  /// 手机号+验证码登录
  Future<User?> phoneLogin(String phone, String code) async {
    try {
      final response = await ApiService().phoneLogin(phone, code);
      final data = response is Map<String, dynamic> ? response : {};
      final token = data['token'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;
      if (token != null && userData != null) {
        userData['token'] = token;
        final user = User.fromJson(userData);
        setUser(user);
        return user;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// 刷新用户信息（从后端获取最新数据）
  /// 用于游戏结算后、签到后等金币变动的同步
  Future<void> refreshUser() async {
    if (!isLoggedIn) return;
    try {
      final response = await ApiService().getProfile();
      final userData =
          response is Map<String, dynamic> ? response : <String, dynamic>{};
      if (userData.isNotEmpty) {
        // 保留现有token（后端返回可能没有）
        userData['token'] = _currentUser?.token;
        final user = User.fromJson(userData);
        setUser(user);
      }
    } catch (e) {
      // 静默失败，保持本地数据
    }
  }

  /// 退出登录（清除所有用户数据）
  /// 清除本地存储和API Token，返回登录页
  Future<void> logout() async {
    _currentUser = null;
    ApiService().setToken(null);
    userNotifier.value = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_userKey);
    notifyListeners();
  }

  /// 获取用户金币余额（安全访问，未登录返回0）
  int get gold => _currentUser?.gold ?? 0;

  /// 获取用户提示次数（安全访问，未登录返回0）
  int get hints => _currentUser?.hints ?? 0;

  /// 获取用户昵称（安全访问，未登录返回"成语达人"）
  String get nickname => _currentUser?.nickname ?? '成语达人';

  @override
  void dispose() {
    userNotifier.dispose();
    super.dispose();
  }
}

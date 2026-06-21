import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// 广告服务类
/// 封装激励视频广告的展示逻辑，支持真实SDK和模拟模式
///
/// 激励广告类型：
/// - hint: 观看广告获取提示
/// - continue: 观看广告续命继续游戏
/// - sign_in_double: 签到后观看广告翻倍奖励
/// - spin: 转盘观看广告获得额外抽奖机会
/// - task: 完成任务观看广告领取奖励
///
/// 正式广告通过平台适配层接入；未配置服务商时不会发放奖励。
class AdService {
  /// 单例实例
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  /// 是否正在播放广告（防止重复点击）
  bool _isShowingAd = false;

  /// 每日广告计数（本地缓存，实际以上限后端为准）
  int _todayAdCount = 0;

  /// 获取广告是否准备就绪（预留SDK检查）
  /// 实际接入SDK时，应调用广告平台的广告加载状态检查
  /// 返回：true 表示广告已加载可播放，false 表示需要等待加载
  Future<bool> isAdReady() async {
    // 测试模式：始终返回就绪
    if (Constants.TEST_MODE) {
      return true;
    }
    return false;
  }

  /// 展示激励视频广告
  ///
  /// [adType] 广告类型（hint/continue/sign_in_double/spin/task）
  /// [onReward] 广告播放完成后的奖励回调（用户完整观看后调用）
  ///
  /// 流程：
  /// 1. 检查广告是否就绪（测试模式直接跳过）
  /// 2. 展示广告（模拟模式弹出加载Dialog，2秒后自动关闭）
  /// 3. 上报后端并等待奖励事务成功
  /// 4. 刷新用户余额后调用 onReward 更新业务 UI
  ///
  /// 异常处理：
  /// - 如果正在播放广告，忽略本次请求
  /// - 如果SDK加载失败，显示错误提示
  Future<void> showRewardedAd(
    String adType,
    VoidCallback onReward, {
    BuildContext? context,
  }) async {
    // 防重复：如果正在播放广告，忽略本次请求
    if (_isShowingAd) {
      return;
    }

    _isShowingAd = true;

    try {
      // 测试模式：直接跳过广告播放，模拟成功
      if (Constants.TEST_MODE) {
        // 如果提供了context，显示一个模拟播放的Dialog
        if (context != null) {
          await _showSimulatedAdDialog(context, adType);
        } else {
          // 无context时直接延迟模拟
          await Future.delayed(
            const Duration(milliseconds: Constants.AD_SIMULATE_DURATION_MS),
          );
        }
        await _reportAdReward(adType);
        await AuthService().refreshUser();
        onReward();
        _todayAdCount++;
        return;
      }

      final adReady = await isAdReady();
      if (!adReady) {
        if (context != null && context.mounted) {
          _showErrorSnackBar(context, '广告服务尚未配置');
        }
        return;
      }
    } catch (e) {
      // 广告播放失败，释放锁并提示用户
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, '广告播放失败: $e');
      }
    } finally {
      _isShowingAd = false;
    }
  }

  /// 模拟广告播放Dialog（测试模式使用）
  /// 显示一个模拟的激励视频播放界面，2秒后自动关闭
  Future<void> _showSimulatedAdDialog(BuildContext context, String adType) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭（模拟真实广告不可跳过）
      builder: (context) {
        // 自动关闭计时器
        Future.delayed(
          const Duration(milliseconds: Constants.AD_SIMULATE_DURATION_MS),
          () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        );

        return Dialog(
          backgroundColor: Colors.black87,
          insetPadding: const EdgeInsets.all(0),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 广告类型图标
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: 24),
                // 模拟广告标题
                const Text(
                  '正在播放激励视频...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // 广告类型说明
                Text(
                  '类型: ${_getAdTypeDisplayName(adType)}',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                // 模拟倒计时（2秒）
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                // 测试模式提示
                Text(
                  '【测试模式】广告已跳过',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 上报广告观看完成记录到后端
  /// 后端进行防刷校验：每日上限、频率、设备指纹等
  ///
  /// [adType] 广告类型
  /// 后端失败时向上抛错，调用方不得执行奖励回调。
  Future<void> _reportAdReward(String adType) async {
    final transactionId =
        'sim_${DateTime.now().millisecondsSinceEpoch}_${_randomString(8)}';
    await ApiService().adReward(adType, transactionId: transactionId);
  }

  /// 显示错误提示（SnackBar）
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Constants.PRIMARY_RED,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 获取广告类型中文显示名
  String _getAdTypeDisplayName(String adType) {
    switch (adType) {
      case 'hint':
        return '获取提示';
      case 'continue':
        return '续命继续';
      case 'sign_in_double':
        return '签到翻倍';
      case 'spin':
        return '转盘抽奖';
      case 'task':
        return '任务奖励';
      default:
        return '其他奖励';
    }
  }

  /// 生成随机字符串（用于模拟transactionId）
  String _randomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(DateTime.now().millisecond + i) % chars.length];
    }
    return result;
  }

  /// 获取今日广告观看次数（本地计数）
  int get todayAdCount => _todayAdCount;

  /// 是否达到每日广告上限（本地预判断，最终以上后端校验为准）
  bool get isDailyLimitReached => _todayAdCount >= Constants.DAILY_AD_LIMIT;

  /// 重置每日广告计数（每天0点调用）
  void resetDailyCount() {
    _todayAdCount = 0;
  }
}

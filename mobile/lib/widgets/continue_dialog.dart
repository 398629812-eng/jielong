import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 续命弹窗组件
/// 游戏失败（超时或答错）时弹出，提供观看广告继续游戏的机会
/// 每局限1次，点击"观看广告续命"播放广告后恢复计时继续游戏
class ContinueDialog extends StatelessWidget {
  /// 当前已进行的轮数
  final int rounds;

  /// 观看广告续命回调
  final VoidCallback? onWatchAdContinue;

  /// 放弃游戏回调（跳转到结算页）
  final VoidCallback? onGiveUp;

  const ContinueDialog({
    super.key,
    required this.rounds,
    this.onWatchAdContinue,
    this.onGiveUp,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 心形图标（红色大图标）
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Constants.PRIMARY_RED.withOpacity(0.1),
                borderRadius: BorderRadius.circular(36),
              ),
              child: const Icon(
                Icons.favorite,
                color: Constants.PRIMARY_RED,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            const Text(
              '时间到！',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Constants.PRIMARY_RED,
              ),
            ),
            const SizedBox(height: 8),
            // 当前轮数提示
            Text(
              '您已坚持了 $rounds 轮',
              style: const TextStyle(
                fontSize: 16,
                color: Constants.TEXT_PRIMARY,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              '是否观看广告续命继续？',
              style: TextStyle(
                fontSize: 14,
                color: Constants.TEXT_SECONDARY,
              ),
            ),
            const SizedBox(height: 8),
            // 每局限1次提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Constants.GOLD.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '每局限 1 次',
                style: TextStyle(
                  fontSize: 12,
                  color: Constants.GOLD_DARK,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 按钮：观看广告续命
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onWatchAdContinue?.call();
                },
                icon: const Icon(Icons.play_circle_outline, size: 22),
                label: const Text(
                  '观看广告续命',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.PRIMARY_RED,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 按钮：放弃游戏
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onGiveUp?.call();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Constants.TEXT_SECONDARY,
                  side: const BorderSide(color: Constants.DIVIDER),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '结束游戏',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示续命弹窗的静态方法
  static Future<void> show(
    BuildContext context, {
    required int rounds,
    VoidCallback? onWatchAdContinue,
    VoidCallback? onGiveUp,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 禁止点击外部关闭（必须做出选择）
      builder: (context) => ContinueDialog(
        rounds: rounds,
        onWatchAdContinue: onWatchAdContinue,
        onGiveUp: onGiveUp,
      ),
    );
  }
}

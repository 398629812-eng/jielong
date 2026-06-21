import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 提示弹窗组件
/// 当玩家点击提示按钮时弹出，显示消耗提示或观看广告获取提示的选项
/// 如果玩家有剩余提示次数，直接显示提示内容；如果没有，引导观看广告
class HintDialog extends StatelessWidget {
  /// 是否有剩余提示次数
  final bool hasHints;

  /// 剩余提示次数
  final int hintsCount;

  /// 提示内容（要显示的成语）
  final String? hintIdiom;

  /// 消耗提示回调（玩家选择消耗提示次数）
  final VoidCallback? onUseHint;

  /// 观看广告回调（玩家选择看广告获取提示）
  final VoidCallback? onWatchAd;

  /// 关闭弹窗回调
  final VoidCallback? onClose;

  const HintDialog({
    super.key,
    required this.hasHints,
    required this.hintsCount,
    this.hintIdiom,
    this.onUseHint,
    this.onWatchAd,
    this.onClose,
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
            // 灯泡图标
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                Icons.lightbulb,
                color: Constants.GOLD_DARK,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            // 标题
            Text(
              hasHints ? '使用提示' : '提示次数不足',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Constants.TEXT_PRIMARY,
              ),
            ),
            const SizedBox(height: 12),
            // 内容区域
            if (hasHints && hintIdiom != null) ...[
              // 有提示次数：显示提示内容
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Constants.SYSTEM_GREEN_LIGHT,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Constants.SYSTEM_GREEN.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      '提示成语：',
                      style: TextStyle(
                        fontSize: 14,
                        color: Constants.TEXT_SECONDARY,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hintIdiom!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Constants.SYSTEM_GREEN,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '消耗 1 次提示（剩余 $hintsCount 次）',
                style: const TextStyle(
                  fontSize: 14,
                  color: Constants.TEXT_SECONDARY,
                ),
              ),
            ] else ...[
              // 无提示次数：显示广告选项
              Text(
                hasHints ? '您还有 $hintsCount 次提示机会' : '您的提示次数已用完，可以通过观看广告获取提示！',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Constants.TEXT_SECONDARY,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 24),
            // 按钮行
            Row(
              children: [
                // 关闭按钮
                Expanded(
                  child: OutlinedButton(
                    onPressed: onClose ?? () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Constants.TEXT_SECONDARY,
                      side: const BorderSide(color: Constants.DIVIDER),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('关闭'),
                  ),
                ),
                const SizedBox(width: 12),
                // 操作按钮
                if (hasHints) ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onUseHint?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Constants.PRIMARY_RED,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('消耗提示 ($hintsCount)'),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onWatchAd?.call();
                      },
                      icon: const Icon(Icons.play_circle_outline, size: 20),
                      label: const Text('看广告获取'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Constants.PRIMARY_RED,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 显示弹窗的静态方法（方便调用）
  static Future<void> show(
    BuildContext context, {
    required bool hasHints,
    required int hintsCount,
    String? hintIdiom,
    VoidCallback? onUseHint,
    VoidCallback? onWatchAd,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => HintDialog(
        hasHints: hasHints,
        hintsCount: hintsCount,
        hintIdiom: hintIdiom,
        onUseHint: onUseHint,
        onWatchAd: onWatchAd,
      ),
    );
  }
}

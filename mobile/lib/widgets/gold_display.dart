import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 顶部金币展示组件
/// 金色大字体 + 金币图标，用于AppBar和各页面顶部显示金币余额
/// 点击可跳转到金币明细或提现页面
class GoldDisplay extends StatelessWidget {
  /// 金币数量
  final int gold;

  /// 是否显示可提现金额（显示 "≈ X元"）
  final bool showRmb;

  /// 点击回调
  final VoidCallback? onTap;

  /// 图标大小
  final double iconSize;

  /// 字体大小
  final double fontSize;

  const GoldDisplay({
    super.key,
    required this.gold,
    this.showRmb = false,
    this.onTap,
    this.iconSize = 24,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    // 计算可提现金额
    final rmb = gold / Constants.GOLD_TO_RMB;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1), // 浅金色背景
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Constants.GOLD.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 金币图标
            Icon(
              Icons.monetization_on,
              color: Constants.GOLD,
              size: iconSize,
            ),
            const SizedBox(width: 4),
            // 金币数量（金色大字体）
            Text(
              gold.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Constants.GOLD_DARK,
                fontFamily: 'Roboto',
              ),
            ),
            // 可提现金额（可选）
            if (showRmb) ...[
              const SizedBox(width: 4),
              Text(
                '≈ ${rmb.toStringAsFixed(2)}元',
                style: const TextStyle(
                  fontSize: 12,
                  color: Constants.TEXT_SECONDARY,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

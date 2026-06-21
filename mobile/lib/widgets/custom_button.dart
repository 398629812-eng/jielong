import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 统一样式按钮组件
/// 提供两种主要样式：红色主按钮（渐变填充）和金色次按钮（边框描边）
/// 支持自定义文字、图标、尺寸和点击事件
class CustomButton extends StatelessWidget {
  /// 按钮文字
  final String text;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 按钮类型：primary=红色主按钮，secondary=金色次按钮
  final ButtonType type;

  /// 前置图标（如 💡、❤️）
  final IconData? icon;

  /// 按钮宽度（默认全宽）
  final double? width;

  /// 按钮高度（默认56）
  final double height;

  /// 圆角大小（默认16）
  final double borderRadius;

  /// 是否禁用状态
  final bool disabled;

  /// 字体大小（默认18）
  final double fontSize;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.width,
    this.height = 56,
    this.borderRadius = Constants.BORDER_RADIUS,
    this.disabled = false,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = type == ButtonType.primary;

    // 禁用状态样式覆盖
    final effectiveDisabled = disabled || onPressed == null;

    // 主按钮：红色渐变填充
    // 次按钮：金色边框描边 + 白色背景
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: effectiveDisabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          foregroundColor: isPrimary
              ? Colors.white
              : (effectiveDisabled ? Constants.TEXT_HINT : Constants.GOLD_DARK),
          backgroundColor: isPrimary
              ? (effectiveDisabled ? Colors.grey[300] : Constants.PRIMARY_RED)
              : Colors.white,
          elevation: isPrimary ? 2 : 0,
          shadowColor: isPrimary
              ? Constants.PRIMARY_RED.withOpacity(0.4)
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
            side: isPrimary
                ? BorderSide.none
                : BorderSide(
                    color: effectiveDisabled
                        ? Constants.TEXT_HINT
                        : Constants.GOLD_DARK,
                    width: 2,
                  ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isPrimary
                    ? Colors.white
                    : (effectiveDisabled
                        ? Constants.TEXT_HINT
                        : Constants.GOLD_DARK),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 按钮类型枚举
enum ButtonType {
  /// 红色主按钮（填充渐变）
  primary,

  /// 金色次按钮（边框描边）
  secondary,
}

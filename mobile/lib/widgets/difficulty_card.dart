import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 难度选择卡片组件
/// 展示三种难度选择：简单（绿色）、普通（橙色）、困难（红色）
/// 横向排列，点击选中时显示勾选标记和边框高亮
class DifficultyCard extends StatelessWidget {
  /// 难度代码
  final String difficulty;

  /// 难度名称（如"简单"）
  final String name;

  /// 难度描述（如"60秒/轮 · 轻松接龙"）
  final String description;

  /// 是否被选中
  final bool isSelected;

  /// 点击回调
  final VoidCallback onTap;

  const DifficultyCard({
    super.key,
    required this.difficulty,
    required this.name,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 根据难度确定颜色
    final Color mainColor = _getDifficultyColor();
    final Color lightColor = _getDifficultyLightColor();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? lightColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? mainColor : Constants.DIVIDER,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? mainColor.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 难度图标
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: mainColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getDifficultyIcon(),
                color: mainColor,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            // 难度名称
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? mainColor : Constants.TEXT_PRIMARY,
              ),
            ),
            const SizedBox(height: 4),
            // 难度描述
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Constants.TEXT_SECONDARY,
                height: 1.3,
              ),
            ),
            // 选中标记
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: mainColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 获取难度主色
  Color _getDifficultyColor() {
    switch (difficulty) {
      case 'easy':
        return Constants.SYSTEM_GREEN;
      case 'hard':
        return Constants.PRIMARY_RED;
      case 'normal':
      default:
        return Constants.ORANGE;
    }
  }

  /// 获取难度浅色（选中背景）
  Color _getDifficultyLightColor() {
    switch (difficulty) {
      case 'easy':
        return const Color(0xFFE8F5E9);
      case 'hard':
        return const Color(0xFFFFEBEE);
      case 'normal':
      default:
        return const Color(0xFFFFF3E0);
    }
  }

  /// 获取难度图标
  IconData _getDifficultyIcon() {
    switch (difficulty) {
      case 'easy':
        return Icons.sentiment_satisfied;
      case 'hard':
        return Icons.sentiment_very_dissatisfied;
      case 'normal':
      default:
        return Icons.sentiment_neutral;
    }
  }
}

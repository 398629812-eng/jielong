import 'package:flutter/material.dart';
import '../models/idiom.dart';
import '../utils/constants.dart';

/// 成语聊天气泡组件
/// 模拟聊天界面，系统成语显示在左侧绿色气泡，玩家成语显示在右侧红色气泡
/// 每条气泡展示成语文本、拼音和释义（系统气泡显示释义，玩家气泡不显示）
class IdiomBubble extends StatelessWidget {
  /// 成语数据
  final Idiom idiom;

  /// 是否为系统出题（true=左侧绿色气泡，false=右侧红色气泡）
  final bool isSystem;

  /// 轮数序号（显示在气泡上方，如"第1轮"）
  final int? roundNumber;

  const IdiomBubble({
    super.key,
    required this.idiom,
    required this.isSystem,
    this.roundNumber,
  });

  @override
  Widget build(BuildContext context) {
    // 根据系统/玩家选择颜色和布局方向
    final bgColor =
        isSystem ? Constants.SYSTEM_GREEN_LIGHT : Constants.PLAYER_RED_LIGHT;
    final borderColor =
        isSystem ? Constants.SYSTEM_GREEN : Constants.PLAYER_RED;
    const textColor = Constants.TEXT_PRIMARY;
    const pinyinColor = Constants.TEXT_SECONDARY;
    final alignment =
        isSystem ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final margin = isSystem
        ? const EdgeInsets.only(right: 60, left: 12, top: 4, bottom: 4)
        : const EdgeInsets.only(left: 60, right: 12, top: 4, bottom: 4);

    return Column(
      crossAxisAlignment: alignment,
      children: [
        // 轮数序号标签（只在系统气泡上方显示）
        if (roundNumber != null && isSystem)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Text(
              '第 $roundNumber 轮',
              style: const TextStyle(
                fontSize: 12,
                color: Constants.TEXT_SECONDARY,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        Container(
          margin: margin,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(Constants.BORDER_RADIUS),
            border: Border.all(
              color: borderColor.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 成语文本（大号加粗）
              Text(
                idiom.idiom,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              // 拼音（小字灰色）
              Text(
                idiom.pinyin,
                style: const TextStyle(
                  fontSize: 14,
                  color: pinyinColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
              // 释义（仅系统气泡显示，帮助玩家学习）
              if (isSystem) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.only(top: 4),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Constants.DIVIDER,
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Text(
                    idiom.meaning,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Constants.TEXT_SECONDARY,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

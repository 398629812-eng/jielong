import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// 倒计时进度条组件
/// 支持环形或条形显示，随时间减少进度，进入红色警告区时变色
/// 困难模式时显示红色，简单/普通模式显示绿色/橙色
class CountdownTimer extends StatefulWidget {
  /// 总秒数（根据难度设定：简单60、普通30、困难15）
  final int totalSeconds;

  /// 当前剩余秒数（实时更新）
  final int remainingSeconds;

  /// 显示模式：true=环形，false=条形
  final bool circular;

  /// 直径（环形模式下）
  final double diameter;

  /// 条形高度（条形模式下）
  final double barHeight;

  const CountdownTimer({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
    this.circular = true,
    this.diameter = 72,
    this.barHeight = 8,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void didUpdateWidget(CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remainingSeconds != widget.remainingSeconds) {
      // 剩余时间变化时触发动画
      _controller.forward(from: 0).then((_) => _controller.reset());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 计算进度比例
    final progress = widget.totalSeconds > 0
        ? widget.remainingSeconds / widget.totalSeconds
        : 0.0;

    // 确定颜色：根据剩余时间和难度
    final Color color = _getColor(progress);

    // 确定文字颜色
    final Color textColor =
        progress < 0.2 ? Constants.WARNING_RED : Constants.TEXT_PRIMARY;

    if (widget.circular) {
      return _buildCircular(progress, color, textColor);
    } else {
      return _buildBar(progress, color, textColor);
    }
  }

  /// 环形进度条
  Widget _buildCircular(double progress, Color color, Color textColor) {
    final compact = widget.diameter <= 56;
    return SizedBox(
      width: widget.diameter,
      height: widget.diameter,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 背景圆环
          const CircularProgressIndicator(
            value: 1.0,
            strokeWidth: 6,
            backgroundColor: Constants.DIVIDER,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.transparent),
          ),
          // 进度圆环
          CircularProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            strokeWidth: 6,
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          // 倒计时文字
          if (compact)
            Text(
              '${widget.remainingSeconds}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
                fontFamily: 'Roboto',
              ),
            )
          else
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${widget.remainingSeconds}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'Roboto',
                  ),
                ),
                const Text(
                  '秒',
                  style: TextStyle(
                    fontSize: 12,
                    color: Constants.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// 条形进度条
  Widget _buildBar(double progress, Color color, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 进度条
        ClipRRect(
          borderRadius: BorderRadius.circular(widget.barHeight / 2),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: widget.barHeight,
            backgroundColor: Constants.DIVIDER,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 4),
        // 剩余时间文字
        Text(
          '剩余 ${widget.remainingSeconds} 秒',
          style: TextStyle(
            fontSize: 14,
            color: textColor,
            fontWeight: progress < 0.2 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// 根据进度获取颜色
  /// 进度 > 50%: 绿色（安全）
  /// 进度 20-50%: 橙色（警告）
  /// 进度 < 20%: 红色（危险）
  Color _getColor(double progress) {
    if (progress <= 0.2) {
      return Constants.WARNING_RED; // 红色警告区
    } else if (progress <= 0.5) {
      return Constants.ORANGE; // 橙色警告区
    } else {
      // 根据总时长判断安全色（困难模式红色主题，其他绿色）
      if (widget.totalSeconds <= 15) {
        return Constants.ORANGE; // 困难模式始终偏紧张
      }
      return Constants.SYSTEM_GREEN; // 简单/普通模式绿色
    }
  }
}

import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../utils/constants.dart';
import 'home_screen.dart';
import 'game_screen.dart';

/// 游戏结算页面（Game Over Screen）
/// 展示游戏结果：
/// 1. 居中：总轮数（超大数字72px）、纪录标签（🏆 新纪录！金色大字）
/// 2. 获得金币：+基础金币（每轮10）+ 纪录奖励（2000）
/// 3. 成语链条：可展开的ListView（前5条展开，更多可点击展开）
/// 4. 按钮行："再玩一次"（红色）/ "返回首页"（金色边框）
/// 5. 新纪录时：animated_text_kit 金色闪烁文字 "恭喜刷新纪录！"
class GameOverScreen extends StatefulWidget {
  /// 游戏状态数据
  final GameState gameState;

  const GameOverScreen({
    super.key,
    required this.gameState,
  });

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  /// 成语链条是否展开全部
  bool _showAllIdioms = false;

  @override
  Widget build(BuildContext context) {
    final rounds = widget.gameState.rounds;
    final baseGold = widget.gameState.baseGoldReward;
    final recordGold = widget.gameState.recordGoldReward;
    final totalGold = widget.gameState.totalGoldReward;
    final isNewRecord = widget.gameState.isNewRecord;
    final chain = widget.gameState.idiomChain;

    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              // 新纪录动画（如果是新纪录）
              if (isNewRecord) ...[
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Constants.GOLD_DARK,
                      Constants.ORANGE,
                      Constants.GOLD,
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    '恭喜刷新纪录！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // 总轮数（超大数字）
              Text(
                '$rounds',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.bold,
                  color: Constants.PRIMARY_RED,
                  fontFamily: 'Roboto',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '本轮接龙轮数',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              // 新纪录标签
              if (isNewRecord)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Constants.GOLD.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Constants.GOLD.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.emoji_events, color: Constants.GOLD, size: 20),
                      SizedBox(width: 6),
                      Text(
                        '🏆 新纪录！',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Constants.GOLD_DARK,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // 金币奖励卡片
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.monetization_on,
                            color: Constants.GOLD, size: 28),
                        SizedBox(width: 8),
                        Text(
                          '获得金币',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Constants.TEXT_PRIMARY,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // 基础奖励
                    _buildGoldRow('基础奖励（$rounds轮 × 10）', '+$baseGold'),
                    if (isNewRecord) ...[
                      const SizedBox(height: 8),
                      _buildGoldRow('纪录奖励', '+$recordGold', isHighlight: true),
                    ],
                    const Divider(height: 24),
                    // 总计
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '合计',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Constants.TEXT_PRIMARY,
                          ),
                        ),
                        Text(
                          '+$totalGold',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Constants.GOLD_DARK,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 成语链条
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 标题栏
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '成语链条',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Constants.TEXT_PRIMARY,
                            ),
                          ),
                          Text(
                            '共 ${chain.length} 条',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // 链条列表（前5条 + 展开按钮）
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _showAllIdioms
                          ? chain.length
                          : (chain.length > 5 ? 5 : chain.length),
                      itemBuilder: (context, index) {
                        final idiom = chain[index];
                        final isSystem = index % 2 == 0;
                        return ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isSystem
                                  ? Constants.SYSTEM_GREEN.withOpacity(0.1)
                                  : Constants.PLAYER_RED.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSystem
                                      ? Constants.SYSTEM_GREEN
                                      : Constants.PLAYER_RED,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            idiom.idiom,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${idiom.pinyin} · ${isSystem ? '系统' : '玩家'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          trailing: index < chain.length - 1
                              ? const Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: Constants.TEXT_HINT,
                                )
                              : null,
                        );
                      },
                    ),
                    // 展开/收起按钮
                    if (chain.length > 5)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showAllIdioms = !_showAllIdioms;
                          });
                        },
                        child: Text(
                          _showAllIdioms ? '收起 ▲' : '展开更多 ▼',
                          style: TextStyle(
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // 按钮行
              Row(
                children: [
                  // 再玩一次
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _playAgain,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Constants.PRIMARY_RED,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '再玩一次',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 返回首页
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _goHome,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Constants.GOLD_DARK,
                        side: const BorderSide(
                          color: Constants.GOLD_DARK,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '返回首页',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建金币明细行
  Widget _buildGoldRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isHighlight ? Constants.GOLD_DARK : Colors.grey[600],
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? Constants.GOLD_DARK : Constants.TEXT_PRIMARY,
          ),
        ),
      ],
    );
  }

  /// 再玩一次
  void _playAgain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          difficulty: widget.gameState.difficulty,
          totalSeconds: widget.gameState.totalSeconds,
        ),
      ),
    );
  }

  /// 返回首页
  void _goHome() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../models/game_state.dart';
import '../services/auth_service.dart';
import '../services/idiom_service.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/idiom_bubble.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/hint_dialog.dart';
import '../widgets/continue_dialog.dart';
import 'game_over_screen.dart';

/// 游戏界面（Game Screen）
/// 核心游戏页面，包含：
/// 1. 顶部：当前难度标签 + 倒计时进度条（环形，困难时变红色）
/// 2. 中部：成语链条（ListView.builder）系统/玩家气泡交替排列
/// 3. 底部：输入框 + 提示按钮 + 续命按钮（失败时显示）
/// 4. 实时验证：输入时本地检查，不匹配时输入框红色边框
/// 5. 超时自动结束：倒计时到0显示结算页
class GameScreen extends StatefulWidget {
  /// 游戏难度
  final String difficulty;

  /// 每轮倒计时秒数
  final int totalSeconds;

  const GameScreen({
    super.key,
    required this.difficulty,
    required this.totalSeconds,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  /// 游戏状态
  late GameState _gameState;

  /// 输入框控制器
  final TextEditingController _inputController = TextEditingController();

  /// 输入框焦点
  final FocusNode _inputFocusNode = FocusNode();

  /// 滚动控制器（自动滚动到最新成语）
  final ScrollController _scrollController = ScrollController();

  /// 倒计时计时器
  Timer? _timer;

  /// 是否正在验证（防止重复提交）
  bool _isValidating = false;

  /// 输入验证错误提示
  String? _inputError;

  /// 是否显示续命按钮
  bool _showContinue = false;

  /// 是否已结束游戏（防止重复跳转）
  bool _gameEnded = false;

  /// 是否正在等待服务端结算（防止重复提交）
  bool _isEnding = false;

  /// 是否正在初始化游戏（从后端获取开局）
  bool _isInitializing = true;

  /// 初始化错误信息（非空时显示重试界面）
  String? _initError;

  @override
  void initState() {
    super.initState();
    // 从设置读取同音不同调开关
    _initGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _inputController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化游戏（从后端获取 game_id 和起始成语）
  Future<void> _initGame() async {
    setState(() {
      _isInitializing = true;
      _initError = null;
    });

    try {
      // 从设置读取同音不同调开关（这里简化为默认 false）
      const allowDifferentTone = false;

      final response = await ApiService().startGame(widget.difficulty);
      final gameId = response['game_id'] as String?;
      final startIdiomData = response['start_idiom'];

      if (gameId == null || startIdiomData == null) {
        throw Exception('后端返回数据不完整');
      }

      final startIdiomText = startIdiomData['idiom'] as String?;
      if (startIdiomText == null) {
        throw Exception('后端返回的起始成语不完整');
      }

      final startIdiom = IdiomService().getIdiomDetail(startIdiomText);
      if (startIdiom == null) {
        throw Exception('本地成语库缺少后端返回的起始成语：$startIdiomText');
      }

      if (!mounted) return;

      _gameState = GameState(
        gameId: gameId,
        difficulty: widget.difficulty,
        totalSeconds: widget.totalSeconds,
        remainingSeconds: widget.totalSeconds,
        allowDifferentTone: allowDifferentTone,
      );
      _gameState.idiomChain.add(startIdiom);
      _gameState.usedIdioms.add(startIdiom.idiom);

      // 启动倒计时
      _startTimer();

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isInitializing = false;
        _initError = e.toString();
      });
    }
  }

  /// 启动倒计时器
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_gameState.remainingSeconds > 0) {
          _gameState.remainingSeconds--;
        } else {
          // 时间到，游戏结束
          _timer?.cancel();
          _onTimeUp();
        }
      });
    });
  }

  /// 超时处理（显示续命弹窗或结算页）
  void _onTimeUp() {
    if (_gameEnded) return;

    // 如果还可以续命且未续命过，显示续命弹窗
    if (!_gameState.hasContinued) {
      setState(() {
        _showContinue = true;
      });
      ContinueDialog.show(
        context,
        rounds: _gameState.rounds,
        onWatchAdContinue: _continueGame,
        onGiveUp: _endGame,
      );
    } else {
      // 已续命过，直接结束
      _endGame();
    }
  }

  /// 续命（看广告后重置时间）
  void _continueGame() {
    AdService().showRewardedAd(
      'continue',
      () {
        if (!mounted) return;
        setState(() {
          _gameState.useContinue();
          _showContinue = false;
          // 恢复输入框
          _inputFocusNode.requestFocus();
        });
        _startTimer();
      },
      context: context,
    );
  }

  /// 结束游戏。金币和纪录只采用服务端结算结果。
  Future<void> _endGame({String reason = 'timeout'}) async {
    if (_gameEnded || _isEnding) return;
    _isEnding = true;
    _timer?.cancel();
    _gameState.endReason = reason;

    try {
      final result = await ApiService().endGame(
        _gameState.gameId,
        _gameState.rounds,
        _gameState.chainStrings,
        reason,
      );

      _gameState.rounds = result['rounds'] as int? ?? _gameState.rounds;
      _gameState.earnedGold = result['gold'] as int? ?? 0;
      _gameState.isNewRecord = result['is_record'] as bool? ?? false;
      await AuthService().refreshUser();

      if (!mounted) return;
      _gameEnded = true;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => GameOverScreen(gameState: _gameState),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _isEnding = false;
      await _showSettlementFailure(e.toString(), reason);
    }
  }

  /// 提交玩家输入的成语（由后端权威验证）
  Future<void> _submitIdiom() async {
    if (_isValidating || _isEnding || _gameEnded) return;

    final input = _inputController.text.trim();

    // 基础验证（格式）
    final formatError = Validators.validateIdiomSubmit(input);
    if (formatError != null) {
      setState(() {
        _inputError = formatError;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _inputError = null;
    });

    try {
      // 获取当前最后一个成语（需要接的成语）
      final currentIdiom = _gameState.currentIdiom;
      if (currentIdiom == null) {
        if (!mounted) return;
        setState(() {
          _inputError = '游戏状态异常';
        });
        return;
      }

      // 调用后端验证接口
      final result = await ApiService().validateGame(
        _gameState.gameId,
        input,
        currentIdiom.idiom,
      );

      if (!mounted) return;

      final valid = result['valid'] as bool? ?? false;
      final message = result['message'] as String?;

      if (!valid) {
        setState(() {
          _inputError = message ?? '接龙失败';
        });
        return;
      }

      // 验证通过：从本地库获取玩家成语完整对象
      final playerIdiom = IdiomService().getIdiomDetail(input);
      if (playerIdiom == null) {
        setState(() {
          _inputError = '本地成语库缺少该成语，无法继续：$input';
        });
        return;
      }

      _inputController.clear();
      setState(() {
        _gameState.addIdiom(playerIdiom);
        _inputError = null;

        // 使用后端返回的轮数
        final rounds = result['rounds'] as int?;
        if (rounds != null) {
          _gameState.rounds = rounds;
        }
      });
      _scrollToBottom();

      final nextIdiomData = result['next_idiom'];
      if (nextIdiomData == null) {
        await _endGame(reason: 'ai_no_words');
        return;
      }

      // 系统有词可接：从本地库获取完整对象
      final nextIdiomText = nextIdiomData['idiom'] as String?;
      if (nextIdiomText == null) {
        setState(() {
          _inputError = '后端返回的系统成语数据不完整';
        });
        return;
      }

      final nextIdiom = IdiomService().getIdiomDetail(nextIdiomText);
      if (nextIdiom == null) {
        setState(() {
          _inputError = '本地成语库缺少系统成语：$nextIdiomText';
        });
        return;
      }

      setState(() {
        _gameState.idiomChain.add(nextIdiom);
        _gameState.usedIdioms.add(nextIdiom.idiom);
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inputError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidating = false;
        });
      }
    }
  }

  Future<void> _showSettlementFailure(String message, String reason) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('结算失败'),
        content: Text('未发放任何金币。请检查网络后重试。\n$message'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.pop(context);
            },
            child: const Text('返回首页'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _endGame(reason: reason);
            },
            child: const Text('重试结算'),
          ),
        ],
      ),
    );
  }

  /// 使用提示
  void _useHint() {
    final authService = AuthService();
    final hasHints = authService.hints > 0;

    final currentIdiom = _gameState.currentIdiom;
    if (currentIdiom == null) return;

    HintDialog.show(
      context,
      hasHints: hasHints,
      hintsCount: authService.hints,
      onUseHint: () {
        _consumeHint(currentIdiom.idiom);
      },
      onWatchAd: () {
        AdService().showRewardedAd(
          'hint',
          () {
            setState(() {});
          },
          context: context,
        );
      },
    );
  }

  Future<void> _consumeHint(String currentIdiom) async {
    try {
      final result = await ApiService().getHint(
        _gameState.gameId,
        currentIdiom,
      );
      await AuthService().refreshUser();
      if (!mounted) return;
      setState(() {});
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('提示成语'),
          content: Text(
            result['hint'] as String? ?? '暂无可用提示',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('知道了'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('获取提示失败: $e')),
      );
    }
  }

  /// 滚动到链条底部
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return _buildLoadingScreen();
    }
    if (_initError != null) {
      return _buildErrorScreen();
    }
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () {
            // 确认退出
            _showQuitConfirmDialog();
          },
          icon: const Icon(Icons.arrow_back, color: Constants.TEXT_PRIMARY),
        ),
        title: Row(
          children: [
            // 难度标签
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getDifficultyColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _getDifficultyColor().withOpacity(0.3),
                ),
              ),
              child: Text(
                _gameState.difficultyDisplayName,
                style: TextStyle(
                  fontSize: 14,
                  color: _getDifficultyColor(),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 轮数
            Text(
              '第 ${_gameState.rounds} 轮',
              style: const TextStyle(
                fontSize: 16,
                color: Constants.TEXT_SECONDARY,
              ),
            ),
          ],
        ),
        actions: [
          // 倒计时（环形）
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: CountdownTimer(
                totalSeconds: widget.totalSeconds,
                remainingSeconds: _gameState.remainingSeconds,
                circular: true,
                diameter: 48,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 提示区域（显示需要接的尾字）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '请接：',
                  style: TextStyle(
                    fontSize: 14,
                    color: Constants.TEXT_SECONDARY,
                  ),
                ),
                Text(
                  '"${_gameState.currentIdiom?.lastChar ?? ''}"',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getDifficultyColor(),
                  ),
                ),
                Text(
                  '（${_gameState.targetTailPinyin}）',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Constants.TEXT_SECONDARY,
                  ),
                ),
              ],
            ),
          ),
          // 成语链条（可滚动区域）
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _gameState.idiomChain.length,
              itemBuilder: (context, index) {
                final idiom = _gameState.idiomChain[index];
                final isSystem = index % 2 == 0; // 偶数=系统，奇数=玩家
                final roundNumber = isSystem ? (index ~/ 2) + 1 : null;
                return IdiomBubble(
                  idiom: idiom,
                  isSystem: isSystem,
                  roundNumber: roundNumber,
                );
              },
            ),
          ),
          // 输入区域
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 输入框和确认按钮
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        textAlign: TextAlign.center,
                        maxLength: 4,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: '请输入四字成语...',
                          hintStyle: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                            letterSpacing: 2,
                          ),
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _inputError != null
                                  ? Constants.PRIMARY_RED
                                  : Constants.DIVIDER,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _inputError != null
                                  ? Constants.PRIMARY_RED
                                  : Constants.DIVIDER,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _inputError != null
                                  ? Constants.PRIMARY_RED
                                  : Constants.PRIMARY_RED,
                              width: 2,
                            ),
                          ),
                          errorText: _inputError,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onSubmitted: (_) => _submitIdiom(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 确认按钮
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isValidating ? null : _submitIdiom,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Constants.PRIMARY_RED,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        child: _isValidating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 底部按钮行：提示 + 续命
                Row(
                  children: [
                    // 提示按钮
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _useHint,
                        icon: const Icon(
                          Icons.lightbulb,
                          color: Constants.GOLD_DARK,
                          size: 18,
                        ),
                        label: Text(
                          '提示 (${AuthService().hints})',
                          style: const TextStyle(
                            color: Constants.GOLD_DARK,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Constants.GOLD_DARK),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    // 续命按钮（仅在失败时显示，这里简化处理）
                    if (_showContinue) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _continueGame,
                          icon: const Icon(Icons.favorite, size: 18),
                          label: const Text('续命（看广告）'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Constants.PRIMARY_RED,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 初始化 loading 界面
  Widget _buildLoadingScreen() {
    return const Scaffold(
      backgroundColor: Constants.BACKGROUND,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Constants.PRIMARY_RED),
            SizedBox(height: 16),
            Text(
              '正在准备游戏...',
              style: TextStyle(color: Constants.TEXT_SECONDARY, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// 初始化失败界面（带重试按钮）
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Constants.TEXT_PRIMARY),
        ),
        title: const Text(
          '游戏初始化失败',
          style: TextStyle(color: Constants.TEXT_PRIMARY, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                color: Constants.PRIMARY_RED,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                _initError!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Constants.TEXT_PRIMARY,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _initGame,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.PRIMARY_RED,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 获取难度颜色
  Color _getDifficultyColor() {
    switch (widget.difficulty) {
      case 'easy':
        return Constants.SYSTEM_GREEN;
      case 'hard':
        return Constants.PRIMARY_RED;
      case 'normal':
      default:
        return Constants.ORANGE;
    }
  }

  /// 显示退出确认弹窗
  void _showQuitConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('退出游戏将不会保存当前进度，是否确认？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('继续游戏'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.PRIMARY_RED,
              foregroundColor: Colors.white,
            ),
            child: const Text('退出'),
          ),
        ],
      ),
    );
  }
}

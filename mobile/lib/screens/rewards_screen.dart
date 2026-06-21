import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../utils/constants.dart';

/// 奖励页面（Rewards Screen）
/// 包含三个Tab：
/// 1. 签到Tab：日历格子（7天），已签到打勾✅，今日可签到高亮，签到后弹窗"观看广告翻倍"
/// 2. 转盘Tab：圆形8等分转盘，区域：50金币、100金币、200金币、500金币、1000金币、谢谢、再来一次、大奖2000
/// 3. 任务Tab：ListTile列表："接对10个成语"、"观看3个广告"、"达到5轮"、"刷新纪录"，进度条+领取按钮
class RewardsScreen extends StatefulWidget {
  /// 初始选中Tab（0=签到，1=转盘，2=任务）
  final int initialTab;

  const RewardsScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // === 签到状态 ===
  /// 今日是否已签到
  bool _todaySigned = false;

  /// 连续签到天数
  int _consecutiveDays = 0;

  /// 签到翻倍是否已领取
  bool _doubleRewardClaimed = false;

  // === 转盘状态 ===
  /// 转盘是否正在旋转
  bool _isSpinning = false;

  /// 当前旋转角度
  double _rotationAngle = 0;

  /// 转盘区域定义（8等分）
  final List<Map<String, dynamic>> _spinSectors = [
    {'label': '谢谢参与', 'reward': 0, 'color': const Color(0xFF9E9E9E)},
    {'label': '10金币', 'reward': 10, 'color': const Color(0xFF8BC34A)},
    {'label': '20金币', 'reward': 20, 'color': const Color(0xFFCDDC39)},
    {'label': '50金币', 'reward': 50, 'color': const Color(0xFF4CAF50)},
    {'label': '100金币', 'reward': 100, 'color': const Color(0xFF8BC34A)},
    {'label': '200金币', 'reward': 200, 'color': const Color(0xFFFFC107)},
    {'label': '500金币', 'reward': 500, 'color': const Color(0xFFFF9800)},
    {'label': '1000金币', 'reward': 1000, 'color': const Color(0xFFF44336)},
  ];

  // === 任务状态 ===
  List<Map<String, dynamic>> _tasks = [];
  bool _isLoadingTasks = true;
  String? _taskError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _tabController.addListener(_onTabChanged);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 2) {
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (mounted) {
      setState(() {
        _isLoadingTasks = true;
        _taskError = null;
      });
    }
    try {
      final response = await ApiService().getDailyTasks();
      final tasks = response is List
          ? response
              .whereType<Map<String, dynamic>>()
              .map(Map<String, dynamic>.from)
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingTasks = false;
        _taskError = e.toString();
      });
    }
  }

  // ==================== 签到逻辑 ====================

  /// 签到
  Future<void> _signIn() async {
    if (_todaySigned) return;
    try {
      final result = await ApiService().signIn();
      await AuthService().refreshUser();
      if (!mounted) return;
      final gold = result['gold'] as int? ?? 0;
      setState(() {
        _todaySigned = true;
        _consecutiveDays = result['consecutive'] as int? ?? _consecutiveDays;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('签到成功！获得 $gold 金币'),
          backgroundColor: Constants.SYSTEM_GREEN,
        ),
      );
      _showDoubleDialog();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('签到失败: $e')),
      );
    }
  }

  /// 显示签到翻倍弹窗
  void _showDoubleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('签到奖励'),
        content: const Text('观看广告可将签到奖励翻倍至 100 金币！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('不用了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AdService().showRewardedAd(
                'sign_in_double',
                () {
                  if (!mounted) return;
                  setState(() {
                    _doubleRewardClaimed = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('翻倍成功，奖励已到账'),
                      backgroundColor: Constants.GOLD,
                    ),
                  );
                },
                context: context,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.PRIMARY_RED,
              foregroundColor: Colors.white,
            ),
            child: const Text('观看广告翻倍'),
          ),
        ],
      ),
    );
  }

  // ==================== 转盘逻辑 ====================

  /// 开始转盘
  Future<void> _startSpin() async {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
    });

    try {
      final result = await ApiService().spin();
      await AuthService().refreshUser();
      if (!mounted) return;
      final reward = result['gold'] as int? ?? 0;
      final sectorIndex = _spinSectors.indexWhere(
        (sector) => sector['reward'] == reward,
      );
      if (sectorIndex < 0) {
        throw Exception('服务端返回了未知转盘奖励: $reward');
      }
      final sector = _spinSectors[sectorIndex];
      final random = Random();

      // 计算目标角度（每个扇区45度，加上随机偏移）
      final sectorAngle = 360 / _spinSectors.length;
      final targetAngle =
          360 * 5 + (sectorIndex * sectorAngle) + random.nextInt(40) - 20;

      _animateSpin(targetAngle, sector);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSpinning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转盘失败: $e')),
      );
    }
  }

  /// 执行旋转动画
  void _animateSpin(double targetAngle, Map<String, dynamic> sector) {
    final startAngle = _rotationAngle;
    const duration = Duration(seconds: 3);
    final startTime = DateTime.now();

    void tick() {
      final elapsed = DateTime.now().difference(startTime);
      final progress = elapsed.inMilliseconds / duration.inMilliseconds;

      if (progress >= 1.0) {
        setState(() {
          _rotationAngle = targetAngle;
          _isSpinning = false;
        });
        _showSpinResult(sector);
        return;
      }

      // 缓动函数（ease-out）
      final eased =
          1.0 - (1.0 - progress) * (1.0 - progress) * (1.0 - progress);
      setState(() {
        _rotationAngle = startAngle + (targetAngle - startAngle) * eased;
      });

      Future.delayed(const Duration(milliseconds: 16), tick);
    }

    tick();
  }

  /// 显示转盘结果
  void _showSpinResult(Map<String, dynamic> sector) {
    final reward = sector['reward'] as int;
    final label = sector['label'] as String;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('转盘结果'),
        content: Text(
          reward > 0
              ? '恭喜获得 $label！'
              : label == '再来一次'
                  ? '获得再来一次机会！'
                  : '谢谢参与，下次好运！',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.PRIMARY_RED,
              foregroundColor: Colors.white,
            ),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // ==================== 任务逻辑 ====================

  /// 领取任务奖励
  Future<void> _claimTaskReward(int index) async {
    final task = _tasks[index];
    if (task['claimed'] == true || task['claimable'] != true) {
      return;
    }
    try {
      final result = await ApiService().claimDailyTask(task['key'] as String);
      await AuthService().refreshUser();
      await _loadTasks();
      if (!mounted) return;
      final gold = result['gold'] as int? ?? task['reward'] as int;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('领取成功！获得 $gold 金币'),
          backgroundColor: Constants.GOLD,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('领取失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '奖励中心',
          style: TextStyle(
            color: Constants.TEXT_PRIMARY,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Constants.TEXT_PRIMARY),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Constants.PRIMARY_RED,
          unselectedLabelColor: Constants.TEXT_SECONDARY,
          indicatorColor: Constants.PRIMARY_RED,
          tabs: const [
            Tab(text: '签到', icon: Icon(Icons.calendar_today)),
            Tab(text: '转盘', icon: Icon(Icons.casino)),
            Tab(text: '任务', icon: Icon(Icons.assignment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSignInTab(),
          _buildSpinTab(),
          _buildTaskTab(),
        ],
      ),
    );
  }

  // ==================== 签到Tab ====================

  Widget _buildSignInTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 连续签到提示
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Constants.GOLD.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Constants.GOLD.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Constants.GOLD, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '连续签到 $_consecutiveDays 天',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Constants.GOLD_DARK,
                        ),
                      ),
                      const Text(
                        '连续签到7天可获得额外奖励',
                        style: TextStyle(
                          fontSize: 12,
                          color: Constants.TEXT_SECONDARY,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // 日历格子
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 0.8,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = index + 1;
              final isSigned = index < _consecutiveDays;
              final isToday = index == _consecutiveDays && !_todaySigned;
              final isPast = index < _consecutiveDays;

              return GestureDetector(
                onTap: isToday ? _signIn : null,
                child: Container(
                  decoration: BoxDecoration(
                    color: isToday
                        ? Constants.PRIMARY_RED.withOpacity(0.1)
                        : isPast
                            ? Constants.SYSTEM_GREEN.withOpacity(0.1)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isToday
                          ? Constants.PRIMARY_RED
                          : isPast
                              ? Constants.SYSTEM_GREEN
                              : Constants.DIVIDER,
                      width: isToday ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '第$day天',
                        style: TextStyle(
                          fontSize: 12,
                          color: isToday
                              ? Constants.PRIMARY_RED
                              : Constants.TEXT_SECONDARY,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSigned)
                        const Icon(Icons.check_circle,
                            color: Constants.SYSTEM_GREEN, size: 24)
                      else if (isToday)
                        const Icon(Icons.touch_app,
                            color: Constants.PRIMARY_RED, size: 24)
                      else
                        Text(
                          '+${50 + (index * 10)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[400],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // 签到按钮
          if (!_todaySigned)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _signIn,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.PRIMARY_RED,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '今日签到',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Constants.SYSTEM_GREEN),
                  const SizedBox(width: 8),
                  Text(
                    _doubleRewardClaimed ? '今日已签到（已翻倍）' : '今日已签到',
                    style: const TextStyle(
                      color: Constants.SYSTEM_GREEN,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== 转盘Tab ====================

  Widget _buildSpinTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 转盘区域
          SizedBox(
            width: 280,
            height: 280,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 转盘
                Transform.rotate(
                  angle: _rotationAngle * 3.14159 / 180,
                  child: Container(
                    width: 260,
                    height: 260,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      size: const Size(260, 260),
                      painter: _WheelPainter(sectors: _spinSectors),
                    ),
                  ),
                ),
                // 指针（固定在上方）
                Positioned(
                  top: 8,
                  child: Container(
                    width: 24,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Constants.PRIMARY_RED,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 开始按钮
          SizedBox(
            width: 200,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSpinning ? null : _startSpin,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Constants.PRIMARY_RED,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _isSpinning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      '开始转动',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          // 奖励说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '转盘奖励说明',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _spinSectors.map((sector) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: (sector['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (sector['color'] as Color).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        sector['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: sector['color'] as Color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 任务Tab ====================

  Widget _buildTaskTab() {
    if (_isLoadingTasks) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_taskError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_taskError!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTasks,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    if (_tasks.isEmpty) {
      return const Center(child: Text('暂无任务'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tasks.length,
      itemBuilder: (context, index) {
        final task = _tasks[index];
        final progress = (task['current'] as int) / (task['target'] as int);
        final isComplete = task['claimable'] == true || task['claimed'] == true;
        final isClaimed = task['claimed'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClaimed
                          ? Colors.grey[200]
                          : isComplete
                              ? Constants.GOLD.withOpacity(0.1)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '+${task['reward']} 金币',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isClaimed
                            ? Colors.grey
                            : isComplete
                                ? Constants.GOLD_DARK
                                : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 进度条
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Constants.SYSTEM_GREEN : Constants.ORANGE,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${task['current']}/${task['target']}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: isComplete && !isClaimed
                        ? () => _claimTaskReward(index)
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Constants.PRIMARY_RED,
                      disabledBackgroundColor: Colors.grey[300],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isClaimed
                          ? '已领取'
                          : isComplete
                              ? '领取'
                              : '进行中',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 转盘绘制器
class _WheelPainter extends CustomPainter {
  final List<Map<String, dynamic>> sectors;

  _WheelPainter({required this.sectors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectorAngle = 2 * 3.14159 / sectors.length;

    for (int i = 0; i < sectors.length; i++) {
      final startAngle = i * sectorAngle - 3.14159 / 2;
      final sector = sectors[i];

      // 绘制扇形
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          sectorAngle,
          false,
        )
        ..close();

      canvas.drawPath(
        path,
        Paint()
          ..color = (sector['color'] as Color).withOpacity(0.8)
          ..style = PaintingStyle.fill,
      );

      // 绘制文字
      final textAngle = startAngle + sectorAngle / 2;
      final textRadius = radius * 0.65;
      final textOffset = Offset(
        center.dx + textRadius * cos(textAngle),
        center.dy + textRadius * sin(textAngle),
      );

      final textPainter = TextPainter(
        text: TextSpan(
          text: sector['label'] as String,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        textOffset.translate(-textPainter.width / 2, -textPainter.height / 2),
      );
    }

    // 绘制中心圆
    canvas.drawCircle(
      center,
      radius * 0.15,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 金币记录模型类
/// 对应后端 gold_records 表，展示用户的金币收支明细
/// 每条记录包含变动金额、类型、描述和时间
class GoldRecord {
  /// 记录ID
  final int id;

  /// 变动金额（正数=增加，负数=消耗）
  final int amount;

  /// 变动类型（对应后端 ENUM）
  /// ad_watch: 观看广告奖励
  /// game: 游戏结算奖励
  /// record: 刷新纪录奖励
  /// sign_in: 每日签到奖励
  /// spin: 转盘抽奖奖励
  /// task: 任务完成奖励
  /// withdraw: 提现扣除
  /// hint: 使用提示消耗
  final String type;

  /// 描述文字（如"游戏结算奖励 +120金币"）
  final String description;

  /// 创建时间
  final DateTime createdAt;

  GoldRecord({
    required this.id,
    required this.amount,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  /// 从后端JSON创建金币记录对象
  factory GoldRecord.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') ? json['data'] : json;
    return GoldRecord(
      id: data['id'] as int,
      amount: data['amount'] as int,
      type: data['type'] as String,
      description: data['description'] as String? ?? '',
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }

  /// 获取类型中文显示名
  String get typeDisplayName {
    switch (type) {
      case 'ad_watch':
        return '广告奖励';
      case 'game':
        return '游戏奖励';
      case 'record':
        return '纪录奖励';
      case 'sign_in':
        return '签到奖励';
      case 'spin':
        return '转盘奖励';
      case 'task':
        return '任务奖励';
      case 'withdraw':
        return '提现扣除';
      case 'hint':
        return '提示消耗';
      default:
        return '其他';
    }
  }

  /// 是否为收入（金额>0）
  bool get isIncome => amount > 0;

  /// 格式化后的金额（带正负号）
  String get formattedAmount {
    final sign = amount > 0 ? '+' : '';
    return '$sign$amount';
  }

  @override
  String toString() {
    return 'GoldRecord($type, $formattedAmount, $description)';
  }
}

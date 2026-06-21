/// 排行榜条目模型类
/// 展示全服或好友排行榜中的单个玩家排名数据
/// 排行榜按轮数从高到低排序，轮数相同按时间先后
class LeaderboardEntry {
  /// 排名（1=冠军）
  final int rank;

  /// 用户ID
  final int userId;

  /// 昵称（匿名显示"成语达人"）
  final String nickname;

  /// 头像URL
  final String? avatar;

  /// 最高轮数纪录
  final int rounds;

  /// 达到纪录的日期
  final DateTime? recordDate;

  /// 是否为当前登录用户（用于高亮显示）
  final bool isMe;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.rounds,
    this.recordDate,
    this.isMe = false,
  });

  /// 从后端JSON创建排行榜条目
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    final data = json.containsKey('data') ? json['data'] : json;
    return LeaderboardEntry(
      rank: data['rank'] as int,
      userId: data['user_id'] as int,
      nickname: data['nickname'] as String? ?? '成语达人',
      avatar: data['avatar'] as String?,
      rounds: data['rounds'] as int,
      recordDate: data['record_date'] != null
          ? DateTime.tryParse(data['record_date'] as String)
          : null,
      isMe: (data['is_me'] as int? ?? 0) == 1,
    );
  }

  /// 获取排名图标（前3名特殊显示）
  String? get rankIcon {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return null;
    }
  }

  /// 获取排名背景色（用于列表项装饰）
  String get rankColorHex {
    switch (rank) {
      case 1:
        return '#FFD700'; // 金色
      case 2:
        return '#C0C0C0'; // 银色
      case 3:
        return '#CD7F32'; // 铜色
      default:
        return '#F5F5F5'; // 浅灰
    }
  }

  @override
  String toString() {
    return 'LeaderboardEntry(rank=$rank, nickname=$nickname, rounds=$rounds)';
  }
}

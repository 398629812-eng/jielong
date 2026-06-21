/// 用户模型类
/// 包含用户的基本信息、金币余额、提示次数等游戏相关数据
class User {
  /// 用户ID（后端主键）
  final int? id;

  /// 手机号（注册用户使用）
  final String? phone;

  /// 微信openid（微信登录用户使用）
  final String? openid;

  /// 昵称（默认"成语达人"或用户自定义）
  final String nickname;

  /// 头像URL（为空时显示默认头像）
  final String? avatar;

  /// 金币余额（游戏核心货币）
  final int gold;

  /// 累计已提现金币（用于展示总收益）
  final int totalWithdrawn;

  /// 提示次数剩余（每局限用，可通过广告补充）
  final int hints;

  /// 是否为历史游客账号
  final bool isGuest;

  /// 是否被封禁（后端风控判定）
  final bool isBanned;

  /// 最后签到日期（YYYY-MM-DD格式，用于判断连续签到）
  final String? lastSignInDate;

  /// 连续签到天数
  final int consecutiveSignIn;

  /// JWT认证令牌（所有API请求的凭证）
  final String? token;

  /// 创建时间
  final DateTime? createdAt;

  User({
    this.id,
    this.phone,
    this.openid,
    this.nickname = '成语达人',
    this.avatar,
    this.gold = 0,
    this.totalWithdrawn = 0,
    this.hints = 3,
    this.isGuest = true,
    this.isBanned = false,
    this.lastSignInDate,
    this.consecutiveSignIn = 0,
    this.token,
    this.createdAt,
  });

  /// 从后端JSON响应创建用户对象
  /// 接口响应格式：{ "code": 0, "data": { ... } }
  factory User.fromJson(Map<String, dynamic> json) {
    // 适配统一响应格式，优先取 data 字段
    final data = json.containsKey('data') ? json['data'] : json;

    return User(
      id: data['id'] as int?,
      phone: data['phone'] as String?,
      openid: data['openid'] as String?,
      nickname: data['nickname'] as String? ?? '成语达人',
      avatar: data['avatar'] as String?,
      gold: data['gold'] as int? ?? 0,
      totalWithdrawn: data['total_withdrawn'] as int? ?? 0,
      hints: data['hints'] as int? ?? 3,
      isGuest: (data['is_guest'] as int? ?? 1) == 1,
      isBanned: (data['is_banned'] as int? ?? 0) == 1,
      lastSignInDate: data['last_sign_in_date'] as String?,
      consecutiveSignIn: data['consecutive_sign_in'] as int? ?? 0,
      token: data['token'] as String?,
      createdAt: data['created_at'] != null
          ? DateTime.tryParse(data['created_at'] as String)
          : null,
    );
  }

  /// 转换为JSON，用于本地缓存存储（SharedPreferences）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone': phone,
      'openid': openid,
      'nickname': nickname,
      'avatar': avatar,
      'gold': gold,
      'total_withdrawn': totalWithdrawn,
      'hints': hints,
      'is_guest': isGuest ? 1 : 0,
      'is_banned': isBanned ? 1 : 0,
      'last_sign_in_date': lastSignInDate,
      'consecutive_sign_in': consecutiveSignIn,
      'token': token,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// 创建副本并修改指定字段（不可变更新模式）
  User copyWith({
    int? id,
    String? phone,
    String? openid,
    String? nickname,
    String? avatar,
    int? gold,
    int? totalWithdrawn,
    int? hints,
    bool? isGuest,
    bool? isBanned,
    String? lastSignInDate,
    int? consecutiveSignIn,
    String? token,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      openid: openid ?? this.openid,
      nickname: nickname ?? this.nickname,
      avatar: avatar ?? this.avatar,
      gold: gold ?? this.gold,
      totalWithdrawn: totalWithdrawn ?? this.totalWithdrawn,
      hints: hints ?? this.hints,
      isGuest: isGuest ?? this.isGuest,
      isBanned: isBanned ?? this.isBanned,
      lastSignInDate: lastSignInDate ?? this.lastSignInDate,
      consecutiveSignIn: consecutiveSignIn ?? this.consecutiveSignIn,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 计算可提现人民币金额（10000金币 = 1元）
  /// 返回保留两位小数的金额字符串
  String get withdrawableRmb {
    final rmb = gold / 10000;
    return rmb.toStringAsFixed(2);
  }

  /// 判断是否为有效登录状态（有token且未被封禁）
  bool get isValid => token != null && token!.isNotEmpty && !isBanned;

  @override
  String toString() {
    return 'User(id=$id, nickname=$nickname, gold=$gold, hints=$hints, isGuest=$isGuest)';
  }
}

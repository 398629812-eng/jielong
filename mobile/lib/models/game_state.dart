import 'idiom.dart';

/// 游戏状态模型类
/// 管理一局游戏中的完整状态：难度、计时、轮数、成语链条、已使用成语等
/// 此类为纯数据模型，UI更新由 GameScreen 的 setState 管理
class GameState {
  /// 游戏唯一ID（用于后端记录，防止重复提交和防作弊）
  final String gameId;

  /// 游戏难度：easy（简单60秒）、normal（普通30秒）、hard（困难15秒）
  final String difficulty;

  /// 每轮倒计时总秒数（根据难度设定）
  final int totalSeconds;

  /// 当前剩余秒数（实时递减，到0时游戏结束）
  int remainingSeconds;

  /// 成功接龙轮数（玩家每成功接对一个成语，轮数+1）
  int rounds;

  /// 成语接龙链条（系统成语和玩家成语交替排列）
  /// 索引偶数为系统出题，奇数为玩家回答
  final List<Idiom> idiomChain;

  /// 已使用成语集合（防止同一成语重复使用，用成语文本作为唯一标识）
  final Set<String> usedIdioms;

  /// 是否已刷新纪录（游戏结束时由后端判定或本地比对）
  bool isNewRecord;

  /// 本局获得金币（基础奖励 + 纪录奖励）
  int earnedGold;

  /// 是否已使用过续命（每局限1次，看广告后继续游戏）
  bool hasContinued;

  /// 同音不同调开关（从设置页读取，影响接龙匹配规则）
  bool allowDifferentTone;

  /// 游戏开始时间（用于防作弊：异常短时间的游戏可能判定为作弊）
  final DateTime startTime;

  /// 游戏结束原因：timeout（超时）、wrong_answer（回答错误）、quit（主动退出）
  String? endReason;

  GameState({
    required this.gameId,
    required this.difficulty,
    required this.totalSeconds,
    this.remainingSeconds = 0,
    this.rounds = 0,
    List<Idiom>? idiomChain,
    Set<String>? usedIdioms,
    this.isNewRecord = false,
    this.earnedGold = 0,
    this.hasContinued = false,
    this.allowDifferentTone = false,
    DateTime? startTime,
    this.endReason,
  })  : idiomChain = idiomChain ?? [],
        usedIdioms = usedIdioms ?? {},
        startTime = startTime ?? DateTime.now();

  /// 获取当前最后一个成语（即玩家需要接的成语）
  /// 返回链条末尾的成语，如果链条为空则返回null
  Idiom? get currentIdiom => idiomChain.isNotEmpty ? idiomChain.last : null;

  /// 获取当前需要接的尾字拼音（用于匹配下一个成语的首字）
  /// 根据同音不同调设置决定返回带声调或不带声调拼音
  String get targetTailPinyin {
    if (currentIdiom == null) return '';
    return allowDifferentTone
        ? currentIdiom!.lastPinyinNoTone
        : currentIdiom!.lastPinyin;
  }

  /// 获取当前需要接的尾字汉字（用于UI展示提示）
  String get targetTailChar => currentIdiom?.lastChar ?? '';

  /// 添加成语到链条（成功接龙后调用）
  /// 同时更新轮数、已使用集合和计时
  void addIdiom(Idiom idiom) {
    idiomChain.add(idiom);
    usedIdioms.add(idiom.idiom);
    rounds++;
    // 重置剩余时间（每轮独立计时）
    remainingSeconds = totalSeconds;
  }

  /// 使用续命（看广告后继续游戏，每局限1次）
  /// 重置剩余时间并标记已续命
  void useContinue() {
    if (!hasContinued) {
      hasContinued = true;
      remainingSeconds = totalSeconds;
    }
  }

  /// 计算基础金币奖励（每轮10金币）
  int get baseGoldReward => rounds * 10;

  /// 计算纪录奖励（刷新纪录额外2000金币）
  int get recordGoldReward => isNewRecord ? 2000 : 0;

  /// 计算总金币奖励
  int get totalGoldReward => baseGoldReward + recordGoldReward;

  /// 将成语链条转换为字符串列表（用于后端上报）
  List<String> get chainStrings => idiomChain.map((i) => i.idiom).toList();

  /// 判断游戏是否进行中（剩余时间>0且未结束）
  bool get isActive => remainingSeconds > 0 && endReason == null;

  /// 获取难度中文显示名
  String get difficultyDisplayName {
    switch (difficulty) {
      case 'easy':
        return '简单';
      case 'normal':
        return '普通';
      case 'hard':
        return '困难';
      default:
        return '普通';
    }
  }

  /// 获取难度颜色（用于UI主题色切换）
  String get difficultyColorHex {
    switch (difficulty) {
      case 'easy':
        return '#4CAF50'; // 绿色
      case 'normal':
        return '#FF9800'; // 橙色
      case 'hard':
        return '#E53935'; // 红色
      default:
        return '#FF9800';
    }
  }

  /// 复制游戏状态（用于创建新轮次的状态快照）
  GameState copyWith({
    String? gameId,
    String? difficulty,
    int? totalSeconds,
    int? remainingSeconds,
    int? rounds,
    List<Idiom>? idiomChain,
    Set<String>? usedIdioms,
    bool? isNewRecord,
    int? earnedGold,
    bool? hasContinued,
    bool? allowDifferentTone,
    DateTime? startTime,
    String? endReason,
  }) {
    return GameState(
      gameId: gameId ?? this.gameId,
      difficulty: difficulty ?? this.difficulty,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      rounds: rounds ?? this.rounds,
      idiomChain: idiomChain ?? List.from(this.idiomChain),
      usedIdioms: usedIdioms ?? Set.from(this.usedIdioms),
      isNewRecord: isNewRecord ?? this.isNewRecord,
      earnedGold: earnedGold ?? this.earnedGold,
      hasContinued: hasContinued ?? this.hasContinued,
      allowDifferentTone: allowDifferentTone ?? this.allowDifferentTone,
      startTime: startTime ?? this.startTime,
      endReason: endReason ?? this.endReason,
    );
  }

  @override
  String toString() {
    return 'GameState(difficulty=$difficulty, rounds=$rounds, remaining=$remainingSeconds, chain=${idiomChain.length})';
  }
}

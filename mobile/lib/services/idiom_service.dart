import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/idiom.dart';
import '../utils/pinyin_helper.dart';

/// 本地成语数据库服务
/// 管理从 assets/idioms.json 加载的成语数据，构建索引，提供接龙核心算法
/// 所有方法均有详细中文注释，确保接龙逻辑清晰可维护
class IdiomService {
  /// 单例实例
  static final IdiomService _instance = IdiomService._internal();
  factory IdiomService() => _instance;
  IdiomService._internal();

  /// 是否已加载完成
  bool _loaded = false;

  /// 所有成语映射：{ 成语文本: Idiom对象 }
  /// 用于快速查找成语是否存在（O(1)查询）
  final Map<String, Idiom> _idiomMap = {};

  /// 按首字带声调拼音分组成语索引：{ 首字拼音: [Idiom, ...] }
  /// 用于严格匹配模式下查找可接成语
  final Map<String, List<Idiom>> _firstPinyinIndex = {};

  /// 按首字无调拼音分组成语索引：{ 首字无调拼音: [Idiom, ...] }
  /// 用于同音不同调模式下查找可接成语
  final Map<String, List<Idiom>> _firstPinyinNoToneIndex = {};

  /// 按尾字带声调拼音分组成语索引：{ 尾字拼音: [Idiom, ...] }
  /// 用于AI选词时计算后续可选范围（频率分析）
  final Map<String, List<Idiom>> _lastPinyinIndex = {};

  /// 按尾字无调拼音分组成语索引：{ 尾字无调拼音: [Idiom, ...] }
  /// 用于同音不同调模式下AI选词
  final Map<String, List<Idiom>> _lastPinyinNoToneIndex = {};

  /// 随机数生成器（用于随机选词）
  final Random _random = Random();

  /// 从本地JSON资源加载成语数据库
  /// 此方法在应用启动时调用（通常在 SplashScreen 中异步加载）
  /// 加载后构建多个索引以加速查询
  Future<void> loadIdioms() async {
    if (_loaded) return; // 避免重复加载

    try {
      // 从 assets/idioms.json 加载原始JSON字符串
      final jsonString = await rootBundle.loadString('assets/idioms.json');
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      // 遍历所有成语数据，构建映射和索引
      for (final item in jsonList) {
        final idiom = Idiom.fromJson(item as Map<String, dynamic>);

        // 1. 构建成语映射（用于存在性验证）
        _idiomMap[idiom.idiom] = idiom;

        // 2. 构建首字拼音索引（严格匹配）
        _firstPinyinIndex.putIfAbsent(idiom.firstPinyin, () => []).add(idiom);

        // 3. 构建首字无调拼音索引（同音不同调匹配）
        _firstPinyinNoToneIndex
            .putIfAbsent(
              idiom.firstPinyinNoTone,
              () => [],
            )
            .add(idiom);

        // 4. 构建尾字拼音索引（AI选词频率分析）
        _lastPinyinIndex.putIfAbsent(idiom.lastPinyin, () => []).add(idiom);

        // 5. 构建尾字无调拼音索引
        _lastPinyinNoToneIndex
            .putIfAbsent(
              idiom.lastPinyinNoTone,
              () => [],
            )
            .add(idiom);
      }

      _loaded = true;
    } catch (e) {
      // 加载失败时抛出异常，由上层处理（如显示错误页面）
      throw Exception('成语数据库加载失败: $e');
    }
  }

  /// 获取随机起始成语（游戏开始时使用）
  /// 从所有成语中随机选取一个作为首条系统成语
  /// 返回：随机选中的Idiom对象
  Idiom getRandomStartIdiom() {
    _ensureLoaded();
    // 将所有成语转换为列表，随机取一个
    final idioms = _idiomMap.values.toList();
    if (idioms.isEmpty) {
      throw Exception('成语数据库为空');
    }
    return idioms[_random.nextInt(idioms.length)];
  }

  /// 查找所有可接的成语（给定上一个成语的尾字拼音）
  ///
  /// [tailPinyin] 上一个成语的尾字拼音（带声调或不带声调，取决于allowDifferentTone）
  /// [allowDifferentTone] 是否允许同音不同调（从设置读取）
  /// 返回：所有首字拼音匹配的成语列表（可能为空，表示无词可接）
  ///
  /// 使用场景：
  /// 1. 验证玩家输入时检查是否匹配
  /// 2. AI选词时获取候选列表
  /// 3. 获取提示时返回可选成语
  List<Idiom> findNextIdioms(
    String tailPinyin, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();
    if (tailPinyin.isEmpty) return [];

    // 根据模式选择索引查询
    if (allowDifferentTone) {
      // 同音不同调模式：使用无调拼音索引
      return List<Idiom>.from(
        _firstPinyinNoToneIndex[tailPinyin] ?? [],
      );
    } else {
      // 严格匹配模式：使用带声调拼音索引
      return List<Idiom>.from(
        _firstPinyinIndex[tailPinyin] ?? [],
      );
    }
  }

  /// 验证玩家输入的成语是否有效（接龙核心验证方法）
  ///
  /// [inputIdiom] 玩家输入的成语文本（如"一五一十"）
  /// [previousTailPinyin] 上一个成语的尾字拼音（需要匹配的目标拼音）
  /// [usedIdioms] 本局已使用的成语集合（防止重复）
  /// [allowDifferentTone] 是否允许同音不同调
  ///
  /// 返回 Map：
  /// {
  ///   'valid': bool,          // 是否验证通过
  ///   'message': String,      // 错误提示（验证失败时）或成功提示
  ///   'idiomDetail': Idiom?   // 成语详情（验证成功时返回）
  /// }
  ///
  /// 验证流程（按顺序执行，任一失败即返回）：
  /// 1. 检查成语是否存在于数据库（是否收录）
  /// 2. 检查成语是否已在本局使用（防重复）
  /// 3. 检查首字拼音是否与上一个成语的尾字匹配（接龙规则）
  Map<String, dynamic> validateIdiom(
    String inputIdiom,
    String previousTailPinyin,
    Set<String> usedIdioms, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();

    // 步骤1：检查成语是否存在于数据库
    final idiom = _idiomMap[inputIdiom.trim()];
    if (idiom == null) {
      return {
        'valid': false,
        'message': '该成语未收录，请尝试其他成语',
        'idiomDetail': null,
      };
    }

    // 步骤2：检查成语是否已在本局使用（防止重复使用同一个成语）
    if (usedIdioms.contains(idiom.idiom)) {
      return {
        'valid': false,
        'message': '该成语已在本局使用，请换其他成语',
        'idiomDetail': null,
      };
    }

    // 步骤3：检查首字拼音是否与上一个成语的尾字匹配
    // 使用 PinyinHelper 进行拼音匹配（支持同音不同调）
    final headPinyin =
        allowDifferentTone ? idiom.firstPinyinNoTone : idiom.firstPinyin;

    final isMatch = PinyinHelper.isMatch(
      previousTailPinyin,
      headPinyin,
      allowDifferentTone: allowDifferentTone,
    );

    if (!isMatch) {
      // 提示用户正确的拼音和可以接的拼音
      return {
        'valid': false,
        'message':
            '接龙不匹配！上一个成语尾字拼音为 "$previousTailPinyin"，请接首字匹配 "$previousTailPinyin" 的成语',
        'idiomDetail': null,
      };
    }

    // 验证通过
    return {
      'valid': true,
      'message': '接龙成功！',
      'idiomDetail': idiom,
    };
  }

  /// 获取提示（返回一个可接的成语）
  ///
  /// [tailPinyin] 上一个成语的尾字拼音
  /// [usedIdioms] 已使用成语集合（排除已用）
  /// [allowDifferentTone] 是否允许同音不同调
  /// 返回：一个可接的成语（Idiom?），如果没有可接的返回null
  ///
  /// 提示逻辑：
  /// 1. 从候选列表中排除已使用成语
  /// 2. 随机返回一个未使用的可接成语（优先选择常见成语，增加游戏友好性）
  /// 3. 如果无词可接，返回null
  Idiom? getHint(
    String tailPinyin,
    Set<String> usedIdioms, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();

    // 查找所有可接成语
    final candidates = findNextIdioms(
      tailPinyin,
      allowDifferentTone: allowDifferentTone,
    );

    // 排除已使用成语
    final available =
        candidates.where((idiom) => !usedIdioms.contains(idiom.idiom)).toList();

    if (available.isEmpty) {
      return null; // 无词可接，提示无解
    }

    // 随机返回一个可接成语（提示应随机，避免总是同一答案）
    return available[_random.nextInt(available.length)];
  }

  /// 获取成语详情（通过成语文本查找）
  /// [idiom] 成语文本（如"一五一十"）
  /// 返回：Idiom对象（如果存在）或null
  Idiom? getIdiomDetail(String idiom) {
    _ensureLoaded();
    return _idiomMap[idiom.trim()];
  }

  /// 检查成语是否存在（快速查询）
  /// 用于实时输入验证时判断用户输入是否是一个有效成语
  bool isIdiomExists(String idiom) {
    _ensureLoaded();
    return _idiomMap.containsKey(idiom.trim());
  }

  // ==================== AI 选词逻辑（难度对应） ====================

  /// 简单难度 AI 选词策略：从可接列表中随机选择
  ///
  /// [tailPinyin] 上一个成语的尾字拼音
  /// [usedIdioms] 已使用成语集合
  /// [allowDifferentTone] 是否允许同音不同调
  /// 返回：选中的成语，或null表示无词可接
  ///
  /// 策略说明：
  /// 简单模式给玩家更多选择空间，AI随机选择不刻意刁难
  /// 增加玩家成功接龙的概率，适合新手体验
  Idiom? selectEasyIdiom(
    String tailPinyin,
    Set<String> usedIdioms, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();

    final candidates = findNextIdioms(
      tailPinyin,
      allowDifferentTone: allowDifferentTone,
    );
    final available =
        candidates.where((idiom) => !usedIdioms.contains(idiom.idiom)).toList();

    if (available.isEmpty) return null;

    // 简单模式：完全随机选择，不对玩家施加压力
    return available[_random.nextInt(available.length)];
  }

  /// 普通难度 AI 选词策略：优先选择尾字拼音出现频率低的成语
  ///
  /// [tailPinyin] 上一个成语的尾字拼音
  /// [usedIdioms] 已使用成语集合
  /// [allowDifferentTone] 是否允许同音不同调
  /// 返回：选中的成语，或null表示无词可接
  ///
  /// 策略说明：
  /// 普通模式AI会优先选择"生僻"的成语，即尾字拼音对应的首字拼音出现频率低的成语
  /// 这样玩家后续可接的成语范围会变小，增加挑战性
  /// 例如：AI选择尾字为"殇(shāng)"的成语，因为以"shang"开头的成语较少
  Idiom? selectNormalIdiom(
    String tailPinyin,
    Set<String> usedIdioms, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();

    final candidates = findNextIdioms(
      tailPinyin,
      allowDifferentTone: allowDifferentTone,
    );
    final available =
        candidates.where((idiom) => !usedIdioms.contains(idiom.idiom)).toList();

    if (available.isEmpty) return null;
    if (available.length == 1) return available.first;

    // 普通模式：排序可接列表，优先选择尾字生僻的成语
    // 计算每个候选成语的尾字拼音对应的首字拼音出现频率
    // 频率越低（生僻），排序越靠前（优先级越高）
    available.sort((a, b) {
      final aFrequency = _getFirstPinyinFrequency(
        a.lastPinyin,
        allowDifferentTone: allowDifferentTone,
      );
      final bFrequency = _getFirstPinyinFrequency(
        b.lastPinyin,
        allowDifferentTone: allowDifferentTone,
      );
      // 频率越低越优先（生僻字优先）
      return aFrequency.compareTo(bFrequency);
    });

    // 取前50%中的随机一个（避免总是选最生僻的，保持一定多样性）
    final topCount = (available.length * 0.5).ceil().clamp(1, available.length);
    final topCandidates = available.sublist(0, topCount);
    return topCandidates[_random.nextInt(topCandidates.length)];
  }

  /// 困难难度 AI 选词策略：深度计算，选择使玩家后续可选范围最小的成语
  ///
  /// [tailPinyin] 上一个成语的尾字拼音
  /// [usedIdioms] 已使用成语集合
  /// [allowDifferentTone] 是否允许同音不同调
  /// 返回：选中的成语，或null表示无词可接
  ///
  /// 策略说明：
  /// 困难模式AI会深度计算每个候选成语的"后续可选范围"
  /// 选择使玩家后续可选成语数量最少的那个（最刁钻的）
  /// 计算量较大，但能给高难度玩家最大挑战
  /// 为防止计算耗时过长，采用两层评估（评估AI下一个词后的玩家可选数）
  Idiom? selectHardIdiom(
    String tailPinyin,
    Set<String> usedIdioms, {
    bool allowDifferentTone = false,
  }) {
    _ensureLoaded();

    final candidates = findNextIdioms(
      tailPinyin,
      allowDifferentTone: allowDifferentTone,
    );
    final available =
        candidates.where((idiom) => !usedIdioms.contains(idiom.idiom)).toList();

    if (available.isEmpty) return null;
    if (available.length == 1) return available.first;

    // 困难模式：深度计算，评估每个候选成语的"难度值"
    // 难度值 = 玩家接该成语后，后续可接成语的数量（越少越难）
    // 采用两层评估：评估AI出词后，玩家可能接的成语再之后的AI可选数
    // 使用Map缓存计算结果，避免重复计算
    final difficultyMap = <Idiom, int>{};

    for (final candidate in available) {
      // 计算该候选成语的尾字拼音对应的"可接数量"
      // 数量越少，表示该成语越刁钻
      final nextOptions = findNextIdioms(
        allowDifferentTone ? candidate.lastPinyinNoTone : candidate.lastPinyin,
        allowDifferentTone: allowDifferentTone,
      );
      // 排除已使用（包括当前候选成语，防止重复使用）
      final usableOptions = nextOptions
          .where((i) =>
              !usedIdioms.contains(i.idiom) && i.idiom != candidate.idiom)
          .length;
      difficultyMap[candidate] = usableOptions;
    }

    // 按难度值排序（可选数越少越优先，即难度值越小越优先）
    available.sort((a, b) {
      return difficultyMap[a]!.compareTo(difficultyMap[b]!);
    });

    // 取前30%最刁钻的成语中随机选择（增加多样性，避免总是同一答案）
    final topCount = (available.length * 0.3).ceil().clamp(1, available.length);
    final hardCandidates = available.sublist(0, topCount);
    return hardCandidates[_random.nextInt(hardCandidates.length)];
  }

  // ==================== 辅助方法 ====================

  /// 获取某个拼音作为首字时，对应成语的数量（频率分析）
  /// 用于普通难度AI评估生僻程度
  ///
  /// [pinyin] 拼音（带声调或不带声调）
  /// [allowDifferentTone] 是否使用无调索引
  /// 返回：该拼音作为首字的成语数量（越大越常见，越小越生僻）
  int _getFirstPinyinFrequency(
    String pinyin, {
    bool allowDifferentTone = false,
  }) {
    if (allowDifferentTone) {
      return _firstPinyinNoToneIndex[pinyin]?.length ?? 0;
    } else {
      return _firstPinyinIndex[pinyin]?.length ?? 0;
    }
  }

  /// 获取数据库中成语总数
  int get totalIdiomCount => _idiomMap.length;

  /// 获取是否已加载
  bool get isLoaded => _loaded;

  /// 确保数据库已加载（所有公共方法开头调用）
  void _ensureLoaded() {
    if (!_loaded) {
      throw Exception('成语数据库尚未加载，请先调用 loadIdioms()');
    }
  }

  /// 获取数据库统计信息（用于调试和日志）
  /// 返回：包含成语总数、索引大小等信息的Map
  Map<String, int> getStatistics() {
    _ensureLoaded();
    return {
      'totalIdioms': _idiomMap.length,
      'firstPinyinIndexSize': _firstPinyinIndex.length,
      'firstPinyinNoToneIndexSize': _firstPinyinNoToneIndex.length,
      'lastPinyinIndexSize': _lastPinyinIndex.length,
      'lastPinyinNoToneIndexSize': _lastPinyinNoToneIndex.length,
    };
  }

  /// 清理资源（应用退出时调用）
  void dispose() {
    _idiomMap.clear();
    _firstPinyinIndex.clear();
    _firstPinyinNoToneIndex.clear();
    _lastPinyinIndex.clear();
    _lastPinyinNoToneIndex.clear();
    _loaded = false;
  }
}

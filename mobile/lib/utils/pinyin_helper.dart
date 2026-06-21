/// 拼音处理工具类
/// 提供成语接龙核心算法所需的拼音比较、提取、匹配功能
/// 支持严格匹配（带声调）和同音不同调匹配（仅拼音字母）
class PinyinHelper {
  /// 私有构造函数，禁止实例化（纯工具类）
  PinyinHelper._();

  // ==================== 基础提取方法 ====================

  /// 提取成语首字的拼音（带声调）
  /// [idiom] 成语对象
  /// 返回首字带声调拼音，如 "yī"
  static String getFirstPinyin(dynamic idiom) {
    return idiom.firstPinyin ?? '';
  }

  /// 提取成语尾字的拼音（带声调）
  /// [idiom] 成语对象
  /// 返回尾字带声调拼音，如 "shí"
  static String getLastPinyin(dynamic idiom) {
    return idiom.lastPinyin ?? '';
  }

  /// 提取成语首字的无声调拼音
  /// [idiom] 成语对象
  /// 返回首字无调拼音，如 "yi"
  static String getFirstPinyinNoTone(dynamic idiom) {
    return idiom.firstPinyinNoTone ?? '';
  }

  /// 提取成语尾字的无声调拼音
  /// [idiom] 成语对象
  /// 返回尾字无调拼音，如 "shi"
  static String getLastPinyinNoTone(dynamic idiom) {
    return idiom.lastPinyinNoTone ?? '';
  }

  // ==================== 核心匹配方法 ====================

  /// 判断两个拼音是否匹配（支持同音不同调）
  ///
  /// [sourcePinyin] 上一个成语的尾字拼音
  /// [targetPinyin] 下一个成语的首字拼音
  /// [allowDifferentTone] 是否允许同音不同调（如 shí 匹配 shì）
  ///
  /// 匹配规则：
  /// 1. 严格模式：带声调拼音必须完全一致（shí == shí）
  /// 2. 宽松模式：无调拼音字母部分一致即可（shi == shi）
  ///
  /// 返回 true 表示可以接龙，false 表示不匹配
  static bool isMatch(
    String sourcePinyin,
    String targetPinyin, {
    bool allowDifferentTone = false,
  }) {
    // 空值检查：任意一方为空则不匹配
    if (sourcePinyin.isEmpty || targetPinyin.isEmpty) {
      return false;
    }

    // 严格模式：直接比较带声调拼音（完全一致）
    if (!allowDifferentTone) {
      return sourcePinyin == targetPinyin;
    }

    // 宽松模式：去除声调后比较（同音不同调匹配）
    // 移除声调字符：āáǎà -> a, ōóǒò -> o, ēéěè -> e, īíǐì -> i, ūúǔù -> u, ǖǘǚǜ -> ü
    final sourceNoTone = _removeTones(sourcePinyin);
    final targetNoTone = _removeTones(targetPinyin);

    return sourceNoTone == targetNoTone;
  }

  /// 判断玩家输入的成语首字是否匹配上一个成语的尾字
  ///
  /// [previousIdiom] 上一个成语（系统或玩家已接的成语）
  /// [currentIdiom] 玩家当前输入的成语
  /// [allowDifferentTone] 是否允许同音不同调
  ///
  /// 此方法为成语接龙的核心验证逻辑，被 IdiomService.validateIdiom 调用
  static bool isChainValid(
    dynamic previousIdiom,
    dynamic currentIdiom, {
    bool allowDifferentTone = false,
  }) {
    if (previousIdiom == null || currentIdiom == null) {
      return false;
    }

    // 获取上一个成语的尾字拼音
    final tailPinyin = allowDifferentTone
        ? getLastPinyinNoTone(previousIdiom)
        : getLastPinyin(previousIdiom);

    // 获取当前成语的首字拼音
    final headPinyin = allowDifferentTone
        ? getFirstPinyinNoTone(currentIdiom)
        : getFirstPinyin(currentIdiom);

    return isMatch(tailPinyin, headPinyin,
        allowDifferentTone: allowDifferentTone);
  }

  // ==================== 声调处理工具方法 ====================

  /// 去除拼音中的声调符号，返回纯字母形式
  ///
  /// 声调映射表：
  /// ā(ā) á(á) ǎ(ǎ) à(à) -> a
  /// ō(ō) ó(ó) ǒ(ǒ) ò(ò) -> o
  /// ē(ē) é(é) ě(ě) è(è) -> e
  /// ī(ī) í(í) ǐ(ǐ) ì(ì) -> i
  /// ū(ū) ú(ú) ǔ(ǔ) ù(ù) -> u
  /// ǖ(ǖ) ǘ(ǘ) ǚ(ǚ) ǜ(ǜ) -> v（ü 的简写形式，便于比较）
  ///
  /// [pinyin] 带声调拼音字符串
  /// 返回去除声调后的字符串，如 "shí" -> "shi"
  static String _removeTones(String pinyin) {
    // 使用正则替换所有带声调字符为对应无调字母
    String result = pinyin;

    // ā á ǎ à -> a
    result = result.replaceAll(RegExp(r'[āáǎà]'), 'a');
    // ō ó ǒ ò -> o
    result = result.replaceAll(RegExp(r'[ōóǒò]'), 'o');
    // ē é ě è -> e
    result = result.replaceAll(RegExp(r'[ēéěè]'), 'e');
    // ī í ǐ ì -> i
    result = result.replaceAll(RegExp(r'[īíǐì]'), 'i');
    // ū ú ǔ ù -> u
    result = result.replaceAll(RegExp(r'[ūúǔù]'), 'u');
    // ǖ ǘ ǚ ǜ -> v (ü 的简写，用于比较)
    result = result.replaceAll(RegExp(r'[ǖǘǚǜ]'), 'v');
    // 轻声不处理（无声调符号）

    return result.toLowerCase();
  }

  /// 获取拼音的声调级别（1-4，0表示轻声或无调）
  /// 用于显示声调符号或声调数字
  ///
  /// [pinyin] 带声调拼音字符串
  /// 返回声调级别：1=阴平，2=阳平，3=上声，4=去声，0=轻声/无调
  static int getToneLevel(String pinyin) {
    // 检查是否有阴平声调字符（第一声）
    if (pinyin.contains(RegExp(r'[āēīōūǖ]'))) return 1;
    // 检查是否有阳平声调字符（第二声）
    if (pinyin.contains(RegExp(r'[áéíóúǘ]'))) return 2;
    // 检查是否有上声声调字符（第三声）
    if (pinyin.contains(RegExp(r'[ǎěǐǒǔǚ]'))) return 3;
    // 检查是否有去声声调字符（第四声）
    if (pinyin.contains(RegExp(r'[àèìòùǜ]'))) return 4;
    // 无声调字符，返回0（轻声或已去除声调）
    return 0;
  }

  // ==================== 辅助工具方法 ====================

  /// 将拼音字符串转换为带声调数字形式（如 "shí" -> "shi2"）
  /// 用于后端存储或拼音排序
  static String toToneNumber(String pinyin) {
    final tone = getToneLevel(pinyin);
    final noTone = _removeTones(pinyin);
    return tone > 0 ? '$noTone$tone' : noTone;
  }

  /// 判断拼音是否为轻声（无声调符号）
  static bool isLightTone(String pinyin) {
    return getToneLevel(pinyin) == 0 && pinyin.isNotEmpty;
  }

  /// 格式化拼音显示（用于UI展示成语拼音）
  /// 将 "yī wú yī shí" 格式化为更美观的显示形式
  static String formatPinyinDisplay(String pinyin) {
    // 将拼音中每个字之间加入适当空格，保持原样
    // 如需更复杂的格式化可在此扩展
    return pinyin.trim();
  }

  /// 获取成语首字和尾字的拼音组合（用于调试和日志）
  /// 返回格式："首[first]->尾[last]"
  static String getChainInfo(dynamic idiom) {
    return '首[${getFirstPinyin(idiom)}]->尾[${getLastPinyin(idiom)}]';
  }
}

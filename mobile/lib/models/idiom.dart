/// 成语模型类
/// 对应本地成语数据库（assets/idioms.json）和前端展示数据结构
/// 每个成语包含完整的拼音、释义、首尾拼音等关键信息
class Idiom {
  /// 成语文本（如"一五一十"）
  final String idiom;

  /// 带声调拼音（如"yī wú yī shí"）
  final String pinyin;

  /// 不带声调拼音（如"yi wu yi shi"），用于同音不同调匹配
  final String pinyinNoTones;

  /// 首字汉字（如"一"）
  final String firstChar;

  /// 首字带声调拼音（如"yī"）
  final String firstPinyin;

  /// 首字不带声调拼音（如"yi"），用于索引构建
  final String firstPinyinNoTone;

  /// 尾字汉字（如"十"）
  final String lastChar;

  /// 尾字带声调拼音（如"shí"）
  final String lastPinyin;

  /// 尾字不带声调拼音（如"shi"），用于接龙匹配
  final String lastPinyinNoTone;

  /// 成语释义（解释含义，用于游戏内展示学习）
  final String meaning;

  Idiom({
    required this.idiom,
    required this.pinyin,
    required this.pinyinNoTones,
    required this.firstChar,
    required this.firstPinyin,
    required this.firstPinyinNoTone,
    required this.lastChar,
    required this.lastPinyin,
    required this.lastPinyinNoTone,
    required this.meaning,
  });

  /// 从JSON数据创建成语对象
  /// 数据来源：assets/idioms.json（10000+条成语数据）
  factory Idiom.fromJson(Map<String, dynamic> json) {
    return Idiom(
      idiom: json['idiom'] as String,
      pinyin: json['pinyin'] as String,
      pinyinNoTones: json['pinyin_no_tones'] as String,
      firstChar: json['first_char'] as String,
      firstPinyin: json['first_pinyin'] as String,
      firstPinyinNoTone: json['first_pinyin_no_tone'] as String,
      lastChar: json['last_char'] as String,
      lastPinyin: json['last_pinyin'] as String,
      lastPinyinNoTone: json['last_pinyin_no_tone'] as String,
      meaning: json['meaning'] as String,
    );
  }

  /// 转换为JSON（用于游戏记录链条上传后端）
  Map<String, dynamic> toJson() {
    return {
      'idiom': idiom,
      'pinyin': pinyin,
      'pinyin_no_tones': pinyinNoTones,
      'first_char': firstChar,
      'first_pinyin': firstPinyin,
      'first_pinyin_no_tone': firstPinyinNoTone,
      'last_char': lastChar,
      'last_pinyin': lastPinyin,
      'last_pinyin_no_tone': lastPinyinNoTone,
      'meaning': meaning,
    };
  }

  @override
  String toString() => 'Idiom($idiom, $pinyin)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Idiom &&
          runtimeType == other.runtimeType &&
          idiom == other.idiom;

  @override
  int get hashCode => idiom.hashCode;
}

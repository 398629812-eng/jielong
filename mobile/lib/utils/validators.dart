/// 输入验证工具类
/// 提供手机号、金额、成语输入等表单验证功能
/// 所有验证方法返回错误消息，验证通过返回null
class Validators {
  /// 私有构造函数，禁止实例化（纯工具类）
  Validators._();

  // ==================== 手机号验证 ====================

  /// 中国大陆手机号验证
  /// 规则：1开头，第二位3-9，后面9位数字，共11位
  /// 支持：13x、14x、15x、16x、17x、18x、19x
  ///
  /// [phone] 手机号字符串
  /// 返回错误消息，或null表示验证通过
  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return '请输入手机号';
    }
    // 去除空格和横线
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length != 11) {
      return '手机号应为11位数字';
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(cleaned)) {
      return '手机号格式不正确';
    }
    return null;
  }

  /// 格式化手机号显示（138 1234 5678）
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 11) return phone;
    return '${cleaned.substring(0, 3)} ${cleaned.substring(3, 7)} ${cleaned.substring(7, 11)}';
  }

  // ==================== 金额验证（提现） ====================

  /// 提现金额验证
  /// 规则：
  /// 1. 必须是整数（元）
  /// 2. 最低1元（10000金币）
  /// 3. 不能超过当前金币余额
  /// 4. 不能超过单笔上限（后端配置，默认50元）
  ///
  /// [amount] 输入金额（人民币元，字符串）
  /// [maxGold] 当前金币余额
  /// [maxRmb] 单笔上限（元）
  /// 返回错误消息，或null表示验证通过
  static String? validateWithdrawAmount(String? amount, int maxGold,
      {int maxRmb = 50}) {
    if (amount == null || amount.isEmpty) {
      return '请输入提现金额';
    }
    // 只接受整数
    if (!RegExp(r'^\d+$').hasMatch(amount)) {
      return '请输入整数金额';
    }
    final rmb = int.tryParse(amount);
    if (rmb == null) {
      return '金额格式不正确';
    }
    // 最低1元
    if (rmb < 1) {
      return '最低提现1元';
    }
    // 计算最大可提现金额（按10000金币=1元）
    final maxWithdrawable = maxGold ~/ 10000;
    if (rmb > maxWithdrawable) {
      return '余额不足，最多可提 $maxWithdrawable 元';
    }
    // 单笔上限
    if (rmb > maxRmb) {
      return '单笔最多提现 $maxRmb 元';
    }
    return null;
  }

  /// 计算金币对应人民币金额（保留2位小数）
  static String goldToRmb(int gold) {
    final rmb = gold / 10000;
    return rmb.toStringAsFixed(2);
  }

  /// 计算人民币对应金币数量
  static int rmbToGold(int rmb) {
    return rmb * 10000;
  }

  // ==================== 成语输入验证 ====================

  /// 成语输入验证（实时输入时调用）
  /// 规则：
  /// 1. 必须是汉字
  /// 2. 必须是4个字
  /// 3. 不能为空
  ///
  /// 注意：此验证仅检查格式，不检查成语是否存在于数据库
  /// 成语存在性检查由 IdiomService.validateIdiom 负责
  ///
  /// [input] 用户输入的字符串
  /// 返回错误消息，或null表示格式验证通过
  static String? validateIdiomInput(String? input) {
    if (input == null || input.isEmpty) {
      return null; // 空输入不报错（提示用户输入）
    }
    // 去除空白字符
    final cleaned = input.trim();
    // 必须是纯汉字（Unicode 汉字范围：\u4e00-\u9fff）
    if (!RegExp(r'^[\u4e00-\u9fff]+$').hasMatch(cleaned)) {
      return '请输入纯汉字成语';
    }
    // 必须是4个字
    if (cleaned.length != 4) {
      return '成语必须是4个字';
    }
    return null;
  }

  /// 严格验证：检查输入是否为4字纯汉字（提交时调用）
  static String? validateIdiomSubmit(String? input) {
    if (input == null || input.isEmpty) {
      return '请输入成语';
    }
    final cleaned = input.trim();
    if (cleaned.isEmpty) {
      return '请输入成语';
    }
    if (!RegExp(r'^[\u4e00-\u9fff]+$').hasMatch(cleaned)) {
      return '请输入纯汉字成语';
    }
    if (cleaned.length != 4) {
      return '成语必须是4个字';
    }
    return null;
  }

  // ==================== 通用验证 ====================

  /// 昵称验证
  /// 规则：1-20个字符，不能全为空格
  static String? validateNickname(String? nickname) {
    if (nickname == null || nickname.trim().isEmpty) {
      return '请输入昵称';
    }
    if (nickname.trim().length > 20) {
      return '昵称最多20个字符';
    }
    return null;
  }

  /// 验证码验证（6位数字）
  static String? validateSmsCode(String? code) {
    if (code == null || code.isEmpty) {
      return '请输入验证码';
    }
    if (code.length != 4) {
      return '验证码应为4位数字';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(code)) {
      return '验证码格式不正确';
    }
    return null;
  }

  /// 支付宝账号验证（手机号或邮箱）
  static String? validateAlipayAccount(String? account) {
    if (account == null || account.isEmpty) {
      return '请输入支付宝账号';
    }
    // 邮箱或手机号
    final isEmail = RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(account);
    final isPhone = validatePhone(account) == null;
    if (!isEmail && !isPhone) {
      return '请输入正确的手机号或邮箱';
    }
    return null;
  }

  // ==================== 数值范围验证 ====================

  /// 验证数值是否在指定范围内
  static String? validateRange(int value, int min, int max, String fieldName) {
    if (value < min) {
      return '$fieldName不能小于$min';
    }
    if (value > max) {
      return '$fieldName不能大于$max';
    }
    return null;
  }
}

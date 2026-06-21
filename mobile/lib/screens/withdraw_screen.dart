import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';

/// 提现页面（Withdraw Screen）
/// 功能：
/// 1. 顶部：金币余额 + "≈ X元" 转换（10000金币=1元）
/// 2. 输入框：金额（元），只接受整数，验证余额
/// 3. 方式选择：微信（绿色图标）/ 支付宝（蓝色图标），单选
/// 4. 按钮："立即提现"（验证通过才可用）
/// 5. 底部：提现记录列表（时间+金额+状态）
/// 6. 提示文字："最低1元起提，每日最多X次"
class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  /// 金额输入控制器
  final TextEditingController _amountController = TextEditingController();

  /// 收款账号（测试环境仅记录，不执行真实打款）
  final TextEditingController _accountController = TextEditingController();

  /// 选中的提现方式（wechat/alipay）
  String _selectedMethod = 'wechat';

  /// 当前金币余额
  int _gold = 0;

  /// 是否正在提交
  bool _isSubmitting = false;

  /// 输入错误提示
  String? _errorText;

  final List<Map<String, dynamic>> _records = [];
  bool _recordsLoading = true;

  @override
  void initState() {
    super.initState();
    _updateGold();
    _loadRecords();
    AuthService().userNotifier.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    AuthService().userNotifier.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() => _updateGold());
  }

  void _updateGold() {
    _gold = AuthService().gold;
  }

  Future<void> _loadRecords() async {
    try {
      final result = await ApiService().getWithdrawHistory(pageSize: 10);
      final records = (result['list'] as List).map((item) {
        final row = Map<String, dynamic>.from(item);
        return {
          'time': row['created_at']
              ?.toString()
              .replaceFirst('T', ' ')
              .substring(0, 16),
          'amount': row['rmb_amount'],
          'status': row['status'],
        };
      }).toList();
      if (mounted) {
        setState(() {
          _records
            ..clear()
            ..addAll(records);
        });
      }
    } catch (_) {
      // 完整记录页提供重试入口；提现页保持主流程可用。
    } finally {
      if (mounted) setState(() => _recordsLoading = false);
    }
  }

  /// 计算可提现人民币金额
  double get _maxRmb => _gold / Constants.GOLD_TO_RMB;

  /// 提交提现
  Future<void> _submitWithdraw() async {
    final amountStr = _amountController.text.trim();
    final error =
        Validators.validateWithdrawAmount(amountStr, _gold, maxRmb: 50);
    if (error != null) {
      setState(() {
        _errorText = error;
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final rmbAmount = int.parse(amountStr);
      final accountInfo = _accountController.text.trim();
      if (accountInfo.isEmpty) {
        setState(() {
          _errorText = '请填写收款账号';
        });
        return;
      }

      await ApiService().applyWithdraw(
        rmbAmount,
        _selectedMethod,
        accountInfo,
      );
      await AuthService().refreshUser();
      if (!mounted) return;

      await _loadRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('提现申请已提交：$rmbAmount 元'),
          backgroundColor: Constants.SYSTEM_GREEN,
        ),
      );
      _amountController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = '提交失败: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
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
          '提现',
          style: TextStyle(
            color: Constants.TEXT_PRIMARY,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Constants.TEXT_PRIMARY),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 余额卡片
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Constants.GOLD, Color(0xFFFFB300)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Constants.GOLD.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet,
                          color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        '金币余额',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$_gold',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '≈ ${_maxRmb.toStringAsFixed(2)} 元',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 提现金额输入
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '提现金额',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Constants.TEXT_PRIMARY,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '¥ ',
                      prefixStyle: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Constants.TEXT_PRIMARY,
                      ),
                      hintText: '请输入整数金额',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[400],
                      ),
                      errorText: _errorText,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Constants.DIVIDER),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Constants.GOLD_DARK,
                          width: 2,
                        ),
                      ),
                    ),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Constants.TEXT_PRIMARY,
                    ),
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '最低1元起提，10000金币 = 1元',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // 提现方式选择
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '提现方式',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Constants.TEXT_PRIMARY,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 微信
                  _buildMethodItem(
                    'wechat',
                    '微信',
                    Icons.wechat,
                    Constants.WECHAT_GREEN,
                  ),
                  const SizedBox(height: 12),
                  // 支付宝
                  _buildMethodItem(
                    'alipay',
                    '支付宝',
                    Icons.payment,
                    Constants.ALIPAY_BLUE,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _accountController,
                    decoration: InputDecoration(
                      labelText: '收款账号（测试）',
                      hintText: _selectedMethod == 'wechat'
                          ? '请输入微信收款标识'
                          : '请输入支付宝账号',
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                    ),
                    onChanged: (_) => setState(() => _errorText = null),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 提交按钮
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWithdraw,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Constants.PRIMARY_RED,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        '立即提现',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            // 提现记录
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '提现记录',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Constants.TEXT_PRIMARY,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recordsLoading)
                    const Center(child: CircularProgressIndicator())
                  else if (_records.isEmpty)
                    Center(
                      child: Text(
                        '暂无提现记录',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[400],
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _records.length,
                      itemBuilder: (context, index) {
                        final record = _records[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${record['amount']} 元',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            record['time'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                          trailing:
                              _buildStatusBadge(record['status'] as String),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建支付方式选项
  Widget _buildMethodItem(
    String method,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? color : Constants.DIVIDER,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check_circle, color: color, size: 24),
          ],
        ),
      ),
    );
  }

  /// 构建状态标签
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    switch (status) {
      case 'approved':
        color = Constants.SYSTEM_GREEN;
        text = '已通过';
        break;
      case 'paid':
        color = Constants.PRIMARY_RED;
        text = '已到账';
        break;
      case 'pending':
        color = Constants.ORANGE;
        text = '审核中';
        break;
      case 'rejected':
        color = Constants.PRIMARY_RED;
        text = '已拒绝';
        break;
      default:
        color = Constants.TEXT_HINT;
        text = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/gold_record.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

String _formatDate(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  if (date == null) return '';
  String two(int number) => number.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)} ${two(date.hour)}:${two(date.minute)}';
}

class GoldHistoryScreen extends StatefulWidget {
  const GoldHistoryScreen({super.key});

  @override
  State<GoldHistoryScreen> createState() => _GoldHistoryScreenState();
}

class _GoldHistoryScreenState extends State<GoldHistoryScreen> {
  final List<GoldRecord> _records = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = reset ? 1 : _page;
      final result = await ApiService().getGoldHistory(page: page);
      final list = (result['list'] as List)
          .map((item) => GoldRecord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) _records.clear();
        _records.addAll(list);
        _page = page + 1;
        _hasMore = page < (result['totalPages'] as int? ?? page);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Constants.BACKGROUND,
        appBar:
            AppBar(title: const Text('金币明细'), backgroundColor: Colors.white),
        body: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: _records.isEmpty
              ? ListView(children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * .3),
                  Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : _error != null
                              ? TextButton(
                                  onPressed: () => _load(reset: true),
                                  child: const Text('加载失败，点击重试'))
                              : const Text('暂无金币明细'))
                ])
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _records.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 72),
                  itemBuilder: (context, index) {
                    if (index == _records.length) {
                      return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _load,
                                      child: const Text('加载更多'))));
                    }
                    final record = _records[index];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundColor: (record.isIncome
                                  ? Constants.SYSTEM_GREEN
                                  : Constants.PRIMARY_RED)
                              .withOpacity(.12),
                          child: Icon(
                              record.isIncome ? Icons.add : Icons.remove,
                              color: record.isIncome
                                  ? Constants.SYSTEM_GREEN
                                  : Constants.PRIMARY_RED)),
                      title: Text(record.description.isEmpty
                          ? record.typeDisplayName
                          : record.description),
                      subtitle:
                          Text(_formatDate(record.createdAt.toIso8601String())),
                      trailing: Text(record.formattedAmount,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: record.isIncome
                                  ? Constants.SYSTEM_GREEN
                                  : Constants.PRIMARY_RED)),
                    );
                  },
                ),
        ),
      );
}

class WithdrawHistoryScreen extends StatefulWidget {
  const WithdrawHistoryScreen({super.key});

  @override
  State<WithdrawHistoryScreen> createState() => _WithdrawHistoryScreenState();
}

class _WithdrawHistoryScreenState extends State<WithdrawHistoryScreen> {
  final List<Map<String, dynamic>> _records = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  String? _error;

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = reset ? 1 : _page;
      final result = await ApiService().getWithdrawHistory(page: page);
      final list = (result['list'] as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        if (reset) _records.clear();
        _records.addAll(list);
        _page = page + 1;
        _hasMore = page < (result['totalPages'] as int? ?? page);
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  ({String label, Color color}) _status(String status) => switch (status) {
        'paid' => (label: '已到账', color: Constants.SYSTEM_GREEN),
        'approved' => (label: '已通过', color: Constants.SYSTEM_GREEN),
        'rejected' => (label: '已拒绝', color: Constants.PRIMARY_RED),
        _ => (label: '审核中', color: Constants.ORANGE),
      };

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Constants.BACKGROUND,
        appBar:
            AppBar(title: const Text('提现记录'), backgroundColor: Colors.white),
        body: RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: _records.isEmpty
              ? ListView(children: [
                  SizedBox(height: MediaQuery.sizeOf(context).height * .3),
                  Center(
                      child: _loading
                          ? const CircularProgressIndicator()
                          : _error != null
                              ? TextButton(
                                  onPressed: () => _load(reset: true),
                                  child: const Text('加载失败，点击重试'))
                              : const Text('暂无提现记录'))
                ])
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _records.length + (_hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 24),
                  itemBuilder: (context, index) {
                    if (index == _records.length) {
                      return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Center(
                              child: _loading
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _load,
                                      child: const Text('加载更多'))));
                    }
                    final record = _records[index];
                    final status =
                        _status(record['status']?.toString() ?? 'pending');
                    return ListTile(
                      title: Text('¥${record['rmb_amount']}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          '${record['method'] == 'alipay' ? '支付宝' : '微信'}  ${_formatDate(record['created_at'])}${record['reject_reason'] == null ? '' : '\n${record['reject_reason']}'}'),
                      isThreeLine: record['reject_reason'] != null,
                      trailing: Text(status.label,
                          style: TextStyle(
                              color: status.color,
                              fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
      );
}

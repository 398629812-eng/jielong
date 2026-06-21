import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _leaderboard = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ApiService().getLeaderboard();
      if (!mounted) return;
      setState(() => _leaderboard = (result as List)
          .map((item) => Map<String, dynamic>.from(item))
          .toList());
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.BACKGROUND,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('排行榜',
              style: TextStyle(
                  color: Constants.TEXT_PRIMARY, fontWeight: FontWeight.bold)),
          iconTheme: const IconThemeData(color: Constants.TEXT_PRIMARY)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _leaderboard.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _leaderboard.isEmpty
                ? ListView(children: [
                    SizedBox(height: MediaQuery.sizeOf(context).height * .3),
                    Center(
                        child: _error != null
                            ? TextButton(
                                onPressed: _load,
                                child: const Text('加载失败，点击重试'))
                            : const Text('还没有排行榜记录'))
                  ])
                : ListView(
                    children: [
                      _buildPodium(),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                            children: _leaderboard
                                .map(_buildLeaderboardItem)
                                .toList()),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildPodium() {
    final top = _leaderboard.take(3).toList();
    final displayOrder = top.length == 3 ? [top[1], top[0], top[2]] : top;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      color: const Color(0xFFFFF8E1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayOrder
            .map((item) => Expanded(child: _buildTopPlayer(item)))
            .toList(),
      ),
    );
  }

  Widget _buildTopPlayer(Map<String, dynamic> item) {
    final rank = item['rank'] as int;
    final isFirst = rank == 1;
    final colors = {
      1: const Color(0xFFFFB300),
      2: const Color(0xFF90A4AE),
      3: const Color(0xFFB87333)
    };
    final color = colors[rank] ?? Constants.TEXT_SECONDARY;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.emoji_events, color: color, size: isFirst ? 44 : 34),
        const SizedBox(height: 6),
        CircleAvatar(
            radius: isFirst ? 34 : 28,
            backgroundColor: color.withOpacity(.15),
            child: Text('$rank',
                style: TextStyle(
                    fontSize: isFirst ? 24 : 18,
                    fontWeight: FontWeight.bold,
                    color: color))),
        const SizedBox(height: 6),
        Text(item['nickname'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${item['rounds']} 轮',
            style: const TextStyle(color: Constants.TEXT_SECONDARY)),
      ],
    );
  }

  Widget _buildLeaderboardItem(Map<String, dynamic> item) {
    final rank = item['rank'] as int;
    final isMe = item['is_me'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: isMe ? Constants.PRIMARY_RED.withOpacity(.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: isMe
              ? Border.all(color: Constants.PRIMARY_RED.withOpacity(.3))
              : null),
      child: ListTile(
        leading: SizedBox(
            width: 34,
            child: Center(
                child: Text('$rank',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: rank <= 3
                            ? const Color(0xFFFFA000)
                            : Constants.TEXT_SECONDARY)))),
        title: Text(item['nickname'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isMe ? Constants.PRIMARY_RED : Constants.TEXT_PRIMARY)),
        subtitle: isMe ? const Text('我的最好成绩') : null,
        trailing: Text('${item['rounds']} 轮',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

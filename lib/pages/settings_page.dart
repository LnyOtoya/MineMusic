import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'login_page.dart';

class SettingsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const SettingsPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Map<String, dynamic>> _playHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPlayHistory();
  }

  Future<void> _loadPlayHistory() async {
    final history = await widget.playerService.historyService.getHistory();
    if (mounted) {
      setState(() {
        _playHistory = history;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('账户', [
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('用户名'),
              subtitle: Text(widget.api.username),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
            ListTile(
              leading: const Icon(Icons.cloud_rounded),
              title: const Text('服务器地址'),
              subtitle: Text(
                widget.api.baseUrl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('播放', [
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: const Text('播放历史'),
              subtitle: Text('最近播放 ${_playHistory.length} 首歌曲'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                _showPlayHistory();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded),
              title: const Text('清除播放历史'),
              onTap: () {
                _confirmClearHistory();
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('其他', [
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: const Text('关于'),
              subtitle: const Text('MineMusic v1.0.0'),
              trailing: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _logout,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('退出登录'),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  void _showPlayHistory() {
    if (_playHistory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('暂无播放历史')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('播放历史'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _playHistory.length,
            itemBuilder: (context, index) {
              final song = _playHistory[index];
              return ListTile(
                title: Text(song['title'] ?? '未知歌曲'),
                subtitle: Text(song['artist'] ?? '未知艺人'),
                leading: song['coverArt'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.api.getCoverArtUrl(song['coverArt']),
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 48,
                              height: 48,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note_rounded,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清除播放历史'),
        content: const Text('确定要清除所有播放历史吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              await widget.playerService.clearHistory();
              Navigator.pop(context);
              await _loadPlayHistory();
              setState(() {});
              if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('播放历史已清除')));
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

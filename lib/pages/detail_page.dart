import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';

enum DetailType { album, artist, playlist }

class DetailPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;
  final Map<String, dynamic> item;
  final DetailType type;

  const DetailPage({
    super.key,
    required this.api,
    required this.playerService,
    required this.item,
    required this.type,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  String _totalDuration = "--:--";

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  Future<void> _loadSongs() async {
    switch (widget.type) {
      case DetailType.album:
        _songsFuture = widget.api.getSongsByAlbum(widget.item['id']);
        break;
      case DetailType.artist:
        _songsFuture = widget.api.getSongsByArtist(widget.item['id']);
        break;
      case DetailType.playlist:
        _songsFuture = widget.api.getPlaylistSongs(widget.item['id']);
        break;
    }

    // 计算总时长
    _songsFuture.then((songs) {
      int totalSeconds = 0;
      for (var song in songs) {
        totalSeconds += int.tryParse(song['duration'] ?? '0') ?? 0;
      }
      setState(() {
        _totalDuration = _formatDuration(totalSeconds);
      });
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playSong(Map<String, dynamic> song, List<Map<String, dynamic>> playlist) {
    widget.playerService.playSong(
      song,
      sourceType: widget.type.toString().split('.').last,
      playlist: playlist,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.item['name'] ?? '未知名称';
    final String subtitle = widget.type == DetailType.album
        ? widget.item['artist'] ?? '未知艺术家'
        : widget.type == DetailType.artist
            ? '艺术家作品'
            : '歌单歌曲';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.type == DetailType.album ? '专辑详情' : 
                   widget.type == DetailType.artist ? '艺人详情' : '歌单详情'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('加载失败: ${snapshot.error}'),
                  TextButton(
                    onPressed: () => _loadSongs(),
                    child: const Text('重试'),
                  ),
                ],
              ),
            );
          }





                    // 在 detail_page.dart 的 build 方法中
          if (snapshot.hasData) {
            final songs = snapshot.data ?? [];
            print('${widget.type} 详情页获取到 ${songs.length} 首歌曲');
            
            if (songs.isEmpty) {
              return const Center(
                child: Text('暂无歌曲'),
              );
            }
            
            // 正常显示歌曲列表...
          }


          final songs = snapshot.data ?? [];

          return Column(
            children: [
              // 顶部信息区域
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // 专辑/艺人/歌单图片
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: widget.type == DetailType.album
                          ? const Icon(Icons.album, size: 100)
                          : widget.type == DetailType.artist
                              ? const Icon(Icons.person, size: 100)
                              : const Icon(Icons.playlist_play, size: 100),
                    ),
                    const SizedBox(height: 16),
                    // 标题和信息
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${songs.length} 首歌曲 • 总时长: $_totalDuration',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 歌曲列表
              Expanded(
                child: ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      leading: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      title: Text(
                        song['title'] ?? '未知标题',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        widget.type == DetailType.artist
                            ? '${song['album'] ?? '未知专辑'}'
                            : '${song['artist'] ?? '未知艺术家'}',
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        _formatDuration(int.tryParse(song['duration'] ?? '0') ?? 0),
                      ),
                      onTap: () => _playSong(song, songs),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

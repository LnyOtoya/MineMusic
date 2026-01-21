import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

// 歌曲页面
class SongsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const SongsPage({super.key, required this.api, required this.playerService});

  @override
  State<SongsPage> createState() => _SongsPageState();
}

class _SongsPageState extends State<SongsPage> {
  late Future<List<Map<String, dynamic>>> _songsFuture;
  List<Map<String, dynamic>>? _songs;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  void _loadSongs() {
    setState(() {
      _songsFuture = widget.api.getAllSongsViaSearch().then((songs) {
        // 排序后缓存到变量
        songs.sort((a, b) {
          final titleA = (a['title'] ?? '').toLowerCase();
          final titleB = (b['title'] ?? '').toLowerCase();
          return titleA.compareTo(titleB);
        });
        _songs = songs; // 缓存排序结果
        return songs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            _buildHeader(),
            Expanded(child: _buildSongsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '所有歌曲',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '浏览和播放所有歌曲',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '加载失败',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadSongs,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final songs = snapshot.data ?? [];
        _songs = songs;

        if (songs.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(20),
              height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.music_note_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无歌曲',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: songs.length,
          itemBuilder: (context, index) {
            return _buildSongItem(songs[index], index);
          },
        );
      },
    );
  }

  Widget _buildSongItem(Map<String, dynamic> song, int index) {
    return InkWell(
      onTap: () => _playSong(song),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 歌曲序号
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 封面图
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: song['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                        fit: BoxFit.cover,
                        width: 56,
                        height: 56,
                        placeholder: (context, url) => Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.music_note_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // 歌曲信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '未知标题',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${song['artist'] ?? '未知艺术家'} • ${song['album'] ?? '未知专辑'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 歌曲时长
            Text(
              _formatDuration(song['duration']),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),

            // 更多操作按钮
            Icon(
              Icons.more_vert_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(dynamic duration) {
    if (duration == null) return '--:--';

    int seconds;
    if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    } else if (duration is int) {
      seconds = duration;
    } else {
      return '--:--';
    }

    int minutes = seconds ~/ 60;
    seconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _playSong(Map<String, dynamic> song) {
    print('播放歌曲: ${song['title']}');
    print('🎵 歌曲数据: $song');
    // 获取所有歌曲作为播放列表
    if (_songs != null) {
      // 确保列表已排序并缓存
      widget.playerService.playSong(
        song,
        sourceType: 'songs',
        playlist: _songs, // 传入排序后的列表
      );
    }
  }
}

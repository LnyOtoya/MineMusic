import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/error_handler_service.dart';
import '../utils/app_fonts.dart';
import '../widgets/animated_list_item.dart';

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
            _buildHeader(),
            Expanded(child: _buildSongsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = '所有歌曲';
    final subtitle = '浏览和播放所有歌曲';
    
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppFonts.getTextStyle(
                  text: title,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppFonts.getTextStyle(
              text: subtitle,
              fontSize: 18,
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
          cacheExtent: 500,
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return _buildSongItem(song, index);
          },
        );
      },
    );
  }

  Widget _buildSongItem(Map<String, dynamic> song, int index) {
    final coverArtUrl = song['coverArt'] != null ? widget.api.getCoverArtUrl(song['coverArt']) : null;
    final title = song['title'] ?? '未知标题';
    final artist = song['artist'] ?? '未知艺术家';
    final album = song['album'] ?? '未知专辑';
    final subtitle = '$artist • $album';

    return AnimatedListItem(
      index: index,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _playSong(song),
            onLongPress: () => _showSongMenu(song),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                      child: coverArtUrl != null
                          ? CachedNetworkImage(
                              imageUrl: coverArtUrl,
                              fit: BoxFit.cover,
                              width: 48,
                              height: 48,
                              placeholder: (context, url) => _buildMusicNoteIcon(context),
                              errorWidget: (context, url, error) => _buildMusicNoteIcon(context),
                            )
                          : _buildMusicNoteIcon(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 构建音乐图标，避免重复创建
  Widget _buildMusicNoteIcon(BuildContext context) {
    return Icon(
      Icons.music_note_rounded,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  void _showSongMenu(Map<String, dynamic> song) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.playlist_add_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('加入歌单'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddToPlaylistDialog(song);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('下载'),
                onTap: () {
                  Navigator.pop(context);
                  // 未来实现下载逻辑
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.skip_next_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('下一曲播放'),
                onTap: () {
                  Navigator.pop(context);
                  // 未来实现下一曲播放逻辑
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(
                  Icons.close_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: const Text('取消'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
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

  // 显示添加到歌单对话框
  void _showAddToPlaylistDialog(Map<String, dynamic> song) async {
    try {
      List<Map<String, dynamic>> playlists = await widget.api.getPlaylists();
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('加入歌单'),
            content: SizedBox(
              height: 300,
              width: double.maxFinite,
              child: ListView.builder(
                itemCount: playlists.length,
                itemBuilder: (context, index) {
                  final playlist = playlists[index];
                  return ListTile(
                    title: Text(playlist['name'] ?? '未知歌单'),
                    subtitle: Text('歌曲数: ${playlist['songCount'] ?? 0}'),
                    onTap: () async {
                      Navigator.pop(context);
                      // 将歌曲添加到歌单
                      try {
                        bool success = await widget.api.addSongToPlaylist(
                          playlist['id'],
                          song['id'],
                        );
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('歌曲已添加到歌单 "${playlist['name']}"'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('添加歌曲到歌单失败')),
                          );
                        }
                      } catch (e) {
                        ErrorHandlerService().handleApiError(context, e, 'addSongToPlaylist');
                      }
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ErrorHandlerService().handleApiError(context, e, 'getPlaylists');
    }
  }
}

import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/error_handler_service.dart';

// 歌单页面
class PlaylistsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const PlaylistsPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;
  static List<Map<String, dynamic>>? _cachedPlaylists;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = _loadPlaylistsWithCover();
    });
  }

  Future<List<Map<String, dynamic>>> _loadPlaylistsWithCover() async {
    try {
      final playlists = await widget.api.getPlaylists();

      List<Map<String, dynamic>> playlistsWithCover = [];

      for (var playlist in playlists) {
        String? coverArt;
        try {
          final songs = await widget.api.getPlaylistSongs(playlist['id']);
          if (songs.isNotEmpty && songs[0]['coverArt'] != null) {
            coverArt = songs[0]['coverArt'];
          }
        } catch (e) {
          print('获取歌单 ${playlist['name']} 的歌曲失败: $e');
        }

        playlistsWithCover.add({...playlist, 'coverArt': coverArt});
      }

      _cachedPlaylists = playlistsWithCover;
      return playlistsWithCover;
    } catch (e) {
      ErrorHandlerService().handleApiError(context, e, 'getPlaylists');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildPlaylistsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 64, 20, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '我的歌单',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showCreatePlaylistDialog();
                },
                icon: Icon(
                  Icons.add_rounded,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '浏览和管理你的歌单',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _playlistsFuture,
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
                      onPressed: _loadPlaylists,
                      child: const Text('重试'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final playlists = snapshot.data ?? [];

        if (playlists.isEmpty) {
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
                      Icons.playlist_play_rounded,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '暂无歌单',
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

        // 按歌单名称字母顺序排序
        playlists.sort((a, b) {
          final nameA = (a['name'] ?? '').toLowerCase();
          final nameB = (b['name'] ?? '').toLowerCase();
          return nameA.compareTo(nameB);
        });

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: playlists.length,
          itemBuilder: (context, index) {
            final playlist = playlists[index];
            return RepaintBoundary(
              child: _buildPlaylistCard(playlist),
            );
          },
        );
      },
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    final coverArtUrl = playlist['coverArt'] != null ? widget.api.getCoverArtUrl(playlist['coverArt']) : null;
    final name = playlist['name'] ?? '未知歌单';
    final songCount = playlist['songCount'] ?? 0;
    final comment = playlist['comment'];

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _openPlaylistDetail(playlist),
        onLongPress: () => _showDeletePlaylistDialog(playlist),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Container(
                  width: double.infinity,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                  child: coverArtUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverArtUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 140,
                          placeholder: (context, url) => _buildPlaylistIcon(context),
                          errorWidget: (context, url, error) => _buildPlaylistIcon(context),
                        )
                      : _buildPlaylistIcon(context),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '歌曲数: $songCount',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (comment != null && comment.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          comment,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 构建播放列表图标，避免重复创建
  Widget _buildPlaylistIcon(BuildContext context) {
    return Icon(
      Icons.playlist_play_rounded,
      size: 56,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  void _openPlaylistDetail(Map<String, dynamic> playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPage(
          api: widget.api,
          playerService: widget.playerService,
          item: playlist,
          type: DetailType.playlist,
          onPlaylistUpdated: () {
            // 歌单更新后，重新加载歌单列表
            _cachedPlaylists = null;
            _loadPlaylists();
          },
        ),
      ),
    );
  }

  // 显示创建歌单对话框
  void _showCreatePlaylistDialog() {
    TextEditingController nameController = TextEditingController();
    TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('创建歌单'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '歌单名称',
                  hintText: '请输入歌单名称',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: '歌单注释',
                  hintText: '请输入歌单注释（可选）',
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                String name = nameController.text.trim();
                String comment = commentController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('歌单名称不能为空')));
                  return;
                }

                // 创建歌单
                bool success = await widget.api.createPlaylist(
                  name,
                  [],
                  comment: comment,
                );
                if (success) {
                  // 重新加载歌单
                  widget.api.clearPlaylistCache();
                  _cachedPlaylists = null;
                  _loadPlaylists();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('歌单 "$name" 创建成功')));
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('歌单创建失败')));
                }
              },
              child: const Text('创建'),
            ),
          ],
        );
      },
    );
  }

  // 显示删除歌单对话框
  void _showDeletePlaylistDialog(Map<String, dynamic> playlist) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除歌单'),
          content: Text('确定要删除歌单 "${playlist['name']}" 吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool success = await widget.api.deletePlaylist(playlist['id']);
                if (success) {
                  // 重新加载歌单
                  widget.api.clearPlaylistCache();
                  _cachedPlaylists = null;
                  _loadPlaylists();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('歌单 "${playlist['name']}" 删除成功')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('歌单删除失败')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.error.withOpacity(0.8),
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }
}

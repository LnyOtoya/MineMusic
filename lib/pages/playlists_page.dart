import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import 'detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    if (_cachedPlaylists != null) {
      return _cachedPlaylists!;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 64),
            _buildHeader(),
            Expanded(child: _buildPlaylistsList()),
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
            '我的歌单',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
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
            return _buildPlaylistCard(playlists[index]);
          },
        );
      },
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist) {
    return InkWell(
      onTap: () => _openPlaylistDetail(playlist),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
                child: playlist['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(
                          playlist['coverArt'],
                        ),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 160,
                        placeholder: (context, url) => Icon(
                          Icons.playlist_play_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.playlist_play_rounded,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    : Icon(
                        Icons.playlist_play_rounded,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['name'] ?? '未知歌单',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '歌曲数: ${playlist['songCount'] ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (playlist['comment'] != null &&
                      playlist['comment']!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      playlist['comment']!,
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
          ],
        ),
      ),
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
        ),
      ),
    );
  }
}

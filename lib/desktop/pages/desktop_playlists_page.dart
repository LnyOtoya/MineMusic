import 'package:flutter/material.dart';
import '../../services/subsonic_api.dart';
import '../../services/player_service.dart';
import '../../pages/detail_page.dart';

class DesktopPlaylistsPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const DesktopPlaylistsPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<DesktopPlaylistsPage> createState() => _DesktopPlaylistsPageState();
}

class _DesktopPlaylistsPageState extends State<DesktopPlaylistsPage> {
  late Future<List<Map<String, dynamic>>> _playlistsFuture;

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  void _loadPlaylists() {
    setState(() {
      _playlistsFuture = widget.api.getPlaylists();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildPlaylistsGrid(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '播放列表',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '管理你的播放列表',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        FilledButton.icon(
          onPressed: _showCreatePlaylistDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('创建播放列表'),
        ),
      ],
    );
  }

  Widget _buildPlaylistsGrid() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _playlistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 400,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            height: 400,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text('加载失败'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadPlaylists,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          );
        }

        final playlists = snapshot.data ?? [];
        if (playlists.isEmpty) {
          return Container(
            height: 400,
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
                  Text('暂无播放列表'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _showCreatePlaylistDialog,
                    child: const Text('创建第一个播放列表'),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1,
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
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
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
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Icon(
                  Icons.playlist_play_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist['name'] ?? '未知播放列表',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${playlist['songCount'] ?? 0} 首歌曲',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final nameController = TextEditingController();
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('创建播放列表'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '输入播放列表名称',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '输入播放列表描述',
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final comment = commentController.text.trim();

              if (name.isEmpty) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('请输入播放列表名称')));
                return;
              }

              final success = await widget.api.createPlaylist(
                name,
                [],
                comment: comment.isNotEmpty ? comment : null,
              );

              if (success && mounted) {
                Navigator.pop(context);
                setState(() {
                  _playlistsFuture = widget.api.getPlaylists();
                });
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('播放列表创建成功')));
              } else if (mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('播放列表创建失败')));
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}

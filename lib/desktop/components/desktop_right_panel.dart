import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/subsonic_api.dart';
import '../../services/player_service.dart';

class DesktopRightPanel extends StatelessWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const DesktopRightPanel({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final currentSong = playerService.currentSong;
    final sourceType = playerService.sourceType;
    final playlist = playerService.currentPlaylist;
    final currentIndex = playerService.currentIndex;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          left: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Top section: Current song info
          if (currentSong != null)
            _buildCurrentSongInfo(context, currentSong, sourceType),

          // Bottom section: Playlist
          Expanded(child: _buildPlaylist(context, playlist, currentIndex)),
        ],
      ),
    );
  }

  Widget _buildCurrentSongInfo(
    BuildContext context,
    Map<String, dynamic> song,
    String sourceType,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Source type
          Text(
            _getSourceTypeText(sourceType),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 16),

          // Artist avatar
          _buildArtistAvatar(context, song),

          const SizedBox(height: 12),

          // Song title and artist name
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song['title'] ?? '未知歌曲',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                song['artist'] ?? '未知艺术家',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Divider
          Divider(
            color: Theme.of(context).colorScheme.outlineVariant,
            thickness: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildArtistAvatar(BuildContext context, Map<String, dynamic> song) {
    final artistName = song['artist'] as String?;

    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: artistName != null && artistName != '未知艺术家'
            ? FutureBuilder<String?>(
                future: _getArtistAvatarUrl(artistName, song['title']),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.network(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultAvatar(context);
                      },
                    );
                  }
                  return _buildDefaultAvatar(context);
                },
              )
            : _buildDefaultAvatar(context),
      ),
    );
  }

  Widget _buildDefaultAvatar(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.person_rounded,
        size: 128,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Future<String?> _getArtistAvatarUrl(
    String artistName,
    String? songTitle,
  ) async {
    try {
      final avatarUrl = await api.getArtistAvatar(
        artistName,
        songTitle: songTitle,
      );
      return avatarUrl;
    } catch (e) {
      print('获取歌手头像失败: $e');
    }
    return null;
  }

  String _getSourceTypeText(String sourceType) {
    switch (sourceType) {
      case 'album':
        return '来自专辑';
      case 'artist':
        return '来自艺术家';
      case 'playlist':
        return '来自播放列表';
      case 'random':
        return '随机播放';
      case 'search':
        return '来自搜索';
      case 'similar':
        return '相似歌曲';
      default:
        return '来自单曲';
    }
  }

  Widget _buildPlaylist(
    BuildContext context,
    List<Map<String, dynamic>> playlist,
    int currentIndex,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Playlist title with "Open Queue" button
          Row(
            children: [
              Icon(
                Icons.queue_music_rounded,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '当前播放列表',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${playlist.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _showFullPlaylist(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  textStyle: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text('打开队列'),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Playlist items (limited to 5 songs)
          Expanded(
            child: playlist.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_off_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '播放列表为空',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: playlist.length > 5 ? 5 : playlist.length,
                    itemBuilder: (context, index) {
                      final song = playlist[index];
                      final isCurrentSong = index == currentIndex;

                      return _buildPlaylistItem(
                        context,
                        song,
                        isCurrentSong,
                        index,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showFullPlaylist(BuildContext context) {
    final playlist = playerService.currentPlaylist;
    final currentIndex = playerService.currentIndex;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.queue_music_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              '完整播放列表',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${playlist.length} 首歌',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          height: 560,
          child: playlist.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_off_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '播放列表为空',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: playlist.length,
                  itemBuilder: (context, index) {
                    final song = playlist[index];
                    final isCurrentSong = index == currentIndex;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrentSong
                            ? Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // Song number or playing indicator
                          SizedBox(
                            width: 32,
                            child: isCurrentSong && playerService.isPlaying
                                ? Icon(
                                    Icons.equalizer_rounded,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  )
                                : Text(
                                    '${index + 1}',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: isCurrentSong
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.primary
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                          ),

                          const SizedBox(width: 12),

                          // Album art
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: song['coverArt'] != null
                                  ? Image.network(
                                      api.getCoverArtUrl(song['coverArt']),
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Icon(
                                              Icons.music_note_rounded,
                                              size: 24,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            );
                                          },
                                    )
                                  : Icon(
                                      Icons.music_note_rounded,
                                      size: 24,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Song info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song['title'] ?? '未知歌曲',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: isCurrentSong
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isCurrentSong
                                            ? Theme.of(
                                                context,
                                              ).colorScheme.primary
                                            : Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  song['artist'] ?? '未知艺术家',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Duration
                          if (song['duration'] != null)
                            Text(
                              _formatDuration(
                                int.tryParse(song['duration'].toString()) ?? 0,
                              ),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistItem(
    BuildContext context,
    Map<String, dynamic> song,
    bool isCurrentSong,
    int index,
  ) {
    return InkWell(
      onTap: () {
        playerService.playSongAt(index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Song number or playing indicator
            SizedBox(
              width: 24,
              child: isCurrentSong && playerService.isPlaying
                  ? Icon(
                      Icons.equalizer_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrentSong
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // Album art
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: song['coverArt'] != null
                    ? Image.network(
                        api.getCoverArtUrl(song['coverArt']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.music_note_rounded,
                            size: 20,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          );
                        },
                      )
                    : Icon(
                        Icons.music_note_rounded,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
              ),
            ),

            const SizedBox(width: 12),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song['title'] ?? '未知歌曲',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentSong
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isCurrentSong
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song['artist'] ?? '未知艺术家',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration
            if (song['duration'] != null)
              Text(
                _formatDuration(int.tryParse(song['duration'].toString()) ?? 0),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

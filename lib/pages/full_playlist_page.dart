import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';

class FullPlaylistPage extends StatefulWidget {
  final List<Map<String, dynamic>> playlist;
  final int currentIndex;
  final PlayerService playerService;
  final SubsonicApi api;

  const FullPlaylistPage({
    super.key,
    required this.playlist,
    required this.currentIndex,
    required this.playerService,
    required this.api,
  });

  @override
  State<FullPlaylistPage> createState() => _FullPlaylistPageState();
}

class _FullPlaylistPageState extends State<FullPlaylistPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('播放列表'),
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.playlist.length,
        itemBuilder: (context, index) {
          final song = widget.playlist[index];
          final isCurrent = index == widget.currentIndex;

          return _buildPlaylistSongItem(song, index, isCurrent);
        },
      ),
    );
  }

  Widget _buildPlaylistSongItem(
    Map<String, dynamic> song,
    int index,
    bool isCurrent,
  ) {
    // 计算圆角
    BorderRadius borderRadius;
    bool isFirst = index == 0;
    bool isLast = index == widget.playlist.length - 1;
    
    if (isFirst && isLast) {
      // 只有一项
      borderRadius = BorderRadius.circular(12);
    } else if (isFirst) {
      // 第一项
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
        bottomLeft: Radius.circular(0),
        bottomRight: Radius.circular(0),
      );
    } else if (isLast) {
      // 最后一项
      borderRadius = const BorderRadius.only(
        topLeft: Radius.circular(0),
        topRight: Radius.circular(0),
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      );
    } else {
      // 中间项
      borderRadius = BorderRadius.zero;
    }

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 0,
        bottom: isLast ? 0 : 0,
      ),
      decoration: BoxDecoration(
        color: isCurrent 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
        border: isFirst || isLast
            ? null
            : Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
              ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: song['coverArt'] != null
              ? CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  placeholderFadeInDuration: Duration(milliseconds: 200),
                  fadeInDuration: Duration(milliseconds: 300),
                  placeholder: (context, url) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 56,
                    height: 56,
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                )
              : Container(
                  width: 56,
                  height: 56,
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
        ),
        title: Text(
          song['title'] ?? '未知标题',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
            color: isCurrent 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          song['artist'] ?? '未知艺术家',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onTap: () {
          if (!isCurrent) {
            widget.playerService.playSongAt(index);
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;

  const MiniPlayer({super.key, required this.playerService, required this.api});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 1), // 从底部开始（隐藏）
          end: Offset.zero, // 移动到正常位置（显示）
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    // 监听播放状态变化
    widget.playerService.addListener(_onPlayerStateChanged);
    PlayerService.colorSchemeNotifier.addListener(_onColorSchemeChanged);
    // 初始检查状态
    _onPlayerStateChanged();
  }

  void _onPlayerStateChanged() {
    if (widget.playerService.currentSong != null) {
      if (!_isVisible) {
        // 有歌曲且播放器未显示时，显示播放器
        _showPlayer();
      }
    } else {
      if (_isVisible) {
        // 没有歌曲且播放器显示时，隐藏播放器
        _hidePlayer();
      }
    }
    // 强制刷新UI
    if (mounted) {
      setState(() {});
    }
  }

  void _showPlayer() {
    if (mounted) {
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  void _hidePlayer() {
    _animationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isVisible = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    widget.playerService.removeListener(_onPlayerStateChanged);
    PlayerService.colorSchemeNotifier.removeListener(_onColorSchemeChanged);
    super.dispose();
  }

  void _onColorSchemeChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _triggerHapticFeedback() {
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink(); // 不显示时占用零空间
    }

    return SlideTransition(
      position: _slideAnimation,
      child: _buildPlayerContent(),
    );
  }

  Widget _buildPlayerContent() {
    final dynamicColorScheme = widget.playerService.currentColorScheme;
    final effectiveColorScheme = dynamicColorScheme ?? Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 72,
      decoration: BoxDecoration(
        color: effectiveColorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _onPlayerTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildLeftSection(effectiveColorScheme),
                const Spacer(),
                _buildControlSection(effectiveColorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget _buildLeftSection() {
  //   final song = widget.playerService.currentSong;
  //   if (song == null) return const SizedBox();

  //   return Row(
  //     children: [
  //       // 歌曲封面
  //       Container(
  //         width: 48,
  //         height: 48,
  //         decoration: BoxDecoration(
  //           color: Theme.of(context).colorScheme.primaryContainer,
  //           borderRadius: BorderRadius.circular(8),
  //         ),
  //         child: Icon(
  //           Icons.music_note,
  //           color: Theme.of(context).colorScheme.onPrimaryContainer,
  //           size: 24,
  //         ),
  //       ),

  //       const SizedBox(width: 12),

  //       // 歌曲信息 - 限制最大宽度
  //       ConstrainedBox(
  //         constraints: const BoxConstraints(maxWidth: 160),
  //         child: _buildSongInfo(),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildLeftSection(ColorScheme colorScheme) {
    final song = widget.playerService.currentSong;
    if (song == null) return const SizedBox();

    return Row(
      children: [
        // 歌曲封面 - 使用Cached图片或默认图标
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: song['coverArt'] != null
                ? CachedNetworkImage(
                    imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Icon(
                      Icons.music_note_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.music_note_rounded,
                      color: colorScheme.onSurfaceVariant,
                      size: 22,
                    ),
                  )
                : Icon(
                    Icons.music_note_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
          ),
        ),

        const SizedBox(width: 10),

        // 歌曲信息 - 限制最大宽度
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 140),
          child: _buildSongInfo(),
        ),
      ],
    );
  }

  Widget _buildSongInfo() {
    final song = widget.playerService.currentSong;
    if (song == null) return const SizedBox();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey(song['id']), // 使用歌曲ID作为唯一标识
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 歌名 - 使用省略号
          _buildSongTitle(song['title'] ?? '未知歌曲'),

          const SizedBox(height: 2),

          // 来源信息
          Text(
            _getSourceInfo(song),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // 构建歌名显示
  Widget _buildSongTitle(String title) {
    const maxLength = 7;

    String displayTitle = title.length > maxLength
        ? '${title.substring(0, maxLength)}...'
        : title;

    return Text(
      displayTitle,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getSourceInfo(Map<String, dynamic> song) {
    switch (widget.playerService.sourceType) {
      case 'album':
        return '专辑';
      case 'playlist':
        return '歌单';
      case 'artist':
        return '艺人';
      case 'random':
        return '随机歌曲';
      case 'random_album':
        return '随机专辑';
      case 'search':
        return '搜索结果';
      case 'similar':
        return '相似歌曲';
      case 'recommended':
        return '推荐歌曲';
      case 'song':
        return '歌曲';
      case 'newest':
        return '最新专辑';
      case 'history':
        return '最近常听';
      default:
        return '播放中';
    }
  }

  Widget _buildControlSection(ColorScheme colorScheme) {
    return Row(
      children: [
        // 上一曲按钮
        IconButton(
          icon: Icon(
            Icons.skip_previous_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            _triggerHapticFeedback();
            widget.playerService.previousSong();
          },
          iconSize: 24,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),

        // 播放/暂停按钮
        Container(
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              widget.playerService.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              color: colorScheme.onPrimary,
            ),
            onPressed: () {
              _triggerHapticFeedback();
              widget.playerService.togglePlayPause();
            },
            iconSize: 20,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ),

        // 下一曲按钮
        IconButton(
          icon: Icon(
            Icons.skip_next_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            _triggerHapticFeedback();
            widget.playerService.nextSong();
          },
          iconSize: 24,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),

        // 歌曲列表按钮
        IconButton(
          icon: Icon(
            Icons.queue_music_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            _triggerHapticFeedback();
            _showPlaylistBottomSheet();
          },
          iconSize: 24,
          padding: const EdgeInsets.all(2),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(backgroundColor: Colors.transparent),
        ),
      ],
    );
  }

  void _onPlayerTap() {
  }

  void _showPlaylistBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              color: Colors.transparent,
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.4, 0.6, 0.9],
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Text(
                          '播放列表',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.playerService.playlist.length} 首歌曲',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: widget.playerService.playlist.length,
                      itemBuilder: (context, index) {
                        final song = widget.playerService.playlist[index];
                        final isCurrentSong =
                            widget.playerService.currentSong?['id'] == song['id'];

                        return ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: song['coverArt'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl: widget.api.getCoverArtUrl(
                                        song['coverArt'],
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(
                                    Icons.music_note_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                          ),
                          title: Text(
                            song['title'] ?? '未知歌曲',
                            style: TextStyle(
                              fontWeight: isCurrentSong
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isCurrentSong
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                          ),
                          subtitle: Text(
                            song['artist'] ?? '未知艺术家',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isCurrentSong
                              ? Icon(
                                  Icons.equalizer_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                )
                              : null,
                          onTap: () {
                            widget.playerService.playSongAt(index);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // void _onPlayerTap() {
  //   // 点击播放栏跳转到完整播放页面
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Text('跳转到播放页面'),
  //       duration: Duration(seconds: 1),
  //     ),
  //   );
  // }
}

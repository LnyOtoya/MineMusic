import 'package:flutter/material.dart';
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

class _MiniPlayerState extends State<MiniPlayer> with SingleTickerProviderStateMixin {
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
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1), // 从底部开始（隐藏）
      end: Offset.zero, // 移动到正常位置（显示）
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    // 监听播放状态变化
    widget.playerService.addListener(_onPlayerStateChanged);
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
    super.dispose();
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
    return Container(
      margin: const EdgeInsets.all(8),
      height: 64,  // 固定高度
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _onPlayerTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildLeftSection(),
                const Spacer(),
                _buildControlSection(),
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


  Widget _buildLeftSection() {
    final song = widget.playerService.currentSong;
    if (song == null) return const SizedBox();
    
    return Row(
      children: [
        // 歌曲封面 - 使用Cached图片或默认图标
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: song['coverArt'] != null
              ? CachedNetworkImage(
                  imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                )
              : Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 24,
                ),
        ),
        
        const SizedBox(width: 12),
        
        // 歌曲信息 - 限制最大宽度
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
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
    const maxLength = 20;
    
    if (title.length <= maxLength) {
      return Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    
    // 长歌名使用省略号显示
    return Text(
      title,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _getSourceInfo(Map<String, dynamic> song) {
    switch (widget.playerService.sourceType) {
      case 'album':
        return '专辑 • ${song['album'] ?? '未知专辑'}';
      case 'playlist':
        return '歌单 • ${song['album'] ?? '未知歌单'}';
      case 'artist':
        return '艺人 • ${song['artist'] ?? '未知艺人'}';
      case 'random':
        return '随机播放';
      case 'search':
        return '搜索结果';
      case 'recommendation':
        return '推荐';
      case 'song':
      default:
        return song['artist'] ?? '未知艺术家';
    }
  }

  Widget _buildControlSection() {
    return Row(
      children: [
        // 上一曲按钮
        IconButton(
          icon: Icon(
            Icons.skip_previous,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            widget.playerService.previousSong();
          },
          iconSize: 24,
          padding: const EdgeInsets.all(4),
        ),
        
        // 播放/暂停按钮
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              widget.playerService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: widget.playerService.togglePlayPause,
            iconSize: 20,
            padding: const EdgeInsets.all(8),
          ),
        ),
        
        // 下一曲按钮
        IconButton(
          icon: Icon(
            Icons.skip_next,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () {
            widget.playerService.nextSong();
          },
          iconSize: 24,
          padding: const EdgeInsets.all(4),
        ),
      ],
    );
  }

  void _onPlayerTap() {
    // 点击播放栏跳转到完整播放页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('跳转到播放页面'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

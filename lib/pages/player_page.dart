import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import 'package:marquee/marquee.dart';

class PlayerPage extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;

  const PlayerPage({
    super.key,
    required this.playerService,
    required this.api,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _albumRotation;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // 初始化专辑封面旋转动画
    // _animationController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 20),
    // );
    // _albumRotation = CurvedAnimation(
    //   parent: _animationController,
    //   curve: Curves.linear,
    // );

    // 监听播放状态变化
    widget.playerService.addListener(_updatePlayerState);
    _updatePlayerState(); // 初始状态更新
  }

  @override
  void dispose() {
    // _animationController.dispose();
    widget.playerService.removeListener(_updatePlayerState);
    super.dispose();
  }

  // 更新播放器状态
  void _updatePlayerState() {
    setState(() {
      _isPlaying = widget.playerService.isPlaying;
      _currentPosition = widget.playerService.currentPosition;
      _totalDuration = widget.playerService.totalDuration;
    });

    // 控制专辑封面旋转
    // if (_isPlaying) {
    //   _animationController.repeat();
    // } else {
    //   _animationController.stop();
    // }
  }

  // 格式化时长显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // 获取播放来源文本
  String _getSourceText() {
    switch (widget.playerService.sourceType) {
      case 'album':
        return '专辑';
      case 'playlist':
        return '歌单';
      case 'artist':
        return '艺人';
      case 'random':
        return '随机播放';
      case 'search':
        return '搜索结果';
      case 'recommendation':
        return '推荐';
      default:
        return '音乐库';
    }
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.playerService.currentSong;
    if (song == null) {
      return const Scaffold(
        body: Center(child: Text('没有正在播放的歌曲')),
      );
    }

    return Scaffold(
      // 使用主题背景色
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部区域
            _buildTopBar(song),
            
            // 中间封面区域
            Expanded(
              child: _buildAlbumCover(song),
            ),
            
            // 底部控制区域
            _buildControlPanel(song),
          ],
        ),
      ),
    );
  }

  // 顶部区域
  Widget _buildTopBar(Map<String, dynamic> song) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 退出按钮
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          
          // 来源和歌名
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getSourceText(),
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              // Text(
              //   song['title'] ?? '未知歌曲',
              //   style: Theme.of(context).textTheme.titleMedium?.copyWith(
              //     color: Theme.of(context).colorScheme.onSurface,
              //     fontWeight: FontWeight.w600,
              //   ),
              //   overflow: TextOverflow.ellipsis,
              // ),
            ],
          ),
          
          // 更多操作
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              // 暂不实现功能
            },
          ),
        ],
      ),
    );
  }

  // 专辑封面区域
  Widget _buildAlbumCover(Map<String, dynamic> song) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: song['coverArt'] != null
                ? CachedNetworkImage(
                    imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildDefaultCover(),
                    errorWidget: (context, url, error) => _buildDefaultCover(),
                  )
                : _buildDefaultCover(),
          ),
        ),
      ),
    );
  }

  // 默认封面
  Widget _buildDefaultCover() {
    return Container(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        Icons.music_note,
        size: 80,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  // 底部控制区域
  Widget _buildControlPanel(Map<String, dynamic> song) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      // decoration: BoxDecoration(
      //   color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      //   borderRadius: const BorderRadius.vertical(
      //     top: Radius.circular(24),
      //   ),
      // ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 歌曲信息和进度条
          Column(
            children: [
              // 歌曲名和艺术家
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? '未知歌曲',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song['artist'] ?? '未知艺术家',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              
              // 进度条
              Column(
                children: [
                  Slider(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    value: _currentPosition.inMilliseconds.toDouble(),
                    max: _totalDuration.inMilliseconds.toDouble(),
                    min: 0,
                    activeColor: Theme.of(context).colorScheme.primary,
                    inactiveColor: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                    onChanged: (value) {
                      widget.playerService.seekTo(Duration(milliseconds: value.toInt()));
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          _formatDuration(_totalDuration),
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          // 控制按钮
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                //随机播放
                IconButton(
                  icon: Icon(
                    Icons.shuffle,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 36,
                  ),
                  onPressed: () {

                  },
                ),



                // 上一曲
                IconButton(
                  icon: Icon(
                    Icons.skip_previous,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 36,
                  ),
                  onPressed: () => widget.playerService.previousSong(),
                ),
                
                // 播放/暂停
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 32,
                    ),
                    onPressed: () => widget.playerService.togglePlayPause(),
                  ),
                ),
                
                // 下一曲
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 36,
                  ),
                  onPressed: () => widget.playerService.nextSong(),
                ),
                
                // 歌词按钮
                IconButton(
                  icon: Icon(
                    Icons.lyrics_rounded,
                    color: Theme.of(context).colorScheme.onSurface,
                    size: 28,
                  ),
                  onPressed: () {
                    // 暂不实现功能
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

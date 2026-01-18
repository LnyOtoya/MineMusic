import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import '../services/lyrics_api.dart';
import '../models/lyrics_api_type.dart';

class PlayerPage extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;
  final LyricsApiType? lyricsApiType;

  const PlayerPage({
    super.key,
    required this.playerService,
    required this.api,
    this.lyricsApiType,
  });

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _albumRotation;
  late AnimationController _playButtonController;
  late Animation<double> _playButtonScale;
  late AnimationController _shapeAnimationController;
  late Animation<double> _shapeAnimation;
  bool _isPlaying = false;
  bool _wasPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String _lrcLyrics = '';
  bool _isLoadingLyrics = false;
  late LyricController _lyricController;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  String? _currentSongId;

  final LyricsApi _lyricsApi = LyricsApi();

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

    // 初始化播放按钮动画
    _playButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _playButtonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _playButtonController, curve: Curves.easeInOut),
    );

    // 初始化形状过渡动画
    _shapeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _shapeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _shapeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 初始化歌词控制器
    _lyricController = LyricController();

    // 监听播放状态变化
    widget.playerService.addListener(_updatePlayerState);
    _updatePlayerState(); // 初始状态更新

    // 加载当前歌曲歌词
    _loadLyrics();
  }

  @override
  void dispose() {
    // _animationController.dispose();
    _playButtonController.dispose();
    _shapeAnimationController.dispose();

    _pageController.dispose();
    _lyricController.dispose();

    widget.playerService.removeListener(_updatePlayerState);
    super.dispose();
  }

  // 加载歌词
  Future<void> _loadLyrics() async {
    final song = widget.playerService.currentSong;
    if (song == null) return;

    final lyricsApiType = widget.lyricsApiType ?? LyricsApiType.disabled;

    if (lyricsApiType == LyricsApiType.disabled) {
      print('🚫 歌词功能已关闭');
      setState(() {
        _lrcLyrics = '';
      });
      return;
    }

    setState(() => _isLoadingLyrics = true);

    try {
      final title = song['title'] ?? '';
      final artist = song['artist'] ?? '';

      print('🎵 开始加载歌词: $title - $artist');
      print('📡 使用API: ${lyricsApiType.displayName}');

      if (lyricsApiType == LyricsApiType.thirdParty) {
        final lrcLyrics = await _lyricsApi.getLyricsByKeyword(title, artist);

        if (lrcLyrics.isNotEmpty) {
          print('✅ 从第三方API获取到歌词');
          setState(() {
            _lrcLyrics = lrcLyrics;
            _lyricController.loadLyric(lrcLyrics);
          });
          return;
        }

        print('⚠️ 第三方API未找到歌词');
      }

      if (lyricsApiType == LyricsApiType.subsonic) {
        final lyricData = await widget.api.getLyrics(
          artist: artist,
          title: title,
        );

        if (lyricData != null && lyricData['text'].isNotEmpty) {
          print('✅ 从Subsonic/Navidrome获取到歌词');
          final lyricsText = lyricData['text'];
          setState(() {
            _lrcLyrics = lyricsText;
            _lyricController.loadLyric(lyricsText);
          });
          return;
        }

        print('⚠️ Subsonic/Navidrome未找到歌词');
      }

      print('⚠️ 未找到歌词');
      setState(() {
        _lrcLyrics = '';
      });
    } catch (e) {
      print('❌ 加载歌词失败: $e');
      setState(() {
        _lrcLyrics = '';
      });
    } finally {
      setState(() => _isLoadingLyrics = false);
    }
  }

  // 更新播放器状态
  void _updatePlayerState() {
    final newIsPlaying = widget.playerService.isPlaying;
    final currentSong = widget.playerService.currentSong;
    final newSongId = currentSong?['id']?.toString();

    // 检测歌曲是否切换
    if (newSongId != null && newSongId != _currentSongId) {
      _currentSongId = newSongId;

      // 重置播放位置，避免进度条超出范围
      setState(() {
        _currentPosition = Duration.zero;
        _totalDuration = widget.playerService.totalDuration;
      });

      // 重新加载歌词
      _loadLyrics();
    }

    // 检测播放状态变化
    if (newIsPlaying != _isPlaying) {
      _wasPlaying = _isPlaying;
      _isPlaying = newIsPlaying;

      // 触发形状过渡动画
      if (_isPlaying) {
        _shapeAnimationController.forward();
      } else {
        _shapeAnimationController.reverse();
      }
    }

    // 获取新的播放位置和总时长
    final newPosition = widget.playerService.currentPosition;
    final newTotalDuration = widget.playerService.totalDuration;

    // 确保播放位置不超过总时长，避免进度条超出范围
    final safePosition = newPosition > newTotalDuration
        ? newTotalDuration
        : newPosition;

    setState(() {
      _currentPosition = safePosition;
      _totalDuration = newTotalDuration;
    });

    // 同步歌词进度
    if (_lrcLyrics.isNotEmpty) {
      _lyricController.setProgress(_currentPosition);
    }

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

  // 线性插值函数
  double _lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
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

  // @override
  // Widget build(BuildContext context) {
  //   final song = widget.playerService.currentSong;
  //   if (song == null) {
  //     return const Scaffold(
  //       body: Center(child: Text('没有正在播放的歌曲')),
  //     );
  //   }

  //   return Scaffold(
  //     // 使用主题背景色
  //     backgroundColor: Theme.of(context).colorScheme.surface,
  //     body: SafeArea(
  //       child: Column(
  //         children: [
  //           // 顶部区域
  //           _buildTopBar(song),

  //           // 中间封面区域
  //           Expanded(
  //             child: _buildAlbumCover(song),
  //           ),

  //           // 底部控制区域
  //           _buildControlPanel(song),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final song = widget.playerService.currentSong;
    if (song == null) {
      return const Scaffold(body: Center(child: Text('没有正在播放的歌曲')));
    }

    return Scaffold(
      // 保留主题背景色设置
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) => setState(() => _currentPage = index),
        children: [
          // 原始播放页面 - 整合原有布局
          SafeArea(
            child: Column(
              children: [
                // 顶部区域
                _buildTopBar(song),

                // 中间封面区域
                Expanded(child: _buildAlbumCover(song)),

                // 底部控制区域
                _buildControlPanel(song),
              ],
            ),
          ),
          // 歌词页面
          _buildLyricsPage(),
        ],
      ),
    );
  }

  // 构建歌词页面
  Widget _buildLyricsPage() {
    return Scaffold(
      body: _isLoadingLyrics
          ? Center(child: CircularProgressIndicator())
          : _lrcLyrics.isEmpty
          ? Center(child: Text('未找到歌词'))
          : Stack(
              children: [
                // 歌词视图
                LyricView(
                  controller: _lyricController,
                  style: LyricStyle(
                    textStyle:
                        Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 22,
                        ) ??
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 22,
                        ),
                    activeStyle:
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                        ) ??
                        TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 28,
                        ),
                    translationStyle:
                        Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ) ??
                        TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                    lineGap: 20,
                    translationLineGap: 10,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical:
                          (MediaQuery.of(context).size.height - 80 - 200) / 2 -
                          48,
                    ),
                    activeAnchorPosition: 0.5,
                    selectionAnchorPosition: 0.5,
                    contentAlignment: CrossAxisAlignment.center,
                    lineTextAlign: TextAlign.center,
                    selectionAlignment: MainAxisAlignment.center,
                    selectedColor: Theme.of(context).colorScheme.primary,
                    selectedTranslationColor: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant,
                    scrollDuration: const Duration(milliseconds: 300),
                    activeAutoResumeDuration: const Duration(seconds: 3),
                    selectionAutoResumeDuration: const Duration(seconds: 1),
                  ),
                ),
                // 顶部遮罩
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface,
                          Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.95),
                          Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                        ],
                      ),
                    ),
                  ),
                ),
                // 底部遮罩
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Theme.of(context).colorScheme.surface.withOpacity(0),
                          Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.8),
                          Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.95),
                          Theme.of(context).colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
            ),
          ),

          // 来源和歌名
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getSourceText(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
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
                padding: const EdgeInsets.only(bottom: 40),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song['title'] ?? '未知歌曲',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song['artist'] ?? '未知艺术家',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                  SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 8,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 0,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 0,
                      ),
                    ),
                    child: Slider(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      value: _currentPosition.inMilliseconds.toDouble().clamp(
                        0,
                        _totalDuration.inMilliseconds.toDouble(),
                      ),
                      max: _totalDuration.inMilliseconds.toDouble(),
                      min: 0,
                      activeColor: Theme.of(context).colorScheme.primary,
                      inactiveColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                      onChanged: (value) {
                        widget.playerService.seekTo(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                        Text(
                          _formatDuration(_totalDuration),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                // 上一曲
                _buildControlButton(
                  icon: Icons.skip_previous,
                  onPressed: () => widget.playerService.previousSong(),
                  isPlaying: _isPlaying,
                  shapeAnimation: _shapeAnimation,
                ),

                // 播放/暂停
                GestureDetector(
                  onTapDown: (_) => _playButtonController.forward(),
                  onTapUp: (_) => _playButtonController.reverse(),
                  onTapCancel: () => _playButtonController.reverse(),
                  onTap: () => widget.playerService.togglePlayPause(),
                  child: AnimatedBuilder(
                    animation: Listenable.merge([
                      _playButtonScale,
                      _shapeAnimation,
                    ]),
                    builder: (context, child) {
                      final progress = _shapeAnimation.value;
                      final width = _lerpDouble(80.0, 64.0, progress);
                      final borderRadius = _lerpDouble(16.0, 32.0, progress);

                      return Transform.scale(
                        scale: _playButtonScale.value,
                        child: Container(
                          width: width,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(borderRadius),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 32,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 下一曲
                _buildControlButton(
                  icon: Icons.skip_next,
                  onPressed: () => widget.playerService.nextSong(),
                  isPlaying: _isPlaying,
                  shapeAnimation: _shapeAnimation,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isPlaying,
    required Animation<double> shapeAnimation,
  }) {
    return GestureDetector(
      onTapDown: (_) => _playButtonController.forward(),
      onTapUp: (_) => _playButtonController.reverse(),
      onTapCancel: () => _playButtonController.reverse(),
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([_playButtonScale, shapeAnimation]),
        builder: (context, child) {
          final progress = shapeAnimation.value;
          final width = _lerpDouble(64.0, 80.0, progress);
          final borderRadius = _lerpDouble(16.0, 16.0, progress);

          return Transform.scale(
            scale: _playButtonScale.value,
            child: Container(
              width: width,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.5),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

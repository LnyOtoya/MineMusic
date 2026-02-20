import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../services/subsonic_api.dart';
import '../services/player_service.dart';
import '../widgets/material_wave_slider.dart';
import '../widgets/lyrics_widget.dart';
import '../models/lyrics_model.dart';

class PlaybackPage extends StatefulWidget {
  final SubsonicApi api;
  final PlayerService playerService;

  const PlaybackPage({
    super.key,
    required this.api,
    required this.playerService,
  });

  @override
  State<PlaybackPage> createState() => _PlaybackPageState();
}

class _PlaybackPageState extends State<PlaybackPage> {
  late PageController _pageController;
  LyricsData? _lyricsData;
  bool _isLoadingLyrics = false;
  String? _currentSongId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    widget.playerService.addListener(_onPlayerStateChanged);
    _loadLyrics();
  }

  @override
  void dispose() {
    widget.playerService.removeListener(_onPlayerStateChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onPlayerStateChanged() {
    if (mounted) {
      final currentSong = widget.playerService.currentSong;
      if (currentSong != null && currentSong['id'] != null) {
        final songId = currentSong['id'];
        if (_currentSongId != songId) {
          _loadLyrics();
        }
      }
      setState(() {});
    }
  }

  Future<void> _loadLyrics() async {
    final currentSong = widget.playerService.currentSong;
    if (currentSong == null || currentSong['id'] == null) {
      return;
    }

    final songId = currentSong['id'];
    
    if (_currentSongId == songId && _lyricsData != null) {
      return;
    }

    setState(() {
      _currentSongId = songId;
      _isLoadingLyrics = true;
    });

    try {
      final lyrics = await widget.api.getLyricsBySongId(songId);
      if (mounted) {
        setState(() {
          _lyricsData = lyrics;
          _isLoadingLyrics = false;
        });
      }
    } catch (e) {
      print('加载歌词失败: $e');
      if (mounted) {
        setState(() {
          _isLoadingLyrics = false;
        });
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getSourceInfo() {
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

  @override
  Widget build(BuildContext context) {
    final currentSong = widget.playerService.currentSong;
    final isPlaying = widget.playerService.isPlaying;
    final currentPosition = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;
    final currentIndex = widget.playerService.currentIndex;
    final playlist = widget.playerService.currentPlaylist;

    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 32),
          child: Transform.scale(
            scale: 1.5,
            child: IconButton(
              icon: const Icon(
                Symbols.keyboard_arrow_down,
                fill: 0,
                weight: 400,
                grade: 0,
                opticalSize: 24,
              ),
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            _getSourceInfo(),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        centerTitle: false,
      ),
      body: PageView(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildPlaybackPage(),
          _buildLyricsPage(),
        ],
      ),
    );
  }

  Widget _buildPlaybackPage() {
    final currentSong = widget.playerService.currentSong;
    final isPlaying = widget.playerService.isPlaying;
    final currentPosition = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;
    final currentIndex = widget.playerService.currentIndex;
    final playlist = widget.playerService.currentPlaylist;

    final progress = totalDuration.inMilliseconds > 0
        ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        const SizedBox(height: 16),

        // 封面区域
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: currentSong != null && currentSong['coverArt'] != null
                    ? CachedNetworkImage(
                        imageUrl: widget.api.getCoverArtUrl(
                          currentSong['coverArt'],
                        ),
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Symbols.music_note,
                            fill: 0,
                            weight: 400,
                            grade: 0,
                            opticalSize: 120,
                            color: Colors.white,
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Symbols.music_note,
                            fill: 0,
                            weight: 400,
                            grade: 0,
                            opticalSize: 120,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Symbols.music_note,
                          fill: 0,
                          weight: 400,
                          grade: 0,
                          opticalSize: 120,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 时间显示和进度条
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: GestureDetector(
            onHorizontalDragStart: (_) {},
            onHorizontalDragUpdate: (_) {},
            onHorizontalDragEnd: (_) {},
            behavior: HitTestBehavior.opaque,
            child: Column(
              children: [
                // 保留现有的进度条
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 6.0,
                  ),
                  child: MaterialWaveSlider(
                    height: 40.0,
                    value: progress,
                    min: 0.0,
                    max: 1.0,
                    paused: !isPlaying,
                    onChanged: (value) {
                      if (totalDuration.inMilliseconds > 0) {
                        final newPosition = Duration(
                          milliseconds: (value * totalDuration.inMilliseconds).round(),
                        );
                        widget.playerService.seekTo(newPosition);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(currentPosition),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      _formatDuration(totalDuration),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 歌曲信息
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 32),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSong?['title'] ?? 'No song',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 28,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  currentSong?['artist'] ?? 'Unknown artist',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 20,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // 播放控制按钮
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 上一曲
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: const Icon(
                      Symbols.skip_previous,
                      fill: 0,
                      weight: 400,
                      grade: 0,
                      opticalSize: 24,
                    ),
                    onPressed: () => widget.playerService.previousSong(),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  ),
                ),
              ),

              // 播放/暂停
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: Icon(
                      isPlaying ? Symbols.pause : Symbols.play_arrow,
                      fill: 1,
                      weight: 400,
                      grade: 0,
                      opticalSize: 24,
                      color: Colors.white,
                    ),
                    onPressed: () => widget.playerService.togglePlayPause(),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  ),
                ),
              ),

              // 下一曲
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: IconButton(
                    icon: const Icon(
                      Symbols.skip_next,
                      fill: 0,
                      weight: 400,
                      grade: 0,
                      opticalSize: 24,
                    ),
                    onPressed: () => widget.playerService.nextSong(),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 底部控制
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 随机播放 - 圆形
              Tooltip(
                message: widget.playerService.playbackMode == PlaybackMode.shuffle
                    ? '随机播放'
                    : '顺序播放',
                child: IconButton(
                  icon: Icon(
                        Symbols.shuffle,
                        fill: widget.playerService.playbackMode == PlaybackMode.shuffle ? 1 : 0,
                        weight: 400,
                        grade: 0,
                        opticalSize: 24,
                        color: widget.playerService.playbackMode == PlaybackMode.shuffle
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  onPressed: () => widget.playerService.toggleShuffle(),
                  style: IconButton.styleFrom(
                    backgroundColor: widget.playerService.playbackMode == PlaybackMode.shuffle
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              // 循环播放 - 胶囊形
              Tooltip(
                message: widget.playerService.playbackMode == PlaybackMode.repeatOne
                    ? '单曲循环'
                    : widget.playerService.playbackMode == PlaybackMode.repeatAll
                        ? '列表循环'
                        : '顺序播放',
                child: IconButton(
                  icon: Icon(
                        widget.playerService.playbackMode == PlaybackMode.repeatOne
                            ? Symbols.repeat_one
                            : Symbols.repeat,
                        fill: (widget.playerService.playbackMode == PlaybackMode.repeatOne ||
                                widget.playerService.playbackMode == PlaybackMode.repeatAll)
                            ? 1
                            : 0,
                        weight: 400,
                        grade: 0,
                        opticalSize: 24,
                        color: (widget.playerService.playbackMode == PlaybackMode.repeatOne ||
                                widget.playerService.playbackMode == PlaybackMode.repeatAll)
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                  onPressed: () => widget.playerService.toggleRepeat(),
                  style: IconButton.styleFrom(
                    backgroundColor: (widget.playerService.playbackMode == PlaybackMode.repeatOne ||
                            widget.playerService.playbackMode == PlaybackMode.repeatAll)
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.primaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                ),
              ),

              // 播放列表 - 胶囊形
              IconButton(
                icon: const Icon(
                  Symbols.queue_music,
                  fill: 0,
                  weight: 400,
                  grade: 0,
                  opticalSize: 24,
                ),
                onPressed: () {},
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildLyricsPage() {
    return ValueListenableBuilder<Duration>(
      valueListenable: PlayerService.positionNotifier,
      builder: (context, position, child) {
        return LyricsWidget(
          lyricsData: _isLoadingLyrics ? null : _lyricsData,
          currentPosition: position,
          isPlaying: widget.playerService.isPlaying,
        );
      },
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import '../services/lyrics_api.dart';
import '../models/lyrics_api_type.dart';
import '../utils/lrc_to_qrc_converter.dart';
import 'artist_detail_page.dart';
import 'detail_page.dart';

class PlayerPage extends StatefulWidget {
  final PlayerService playerService;
  final SubsonicApi api;

  const PlayerPage({super.key, required this.playerService, required this.api});

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
  late AnimationController _toolbarAnimationController;
  late Animation<double> _toolbarAnimation;
  late AnimationController _buttonScaleController;
  late Animation<double> _buttonScale;
  late AnimationController _buttonRotationController;
  late Animation<double> _buttonRotation;
  late AnimationController _fontSizeSliderController;
  late Animation<double> _fontSizeSliderAnimation;
  bool _isPlaying = false;
  bool _wasPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String _lrcLyrics = '';
  bool _isLoadingLyrics = false;
  bool _lyricsEnabled = false;
  LyricsApiType _currentLyricsApiType = LyricsApiType.disabled;
  late LyricController _lyricController;
  ValueNotifier<LyricStyle>? _lyricStyleNotifier;
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;
  String? _currentSongId;

  bool _showStyleToolbar = false;
  bool _showFontSizeSlider = false;
  String _currentAlignment = '中'; // 左、中、右

  final LyricsApi _lyricsApi = LyricsApi();

  @override
  void initState() {
    super.initState();

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

    // 初始化工具栏动画
    _toolbarAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _toolbarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _toolbarAnimationController,
        curve: Curves.easeOut,
      ),
    );

    // 初始化按钮缩放动画
    _buttonScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonScaleController, curve: Curves.easeInOut),
    );

    // 初始化按钮旋转动画
    _buttonRotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // 延长动画时间，确保可见
    );
    _buttonRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonRotationController,
        curve: Curves.easeInOut,
      ),
    );

    // 初始化字体大小滑动条动画
    _fontSizeSliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fontSizeSliderAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fontSizeSliderController, curve: Curves.easeOut),
    );

    // 初始化歌词控制器
    _lyricController = LyricController();

    // 初始化歌词设置
    _lyricsEnabled = PlayerService.lyricsEnabledNotifier.value;
    _currentLyricsApiType = PlayerService.lyricsApiTypeNotifier.value;

    // 监听歌词设置变化
    PlayerService.lyricsEnabledNotifier.addListener(_onLyricsSettingsChanged);
    PlayerService.lyricsApiTypeNotifier.addListener(_onLyricsSettingsChanged);

    // 监听播放状态变化
    widget.playerService.addListener(_updatePlayerState);
    _updatePlayerState(); // 初始状态更新

    // 加载当前歌曲歌词
    _loadLyrics();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 初始化歌词样式通知器（在 initState 之后调用，可以安全访问 Theme）
    _lyricStyleNotifier ??= ValueNotifier(
      LyricStyles.default1.copyWith(
        textStyle: TextStyle(
          fontSize: 22,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        activeStyle: TextStyle(
          fontSize: 28,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.normal,
        ),
        translationStyle: TextStyle(
          fontSize: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        selectedColor: Theme.of(context).colorScheme.onSurfaceVariant,
        selectedTranslationColor: Theme.of(
          context,
        ).colorScheme.onSurfaceVariant,
        activeHighlightColor: Theme.of(
          context,
        ).colorScheme.primary.withValues(alpha: 1),
      ),
    );
  }

  void _onLyricsSettingsChanged() {
    setState(() {
      _lyricsEnabled = PlayerService.lyricsEnabledNotifier.value;
      _currentLyricsApiType = PlayerService.lyricsApiTypeNotifier.value;
    });
    _loadLyrics();
  }

  @override
  void dispose() {
    // _animationController.dispose();
    _playButtonController.dispose();
    _shapeAnimationController.dispose();
    _toolbarAnimationController.dispose();
    _buttonScaleController.dispose();
    _buttonRotationController.dispose();
    _fontSizeSliderController.dispose();

    _pageController.dispose();
    _lyricController.dispose();

    PlayerService.lyricsEnabledNotifier.removeListener(
      _onLyricsSettingsChanged,
    );
    PlayerService.lyricsApiTypeNotifier.removeListener(
      _onLyricsSettingsChanged,
    );

    widget.playerService.removeListener(_updatePlayerState);
    super.dispose();
  }

  // 加载歌词
  Future<void> _loadLyrics() async {
    final song = widget.playerService.currentSong;
    if (song == null) return;

    if (!_lyricsEnabled) {
      print('🚫 歌词功能已关闭');
      setState(() {
        _lrcLyrics = '';
      });
      return;
    }

    final lyricsApiType = _currentLyricsApiType;

    setState(() => _isLoadingLyrics = true);

    try {
      final title = song['title'] ?? '';
      final artist = song['artist'] ?? '';

      print('🎵 开始加载歌词: $title - $artist');
      print('📡 使用API: ${lyricsApiType.displayName}');

      if (lyricsApiType == LyricsApiType.subsonic) {
        final lyricData = await widget.api.getLyrics(
          artist: artist,
          title: title,
        );

        if (lyricData != null && lyricData['text'].isNotEmpty) {
          print('✅ 从Subsonic/Navidrome获取到歌词');
          final lyricsText = lyricData['text'];

          final isQrc = LrcToQrcConverter.isQrcFormat(lyricsText);
          final qrcLyrics = isQrc
              ? lyricsText
              : LrcToQrcConverter.convertLrcToQrc(lyricsText);

          if (isQrc) {
            print('✅ 检测到QRC格式，使用原始歌词（支持逐字高亮）');
          } else {
            print('🔄 已转换为QRC格式，支持逐字高亮');
          }

          setState(() {
            _lrcLyrics = qrcLyrics;
            _lyricController.loadLyric(qrcLyrics);
          });
          return;
        }

        print('⚠️ Subsonic/Navidrome未找到歌词');
      }

      if (lyricsApiType == LyricsApiType.customApi) {
        final lyricsData = await _lyricsApi.getCustomApiLyrics(title, artist);

        if (lyricsData['lyrics'] != null && lyricsData['lyrics']!.isNotEmpty) {
          print('✅ 从自建API获取到歌词');
          print('📝 歌词长度: ${lyricsData['lyrics']!.length}');
          print('📝 翻译长度: ${lyricsData['translation']!.length}');

          final lyricsText = lyricsData['lyrics']!;
          final translationText = lyricsData['translation'];

          final isQrc = LrcToQrcConverter.isQrcFormat(lyricsText);
          final qrcLyrics = isQrc
              ? lyricsText
              : LrcToQrcConverter.convertLrcToQrc(lyricsText);

          if (isQrc) {
            print('✅ 检测到QRC格式，使用原始歌词（支持逐字高亮）');
          } else {
            print('🔄 已转换为QRC格式，支持逐字高亮');
          }

          setState(() {
            _lrcLyrics = qrcLyrics;
            if (translationText != null && translationText.isNotEmpty) {
              // 翻译歌词保持LRC格式，不需要转换为QRC格式
              _lyricController.loadLyric(
                qrcLyrics,
                translationLyric: translationText,
              );
            } else {
              _lyricController.loadLyric(qrcLyrics);
            }
          });
          return;
        }

        print('⚠️ 自建API未找到歌词');
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
    if (!_lyricsEnabled) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lyrics_rounded,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '歌词功能已关闭',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '请在设置中启用歌词',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _isLoadingLyrics
          ? Center(child: CircularProgressIndicator())
          : _lrcLyrics.isEmpty
          ? Center(child: Text('未找到歌词'))
          : ValueListenableBuilder(
              valueListenable: _lyricStyleNotifier!,
              builder: (context, style, child) {
                final isDark =
                    MediaQuery.of(context).platformBrightness ==
                    Brightness.dark;

                // 确保始终设置翻译相关样式，但保留用户调整的字体大小
                style = style.copyWith(
                  // 基本翻译样式
                  translationStyle: style.translationStyle.copyWith(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  // 激活状态的翻译样式
                  translationActiveColor: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  // 选中状态的翻译样式
                  selectedTranslationColor: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  // 翻译行间距
                  translationLineGap: 8.0,
                  // 基本文本样式
                  textStyle: style.textStyle.copyWith(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.4)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  // 激活状态的文本样式
                  activeStyle: style.activeStyle.copyWith(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.8)
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                  ),
                  // 选中状态的文本样式
                  selectedColor: isDark
                      ? Colors.black.withValues(alpha: 0.4)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  // 高亮颜色
                  activeHighlightColor: isDark
                      ? Colors.black.withValues(alpha: 0.9)
                      : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 1),
                );

                return Stack(
                  children: [
                    RepaintBoundary(
                      child: Container(
                        // 添加上下内边距，间接增大遮罩效果
                        padding: const EdgeInsets.symmetric(vertical: 120),
                        child: LyricView(
                          controller: _lyricController,
                          style: style,
                        ),
                      ),
                    ),
                    // 歌词样式调整工具栏
                    _buildStyleToolbar(),
                  ],
                );
              },
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

  // 构建字体大小调整按钮
  Widget _buildFontSizeButtons() {
    return Column(
      children: [
        // 增大字体按钮
        GestureDetector(
          onTap: () {
            final currentStyle = _lyricStyleNotifier!.value;
            final newTextSize = (currentStyle.textStyle.fontSize ?? 22) + 2;
            final newActiveSize = (currentStyle.activeStyle.fontSize ?? 28) + 2;
            final newTranslationSize =
                (currentStyle.translationStyle.fontSize ?? 16) + 1;

            _lyricStyleNotifier!.value = currentStyle.copyWith(
              textStyle: currentStyle.textStyle.copyWith(fontSize: newTextSize),
              activeStyle: currentStyle.activeStyle.copyWith(
                fontSize: newActiveSize,
              ),
              translationStyle: currentStyle.translationStyle.copyWith(
                fontSize: newTranslationSize,
              ),
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.text_increase,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        // 减小字体按钮
        GestureDetector(
          onTap: () {
            final currentStyle = _lyricStyleNotifier!.value;
            final newTextSize = (currentStyle.textStyle.fontSize ?? 22) - 2;
            final newActiveSize = (currentStyle.activeStyle.fontSize ?? 28) - 2;
            final newTranslationSize =
                (currentStyle.translationStyle.fontSize ?? 16) - 1;

            // 最小字体大小限制
            if (newTextSize >= 12 &&
                newActiveSize >= 16 &&
                newTranslationSize >= 10) {
              _lyricStyleNotifier!.value = currentStyle.copyWith(
                textStyle: currentStyle.textStyle.copyWith(
                  fontSize: newTextSize,
                ),
                activeStyle: currentStyle.activeStyle.copyWith(
                  fontSize: newActiveSize,
                ),
                translationStyle: currentStyle.translationStyle.copyWith(
                  fontSize: newTranslationSize,
                ),
              );
            }
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.text_decrease,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建对齐方式调整按钮
  Widget _buildAlignmentButtons() {
    return Column(
      children: [
        // 左对齐按钮
        GestureDetector(
          onTap: () {
            final currentStyle = _lyricStyleNotifier!.value;
            _lyricStyleNotifier!.value = currentStyle.copyWith(
              textAlign: TextAlign.left,
              contentAlignment: CrossAxisAlignment.start,
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.format_align_left,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        // 居中对齐按钮
        GestureDetector(
          onTap: () {
            final currentStyle = _lyricStyleNotifier!.value;
            _lyricStyleNotifier!.value = currentStyle.copyWith(
              textAlign: TextAlign.center,
              contentAlignment: CrossAxisAlignment.center,
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.format_align_center,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
        SizedBox(height: 8),
        // 右对齐按钮
        GestureDetector(
          onTap: () {
            final currentStyle = _lyricStyleNotifier!.value;
            _lyricStyleNotifier!.value = currentStyle.copyWith(
              textAlign: TextAlign.right,
              contentAlignment: CrossAxisAlignment.end,
            );
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(200),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.format_align_right,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 构建样式调整工具栏
  Widget _buildStyleToolbar() {
    return Stack(
      children: [
        // 主控制按钮
        Positioned(
          bottom: 32,
          right: 16,
          child: GestureDetector(
            onTapDown: (_) => _buttonScaleController.forward(),
            onTapUp: (_) {
              _buttonScaleController.reverse();
              if (_showStyleToolbar) {
                // 收起工具栏 - 同时执行旋转和收起动画
                _buttonRotationController.forward(from: 0).then((_) {
                  _buttonRotationController.reset();
                });
                // 工具栏收起动画完成后再更新状态
                _toolbarAnimationController.reverse().then((_) {
                  setState(() {
                    _showStyleToolbar = false;
                    _showFontSizeSlider = false;
                  });
                });
              } else {
                // 展开工具栏 - 同时执行旋转和展开动画
                _buttonRotationController.forward(from: 0).then((_) {
                  _buttonRotationController.reset();
                });
                _toolbarAnimationController.forward(from: 0);
                // 立即更新状态，使图标切换与动画同步
                setState(() {
                  _showStyleToolbar = true;
                  _showFontSizeSlider = false;
                });
              }
            },
            onTapCancel: () => _buttonScaleController.reverse(),
            child: AnimatedBuilder(
              animation: Listenable.merge([_buttonScale, _buttonRotation]),
              builder: (context, child) {
                double rotationAngle = _buttonRotation.value * 2 * 3.14159;
                // 收起时使用负角度
                if (_showStyleToolbar) {
                  rotationAngle = -rotationAngle;
                }
                return Transform.scale(
                  scale: _buttonScale.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle: rotationAngle,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: Icon(
                            _showStyleToolbar ? Icons.close : Icons.format_size,
                            key: ValueKey<bool>(_showStyleToolbar),
                            color: Theme.of(context).colorScheme.onPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // 展开的工具栏
        if (_showStyleToolbar) ...[
          // 背景遮罩
          GestureDetector(
            onTap: () {
              // 逆时针旋转360度 - 同时执行旋转和收起动画
              _buttonRotationController.forward(from: 0).then((_) {
                _buttonRotationController.reset();
              });
              // 工具栏收起动画完成后再更新状态
              _toolbarAnimationController.reverse().then((_) {
                setState(() {
                  _showStyleToolbar = false;
                  _showFontSizeSlider = false;
                });
              });
            },
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // 工具栏按钮
          Positioned(
            bottom: 100,
            right: 16,
            child: AnimatedBuilder(
              animation: _toolbarAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _toolbarAnimation.value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _toolbarAnimation.value) * 20),
                    child: Column(
                      children: [
                        // 字体大小调整按钮
                        GestureDetector(
                          onTapDown: (_) => _buttonScaleController.forward(),
                          onTapUp: (_) {
                            _buttonScaleController.reverse();
                            if (_showFontSizeSlider) {
                              // 收起滑动条 - 先播放收回动画，完成后再更新状态
                              _fontSizeSliderController.reverse().then((_) {
                                setState(() {
                                  _showFontSizeSlider = false;
                                });
                              });
                            } else {
                              // 展开滑动条 - 立即更新状态并播放弹出动画
                              setState(() {
                                _showFontSizeSlider = true;
                              });
                              _fontSizeSliderController.forward(from: 0);
                            }
                          },
                          onTapCancel: () => _buttonScaleController.reverse(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Icon(
                                Icons.text_fields,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),

                        // 对齐方式调整按钮
                        GestureDetector(
                          onTapDown: (_) => _buttonScaleController.forward(),
                          onTapUp: (_) {
                            _buttonScaleController.reverse();
                            _toggleAlignment();
                          },
                          onTapCancel: () => _buttonScaleController.reverse(),
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(30),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _currentAlignment,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // 字体大小滑动条
          if (_showFontSizeSlider) ...[
            Positioned(
              bottom: 200,
              left: 16,
              right: 80,
              child: AnimatedBuilder(
                animation: _fontSizeSliderAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fontSizeSliderAnimation.value,
                    child: Transform.translate(
                      offset: Offset(
                        0,
                        (1 - _fontSizeSliderAnimation.value) * 20,
                      ),
                      child: Transform.scale(
                        scale: 0.95 + (_fontSizeSliderAnimation.value * 0.05),
                        child: Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                '字体大小',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              SizedBox(height: 12),
                              Slider(
                                value:
                                    (_lyricStyleNotifier!
                                        .value
                                        .textStyle
                                        .fontSize ??
                                    22),
                                min: 12,
                                max: 36,
                                divisions: 12,
                                label:
                                    '${(_lyricStyleNotifier!.value.textStyle.fontSize ?? 22).toStringAsFixed(0)}',
                                onChanged: (value) {
                                  final currentStyle =
                                      _lyricStyleNotifier!.value;
                                  final scaleFactor =
                                      value /
                                      (currentStyle.textStyle.fontSize ?? 22);
                                  final newActiveSize =
                                      (currentStyle.activeStyle.fontSize ??
                                          28) *
                                      scaleFactor;
                                  final newTranslationSize =
                                      (currentStyle.translationStyle.fontSize ??
                                          16) *
                                      scaleFactor;

                                  _lyricStyleNotifier!.value = currentStyle
                                      .copyWith(
                                        textStyle: currentStyle.textStyle
                                            .copyWith(fontSize: value),
                                        activeStyle: currentStyle.activeStyle
                                            .copyWith(fontSize: newActiveSize),
                                        translationStyle: currentStyle
                                            .translationStyle
                                            .copyWith(
                                              fontSize: newTranslationSize,
                                            ),
                                      );
                                },
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '小',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  Text(
                                    '大',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }

  // 切换对齐方式
  void _toggleAlignment() {
    setState(() {
      if (_currentAlignment == '左') {
        _currentAlignment = '中';
        _updateAlignment(TextAlign.center, CrossAxisAlignment.center);
      } else if (_currentAlignment == '中') {
        _currentAlignment = '右';
        _updateAlignment(TextAlign.right, CrossAxisAlignment.end);
      } else {
        _currentAlignment = '左';
        _updateAlignment(TextAlign.left, CrossAxisAlignment.start);
      }
    });
  }

  // 更新对齐方式
  void _updateAlignment(
    TextAlign textAlign,
    CrossAxisAlignment contentAlignment,
  ) {
    final currentStyle = _lyricStyleNotifier!.value;
    _lyricStyleNotifier!.value = currentStyle.copyWith(
      textAlign: textAlign,
      contentAlignment: contentAlignment,
    );
  }

  // 构建默认封面
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
                      GestureDetector(
                        onTap: () {
                          if (song['album'] != null &&
                              song['album'] != '未知专辑' &&
                              song['albumId'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DetailPage(
                                  item: {
                                    'id': song['albumId'],
                                    'name': song['album'],
                                    'coverArt': song['coverArt'],
                                    'artist': song['artist'],
                                  },
                                  type: DetailType.album,
                                  api: widget.api,
                                  playerService: widget.playerService,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          song['title'] ?? '未知歌曲',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                decoration: TextDecoration.none,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          if (song['artist'] != null &&
                              song['artist'] != '未知艺术家' &&
                              song['artistId'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArtistDetailPage(
                                  artist: {
                                    'id': song['artistId'],
                                    'name': song['artist'],
                                  },
                                  api: widget.api,
                                  playerService: widget.playerService,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          song['artist'] ?? '未知艺术家',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.none,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
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

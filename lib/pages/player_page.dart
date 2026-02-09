import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import '../services/player_service.dart';
import '../services/subsonic_api.dart';
import '../services/lyrics_api.dart';
import '../services/color_manager_service.dart';
import '../models/lyrics_api_type.dart';
import '../utils/lrc_to_qrc_converter.dart';
import '../utils/tonal_surface_helper.dart';
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
  late AnimationController _breathingAnimationController;
  late Animation<double> _breathingAnimation;
  late WaveLinearProgressController _waveController;
  late AnimationController _transitionAnimationController;
  late Animation<double> _transitionAnimation;
  bool _isPlaying = false;
  bool _wasPlaying = false;
  bool _isInitialized = false;
  bool _isDraggingProgressBar = false;
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

  ColorScheme? _coverColorScheme; // 提取的封面颜色方案
  ColorScheme? _targetCoverColorScheme; // 目标封面颜色方案
  bool _isExtractingColors = false; // 颜色提取加载状态
  late AnimationController _colorAnimationController; // 颜色动画控制器
  Animation<Color?>? _primaryColorAnimation; // 主色动画
  Animation<Color?>? _onPrimaryColorAnimation; // 主色文本动画
  Animation<Color?>? _onSurfaceColorAnimation; // 表面文本动画
  Animation<Color?>? _onSurfaceVariantColorAnimation; // 表面变体文本动画
  Animation<Color?>? _primaryContainerColorAnimation; // 主容器色动画
  Animation<Color?>? _onPrimaryContainerColorAnimation; // 主容器文本动画
  Animation<Color?>? _surfaceVariantColorAnimation; // 表面变体色动画
  Animation<Color?>? _tonalSurfaceAnimation; // tonal surface背景色动画

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

    // 初始化呼吸动画控制器
    _breathingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800), // 1800-2400ms之间
    );
    _breathingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    _breathingAnimationController.repeat(reverse: true);

    // 初始化波浪进度条控制器
    _waveController = WaveLinearProgressController();
    _waveController.waveOn();

    // 初始化过渡动画控制器
    _transitionAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _transitionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _transitionAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // 初始化歌词控制器
    _lyricController = LyricController();

    // 初始化歌词设置
    _lyricsEnabled = PlayerService.lyricsEnabledNotifier.value;
    _currentLyricsApiType = PlayerService.lyricsApiTypeNotifier.value;

    // 初始化颜色动画控制器
    _colorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200), // 增加动画时长
      vsync: this,
    );

    // 监听全局颜色变化
    ColorManagerService().addListener(_onGlobalColorChanged);

    // 监听歌词设置变化
    PlayerService.lyricsEnabledNotifier.addListener(_onLyricsSettingsChanged);
    PlayerService.lyricsApiTypeNotifier.addListener(_onLyricsSettingsChanged);

    // 监听播放状态变化
    widget.playerService.addListener(_updatePlayerState);

    // 初始化基本状态但不调用 _updatePlayerState（避免在 initState 中使用 context）
    final currentSong = widget.playerService.currentSong;
    final isPlaying = widget.playerService.isPlaying;
    final position = widget.playerService.currentPosition;
    final totalDuration = widget.playerService.totalDuration;

    _currentSongId = currentSong?['id'];
    _isPlaying = isPlaying;
    _currentPosition = position ?? Duration.zero;
    _totalDuration = totalDuration;

    // 初始化动画状态
    if (isPlaying) {
      // 设置为播放状态
      _shapeAnimationController.value = 1.0;
      _transitionAnimationController.value = 1.0;
      _waveController.waveOn();
    } else {
      // 设置为暂停状态
      _shapeAnimationController.value = 0.0;
      _transitionAnimationController.value = 0.0;
      _waveController.waveOff();
    }

    // 初始化波浪进度条
    if (_totalDuration.inMilliseconds > 0) {
      final double progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
      _waveController.setProgress(progress);
    }

    _isInitialized = true; // 初始化完成

    // 加载当前歌曲歌词
    _loadLyrics();
  }

  Brightness? _previousBrightness;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final currentBrightness = Theme.of(context).brightness; // 使用应用主题亮度而不是系统亮度
    final defaultColorScheme = Theme.of(context).colorScheme;

    // 检测主题切换
    if (_previousBrightness != null &&
        _previousBrightness != currentBrightness) {
      // 主题切换时，立即更新所有动画的当前值，避免二次变深
      _updateAnimationValuesForThemeChange(defaultColorScheme);
    }
    _previousBrightness = currentBrightness;

    // 初始化颜色动画变量（在 initState 之后调用，可以安全访问 Theme）
    _primaryColorAnimation = ColorTween(
      begin: defaultColorScheme.primary,
      end: defaultColorScheme.primary,
    ).animate(_colorAnimationController);

    _onPrimaryColorAnimation = ColorTween(
      begin: defaultColorScheme.onPrimary,
      end: defaultColorScheme.onPrimary,
    ).animate(_colorAnimationController);

    _onSurfaceColorAnimation = ColorTween(
      begin: defaultColorScheme.onSurface,
      end: defaultColorScheme.onSurface,
    ).animate(_colorAnimationController);

    _onSurfaceVariantColorAnimation = ColorTween(
      begin: defaultColorScheme.onSurfaceVariant,
      end: defaultColorScheme.onSurfaceVariant,
    ).animate(_colorAnimationController);

    _primaryContainerColorAnimation = ColorTween(
      begin: defaultColorScheme.primaryContainer,
      end: defaultColorScheme.primaryContainer,
    ).animate(_colorAnimationController);

    // 初始化完成后使用全局颜色方案
    if (_isInitialized) {
      _useGlobalColorScheme();
    }

    _onPrimaryContainerColorAnimation = ColorTween(
      begin: defaultColorScheme.onPrimaryContainer,
      end: defaultColorScheme.onPrimaryContainer,
    ).animate(_colorAnimationController);

    _surfaceVariantColorAnimation = ColorTween(
      begin: defaultColorScheme.surfaceVariant,
      end: defaultColorScheme.surfaceVariant,
    ).animate(_colorAnimationController);

    // 初始化tonal surface背景色动画（将primary以6%不透明度混入surface）
    _tonalSurfaceAnimation = ColorTween(
      begin: TonalSurfaceHelper.getTonalSurfaceFromColors(
        defaultColorScheme.primary,
        defaultColorScheme.surface,
      ),
      end: TonalSurfaceHelper.getTonalSurfaceFromColors(
        defaultColorScheme.primary,
        defaultColorScheme.surface,
      ),
    ).animate(_colorAnimationController);

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

  // 主题切换时更新动画值
  void _updateAnimationValuesForThemeChange(ColorScheme colorScheme) {
    // 立即更新 _coverColorScheme 为 null，强制使用新主题颜色
    _coverColorScheme = null;
    _targetCoverColorScheme = null;

    // 重置颜色动画控制器，确保动画从新主题颜色开始
    _colorAnimationController.value = 0;

    // 重新计算并应用新主题的颜色
    setState(() {
      // 这里不需要做任何操作，因为 didChangeDependencies 会重新初始化动画
      // 但我们需要确保 _coverColorScheme 为 null，这样就会使用新主题的颜色
    });
  }

  // 计算颜色的亮度（0-1，值越大越亮）
  double _getColorBrightness(Color color) {
    // 使用相对亮度公式：0.299*R + 0.587*G + 0.114*B
    final r = color.red / 255.0;
    final g = color.green / 255.0;
    final b = color.blue / 255.0;
    return 0.299 * r + 0.587 * g + 0.114 * b;
  }

  // 调整颜色方案的亮度，使其达到目标亮度
  ColorScheme _adjustColorSchemeBrightness(
    ColorScheme colorScheme,
    double targetBrightness,
  ) {
    // 计算当前 surface 颜色的亮度
    final currentBrightness = _getColorBrightness(colorScheme.surface);

    // 如果当前亮度已经大于等于目标亮度，不需要调整
    if (currentBrightness >= targetBrightness) {
      return colorScheme;
    }

    // 计算亮度调整比例
    final brightnessRatio = targetBrightness / currentBrightness;

    // 调整所有颜色
    return ColorScheme(
      brightness: colorScheme.brightness,
      primary: _adjustColorBrightness(colorScheme.primary, brightnessRatio),
      onPrimary: _adjustColorBrightness(colorScheme.onPrimary, brightnessRatio),
      primaryContainer: _adjustColorBrightness(
        colorScheme.primaryContainer,
        brightnessRatio,
      ),
      onPrimaryContainer: _adjustColorBrightness(
        colorScheme.onPrimaryContainer,
        brightnessRatio,
      ),
      secondary: _adjustColorBrightness(colorScheme.secondary, brightnessRatio),
      onSecondary: _adjustColorBrightness(
        colorScheme.onSecondary,
        brightnessRatio,
      ),
      secondaryContainer: _adjustColorBrightness(
        colorScheme.secondaryContainer,
        brightnessRatio,
      ),
      onSecondaryContainer: _adjustColorBrightness(
        colorScheme.onSecondaryContainer,
        brightnessRatio,
      ),
      tertiary: _adjustColorBrightness(colorScheme.tertiary, brightnessRatio),
      onTertiary: _adjustColorBrightness(
        colorScheme.onTertiary,
        brightnessRatio,
      ),
      tertiaryContainer: _adjustColorBrightness(
        colorScheme.tertiaryContainer,
        brightnessRatio,
      ),
      onTertiaryContainer: _adjustColorBrightness(
        colorScheme.onTertiaryContainer,
        brightnessRatio,
      ),
      error: _adjustColorBrightness(colorScheme.error, brightnessRatio),
      onError: _adjustColorBrightness(colorScheme.onError, brightnessRatio),
      errorContainer: _adjustColorBrightness(
        colorScheme.errorContainer,
        brightnessRatio,
      ),
      onErrorContainer: _adjustColorBrightness(
        colorScheme.onErrorContainer,
        brightnessRatio,
      ),
      background: _adjustColorBrightness(
        colorScheme.background,
        brightnessRatio,
      ),
      onBackground: _adjustColorBrightness(
        colorScheme.onBackground,
        brightnessRatio,
      ),
      surface: _adjustColorBrightness(colorScheme.surface, brightnessRatio),
      onSurface: _adjustColorBrightness(colorScheme.onSurface, brightnessRatio),
      surfaceVariant: _adjustColorBrightness(
        colorScheme.surfaceVariant,
        brightnessRatio,
      ),
      onSurfaceVariant: _adjustColorBrightness(
        colorScheme.onSurfaceVariant,
        brightnessRatio,
      ),
      outline: _adjustColorBrightness(colorScheme.outline, brightnessRatio),
      outlineVariant: _adjustColorBrightness(
        colorScheme.outlineVariant,
        brightnessRatio,
      ),
      shadow: _adjustColorBrightness(colorScheme.shadow, brightnessRatio),
      scrim: _adjustColorBrightness(colorScheme.scrim, brightnessRatio),
      inverseSurface: _adjustColorBrightness(
        colorScheme.inverseSurface,
        brightnessRatio,
      ),
      onInverseSurface: _adjustColorBrightness(
        colorScheme.onInverseSurface,
        brightnessRatio,
      ),
      inversePrimary: _adjustColorBrightness(
        colorScheme.inversePrimary,
        brightnessRatio,
      ),
    );
  }

  // 调整单个颜色的亮度
  Color _adjustColorBrightness(Color color, double ratio) {
    // 限制比例在合理范围内（避免过度调整）
    final clampedRatio = ratio.clamp(1.0, 1.5);

    // 调整 RGB 值
    final r = (color.red * clampedRatio).clamp(0, 255).toInt();
    final g = (color.green * clampedRatio).clamp(0, 255).toInt();
    final b = (color.blue * clampedRatio).clamp(0, 255).toInt();

    return Color.fromARGB(color.alpha, r, g, b);
  }

  // 全局颜色变化监听
  void _onGlobalColorChanged(ColorScheme colorScheme) {
    if (!mounted) return;

    // 检查当前亮度模式是否与变化的颜色方案匹配
    final currentBrightness = Theme.of(context).brightness;
    if (colorScheme.brightness == currentBrightness) {
      _targetCoverColorScheme = colorScheme;
      _startColorAnimation();
      print('✅ 全局颜色变化，更新播放页颜色');
    }
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
    _breathingAnimationController.dispose();
    _waveController.dispose();
    _transitionAnimationController.dispose();

    _pageController.dispose();
    _lyricController.dispose();
    _colorAnimationController.dispose();

    // 移除监听器
    ColorManagerService().removeListener(_onGlobalColorChanged);
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
      final songId = song['id'] ?? '';

      print('🎵 开始加载歌词: $title - $artist');
      print('📡 使用API: ${lyricsApiType.displayName}');

      // 根据用户选择的歌词API类型决定是否使用OpenSubsonic API
      if (songId.isNotEmpty && lyricsApiType != LyricsApiType.customApi) {
        // 只有当用户没有选择自建API时，才尝试使用OpenSubsonic API
        final openSubsonicLyrics = await widget.api.getLyricsBySongId(
          songId: songId,
        );

        if (openSubsonicLyrics != null && openSubsonicLyrics['structuredLyrics'] != null) {
          print('✅ 从OpenSubsonic API获取到带时间轴的歌词');
          
          // 解析结构化歌词为LRC格式
          final structuredLyrics = openSubsonicLyrics['structuredLyrics'] as List;
          if (structuredLyrics.isNotEmpty) {
            final bestLyrics = structuredLyrics[0];
            final lines = bestLyrics['line'] as List;
            
            // 构建LRC格式歌词
            String lrcLyrics = '';
            for (var line in lines) {
              final start = line['start'] ?? 0;
              final value = line['value'] ?? '';
              
              // 转换毫秒为LRC格式时间 [mm:ss.ms]
              final totalSeconds = start / 1000;
              final minutes = (totalSeconds / 60).floor();
              final seconds = (totalSeconds % 60).floor();
              final milliseconds = ((totalSeconds % 1) * 100).floor();
              
              lrcLyrics += '[${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${milliseconds.toString().padLeft(2, '0')}]$value\n';
            }

            // 非自建API，使用逐行歌词
            print('📝 使用LRC格式，逐行显示歌词');
            setState(() {
              _lrcLyrics = lrcLyrics;
              _lyricController.loadLyric(lrcLyrics);
            });
            return;
          }
        }
        print('⚠️ OpenSubsonic API未找到歌词');
      }

      // 如果OpenSubsonic API失败，尝试使用其他API
      if (lyricsApiType == LyricsApiType.subsonic) {
        final lyricData = await widget.api.getLyrics(
          artist: artist,
          title: title,
        );

        if (lyricData != null && lyricData['text'].isNotEmpty) {
          print('✅ 从Subsonic/Navidrome获取到歌词');
          final lyricsText = lyricData['text'];

          // 只有自建API才使用逐字歌词，其余一律逐行
          if (lyricsApiType == LyricsApiType.customApi) {
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
          } else {
            // 非自建API，使用逐行歌词
            print('📝 使用LRC格式，逐行显示歌词');
            setState(() {
              _lrcLyrics = lyricsText;
              _lyricController.loadLyric(lyricsText);
            });
          }
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

      // 预加载歌手头像
      if (currentSong != null) {
        final artistName = currentSong['artist'] as String?;
        final songTitle = currentSong['title'] as String?;
        if (artistName != null &&
            artistName != '未知艺术家') {

        }
      }
    }

    // 检测播放状态变化
    if (newIsPlaying != _isPlaying) {
      _wasPlaying = _isPlaying;
      _isPlaying = newIsPlaying;

      // 触发过渡动画
      if (_isPlaying) {
        _transitionAnimationController.forward();
        // 动画结束后开启波浪动画
        _transitionAnimationController.addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _waveController.waveOn();
          }
        });
      } else {
        _waveController.waveOff();
        _transitionAnimationController.reverse();
      }

      // 触发形状过渡动画
      if (_isPlaying) {
        if (_isInitialized) {
          _shapeAnimationController.forward();
        } else {
          // 初始化时直接设置为播放状态，不触发动画
          _shapeAnimationController.value = 1.0;
          _transitionAnimationController.value = 1.0;
        }
      } else {
        if (_isInitialized) {
          _shapeAnimationController.reverse();
        } else {
          // 初始化时直接设置为暂停状态，不触发动画
          _shapeAnimationController.value = 0.0;
          _transitionAnimationController.value = 0.0;
        }
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

    // 更新波浪进度条（拖动时跳过，避免干扰）
    if (_totalDuration.inMilliseconds > 0 && !_isDraggingProgressBar) {
      final double progress =
          _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
      _waveController.setProgress(progress);
    }

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

  // 预加载歌手头像
  Future<void> _preloadArtistAvatar(
    String artistName,
    String? songTitle,
  ) async {
    // 已移除头像预加载逻辑
  }

  // 使用全局颜色方案
  void _useGlobalColorScheme() {
    final brightness = Theme.of(context).brightness;
    final globalColorScheme = ColorManagerService().getCurrentColorScheme(
      brightness,
    );

    if (globalColorScheme != null && mounted) {
      _targetCoverColorScheme = globalColorScheme;
      _startColorAnimation();
      print('✅ 使用全局颜色方案并启动动画');
    }
  }

  // 启动颜色过渡动画
  void _startColorAnimation() {
    if (_targetCoverColorScheme == null) return;

    // 创建动画曲线
    final curvedAnimation = CurvedAnimation(
      parent: _colorAnimationController,
      curve: Curves.easeInOutCubic, // 使用更自然的缓动曲线
    );

    // 获取当前主题颜色方案
    final currentThemeColorScheme = Theme.of(context).colorScheme;

    // 检查提取的颜色是否比主题颜色更暗（通过亮度比较）
    final isDarkTheme = currentThemeColorScheme.brightness == Brightness.dark;
    final targetSurfaceBrightness = _getColorBrightness(
      _targetCoverColorScheme!.surface,
    );
    final themeSurfaceBrightness = _getColorBrightness(
      currentThemeColorScheme.surface,
    );

    // 如果是深色主题，且提取的颜色比主题颜色更暗，调整提取颜色的亮度
    ColorScheme effectiveTargetColorScheme = _targetCoverColorScheme!;
    if (isDarkTheme && targetSurfaceBrightness < themeSurfaceBrightness) {
      // 调整提取的颜色，使其亮度至少与主题颜色相同
      effectiveTargetColorScheme = _adjustColorSchemeBrightness(
        _targetCoverColorScheme!,
        themeSurfaceBrightness,
      );
    }

    // 创建颜色动画
    _primaryColorAnimation = ColorTween(
      begin: _coverColorScheme?.primary ?? currentThemeColorScheme.primary,
      end: effectiveTargetColorScheme.primary,
    ).animate(curvedAnimation);

    _onPrimaryColorAnimation = ColorTween(
      begin: _coverColorScheme?.onPrimary ?? currentThemeColorScheme.onPrimary,
      end: effectiveTargetColorScheme.onPrimary,
    ).animate(curvedAnimation);

    _onSurfaceColorAnimation = ColorTween(
      begin: _coverColorScheme?.onSurface ?? currentThemeColorScheme.onSurface,
      end: effectiveTargetColorScheme.onSurface,
    ).animate(curvedAnimation);

    _onSurfaceVariantColorAnimation = ColorTween(
      begin:
          _coverColorScheme?.onSurfaceVariant ??
          currentThemeColorScheme.onSurfaceVariant,
      end: effectiveTargetColorScheme.onSurfaceVariant,
    ).animate(curvedAnimation);

    _primaryContainerColorAnimation = ColorTween(
      begin:
          _coverColorScheme?.primaryContainer ??
          currentThemeColorScheme.primaryContainer,
      end: effectiveTargetColorScheme.primaryContainer,
    ).animate(curvedAnimation);

    _onPrimaryContainerColorAnimation = ColorTween(
      begin:
          _coverColorScheme?.onPrimaryContainer ??
          currentThemeColorScheme.onPrimaryContainer,
      end: effectiveTargetColorScheme.onPrimaryContainer,
    ).animate(curvedAnimation);

    _surfaceVariantColorAnimation = ColorTween(
      begin:
          _coverColorScheme?.surfaceVariant ??
          currentThemeColorScheme.surfaceVariant,
      end: effectiveTargetColorScheme.surfaceVariant,
    ).animate(curvedAnimation);

    // 创建tonal surface背景色动画
    final currentPrimary =
        _coverColorScheme?.primary ?? currentThemeColorScheme.primary;
    final currentSurface =
        _coverColorScheme?.surface ?? currentThemeColorScheme.surface;
    final targetPrimary = effectiveTargetColorScheme.primary;
    final targetSurface = effectiveTargetColorScheme.surface;

    _tonalSurfaceAnimation = ColorTween(
      begin: TonalSurfaceHelper.getTonalSurfaceFromColors(
        currentPrimary,
        currentSurface,
      ),
      end: TonalSurfaceHelper.getTonalSurfaceFromColors(
        targetPrimary,
        targetSurface,
      ),
    ).animate(curvedAnimation);

    // 监听动画状态变化
    _colorAnimationController.addListener(() {
      if (mounted) setState(() {});
    });

    _colorAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _coverColorScheme = _targetCoverColorScheme;
        });
      }
    });

    // 启动动画
    _colorAnimationController.forward(from: 0);
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
      case 'random_album':
        return '随机专辑';
      case 'search':
        return '搜索结果';
      case 'recommendation':
      case 'similar':
        return '推荐';
      case 'newest':
        return '最新专辑';
      case 'history':
        return '最近常听';
      case 'song':
        return '歌曲';
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
      // 使用tonal surface作为背景色（Material 3设计：primary以6%不透明度混入surface）
      backgroundColor:
          _tonalSurfaceAnimation?.value ??
          Theme.of(context).colorScheme.surface,
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
    final primaryColor =
        _primaryColorAnimation?.value ??
        _coverColorScheme?.primary ??
        Theme.of(context).colorScheme.primary;
    final onSurfaceColor =
        _onSurfaceColorAnimation?.value ??
        _coverColorScheme?.onSurface ??
        Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariantColor =
        _onSurfaceVariantColorAnimation?.value ??
        _coverColorScheme?.onSurfaceVariant ??
        Theme.of(context).colorScheme.onSurfaceVariant;

    if (!_lyricsEnabled) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lyrics_rounded,
                size: 64,
                color: onSurfaceVariantColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                '歌词功能已关闭',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: onSurfaceVariantColor),
              ),
              const SizedBox(height: 8),
              Text(
                '请在设置中启用歌词',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onSurfaceVariantColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _isLoadingLyrics
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _lrcLyrics.isEmpty
          ? Center(
              child: Text(
                '未找到歌词',
                style: TextStyle(color: onSurfaceVariantColor),
              ),
            )
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
                    color: onSurfaceVariantColor,
                  ),
                  // 激活状态的翻译样式
                  translationActiveColor: onSurfaceVariantColor,
                  // 选中状态的翻译样式
                  selectedTranslationColor: onSurfaceVariantColor,
                  // 翻译行间距
                  translationLineGap: 8.0,
                  // 基本文本样式
                  textStyle: style.textStyle.copyWith(
                    color: onSurfaceVariantColor,
                  ),
                  // 激活状态的文本样式
                  activeStyle: style.activeStyle.copyWith(
                    color: onSurfaceColor,
                    fontWeight: FontWeight.normal,
                  ),
                  // 选中状态的文本样式
                  selectedColor: onSurfaceVariantColor,
                  // 高亮颜色
                  activeHighlightColor: primaryColor.withValues(alpha: 1),
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
    final primaryColor =
        _primaryColorAnimation?.value ??
        _coverColorScheme?.primary ??
        Theme.of(context).colorScheme.primary;
    final primaryContainerColor =
        _primaryContainerColorAnimation?.value ??
        _coverColorScheme?.primaryContainer ??
        Theme.of(context).colorScheme.primaryContainer;
    final onPrimaryContainerColor =
        _onPrimaryContainerColorAnimation?.value ??
        _coverColorScheme?.onPrimaryContainer ??
        Theme.of(context).colorScheme.onPrimaryContainer;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 来源和歌名
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryContainerColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _getSourceText(),
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: onPrimaryContainerColor),
            ),
          ),
        ],
      ),
    );
  }

  // 专辑封面区域
  Widget _buildAlbumCover(Map<String, dynamic> song) {
    final primaryColor =
        _primaryColorAnimation?.value ??
        _coverColorScheme?.primary ??
        Theme.of(context).colorScheme.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 360),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24)),
          child: Hero(
            tag: 'album_cover',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: song['coverArt'] != null
                  ? CachedNetworkImage(
                      imageUrl: widget.api.getCoverArtUrl(song['coverArt']),
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildDefaultCover(),
                      errorWidget: (context, url, error) =>
                          _buildDefaultCover(),
                    )
                  : _buildDefaultCover(),
            ),
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
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(50),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(30),
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
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withAlpha(30),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(50),
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
    final primaryColor =
        _primaryColorAnimation?.value ??
        _coverColorScheme?.primary ??
        Theme.of(context).colorScheme.primary;
    final onPrimaryColor =
        _onPrimaryColorAnimation?.value ??
        _coverColorScheme?.onPrimary ??
        Theme.of(context).colorScheme.onPrimary;
    final onSurfaceColor =
        _onSurfaceColorAnimation?.value ??
        _coverColorScheme?.onSurface ??
        Theme.of(context).colorScheme.onSurface;
    final onSurfaceVariantColor =
        _onSurfaceVariantColorAnimation?.value ??
        _coverColorScheme?.onSurfaceVariant ??
        Theme.of(context).colorScheme.onSurfaceVariant;
    final primaryContainerColor =
        _primaryContainerColorAnimation?.value ??
        _coverColorScheme?.primaryContainer ??
        Theme.of(context).colorScheme.primaryContainer;
    final onPrimaryContainerColor =
        _onPrimaryContainerColorAnimation?.value ??
        _coverColorScheme?.onPrimaryContainer ??
        Theme.of(context).colorScheme.onPrimaryContainer;
    final surfaceVariantColor =
        _surfaceVariantColorAnimation?.value ??
        _coverColorScheme?.surfaceVariant ??
        Theme.of(context).colorScheme.surfaceVariant;

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
                                color: onSurfaceColor,
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
                            final artistName = song['artist'] as String;
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
                                color: onSurfaceVariantColor,
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
                  WaveLinearProgressIndicator(
                    controller: _waveController,
                    primaryColor: primaryColor,
                    surfaceVariantColor: surfaceVariantColor,
                    onTap: (double progress) {
                      final double newValue =
                          progress * _totalDuration.inMilliseconds.toDouble();
                      widget.playerService.seekTo(
                        Duration(milliseconds: newValue.toInt()),
                      );
                    },
                    onDragStart: () {
                      setState(() {
                        _isDraggingProgressBar = true;
                      });
                    },
                    onDragEnd: () {
                      setState(() {
                        _isDraggingProgressBar = false;
                      });
                    },
                    transitionAnimation: _transitionAnimation,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(_currentPosition),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: onSurfaceVariantColor),
                        ),
                        Text(
                          _formatDuration(_totalDuration),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: onSurfaceVariantColor),
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
                  primaryContainerColor: primaryContainerColor,
                  onPrimaryContainerColor: onPrimaryContainerColor,
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
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                          child: Center(
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: onPrimaryColor,
                              size: 32,
                            ),
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
                  primaryContainerColor: primaryContainerColor,
                  onPrimaryContainerColor: onPrimaryContainerColor,
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
    required Color primaryContainerColor,
    required Color onPrimaryContainerColor,
  }) {
    return GestureDetector(
      onTapDown: (_) => _playButtonController.forward(),
      onTapUp: (_) => _playButtonController.reverse(),
      onTapCancel: () => _playButtonController.reverse(),
      onTap: onPressed,
      child: AnimatedBuilder(
        animation: _playButtonScale,
        builder: (context, child) {
          return Transform.scale(
            scale: _playButtonScale.value,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryContainerColor.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: onPrimaryContainerColor, size: 28),
            ),
          );
        },
      ),
    );
  }
}

class WaveLinearProgressController extends ChangeNotifier {
  double progress = 0;
  double phase = 0;
  late Ticker ticker;

  WaveLinearProgressController() {
    ticker = Ticker((elapsed) {
      if (phase < 2 * pi) {
        phase += pi / 48;
      } else if (phase >= 2 * pi) {
        phase = 0;
      }
      notifyListeners();
    });
  }

  void setProgress(double newProgress) {
    progress = newProgress;
    notifyListeners();
  }

  void waveOn() {
    if (!ticker.isActive) {
      ticker.start();
    }
  }

  void waveOff() {
    ticker.stop();
  }

  @override
  void dispose() {
    super.dispose();
    ticker.dispose();
  }
}

class WaveLinearProgressIndicator extends StatefulWidget {
  const WaveLinearProgressIndicator({
    super.key,
    required this.controller,
    required this.primaryColor,
    required this.surfaceVariantColor,
    required this.onTap,
    this.onDragStart,
    this.onDragEnd,
    this.transitionAnimation,
  });

  final WaveLinearProgressController controller;
  final Color primaryColor;
  final Color surfaceVariantColor;
  final Function(double) onTap;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final Animation<double>? transitionAnimation;

  @override
  State<WaveLinearProgressIndicator> createState() => _WaveLinearProgressIndicatorState();
}

class _WaveLinearProgressIndicatorState extends State<WaveLinearProgressIndicator> {
  bool _isDragging = false;
  double _cachedProgress = 0;

  @override
  void initState() {
    super.initState();
    _cachedProgress = widget.controller.progress;
  }

  void _updateProgress(Offset localPosition) {
    final box = context.findRenderObject() as RenderBox;
    final double width = box.size.width;
    double progress = localPosition.dx / width;
    
    // 确保进度值在 0-1 范围内
    progress = progress.clamp(0.0, 1.0);
    
    setState(() {
      widget.controller.setProgress(progress);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (DragStartDetails details) {
        _isDragging = true;
        widget.onDragStart?.call();
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        _updateProgress(localPosition);
      },
      onPanUpdate: (DragUpdateDetails details) {
        if (_isDragging) {
          final box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          _updateProgress(localPosition);
        }
      },
      onPanEnd: (DragEndDetails details) {
        if (_isDragging) {
          _isDragging = false;
          widget.onTap(widget.controller.progress);
          widget.onDragEnd?.call();
          _cachedProgress = widget.controller.progress;
        }
      },
      onPanCancel: () {
        if (_isDragging) {
          _isDragging = false;
          widget.onDragEnd?.call();
          setState(() {
            widget.controller.setProgress(_cachedProgress);
          });
        }
      },
      onTapDown: (TapDownDetails details) {
        // 处理点击事件
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final double width = box.size.width;
        double progress = localPosition.dx / width;
        progress = progress.clamp(0.0, 1.0);
        widget.onTap(progress);
      },
      child: CustomPaint(
        size: Size(double.infinity, 40),
        painter: WaveLinearPainter(
          controller: widget.controller,
          primaryColor: widget.primaryColor,
          surfaceVariantColor: widget.surfaceVariantColor,
          transitionAnimation: widget.transitionAnimation,
        ),
      ),
    );
  }
}

class WaveLinearPainter extends CustomPainter {
  final WaveLinearProgressController controller;
  final Color primaryColor;
  final Color surfaceVariantColor;
  final Animation<double>? transitionAnimation;

  WaveLinearPainter({
    required this.controller,
    required this.primaryColor,
    required this.surfaceVariantColor,
    this.transitionAnimation,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    var painter = Paint()..color = primaryColor; //2080E5

    Path path = Path();
    path.moveTo(0, (size.height / 2));
    painter.strokeWidth = 4.0;

    ///线条
    painter.style = PaintingStyle.stroke;

    // 获取过渡动画值，默认为1.0（完全波浪）
    double transitionValue = transitionAnimation?.value ?? 1.0;

    for (double i = 1; i <= size.width * controller.progress; i++) {
      // 根据过渡动画值混合直线和波浪
      double waveAmplitude = 2 * transitionValue;
      double y =
          waveAmplitude * sin((2 * pi * i / 24.0) + controller.phase) +
          (size.height / 2);
      path.lineTo(i, y);
    }
    canvas.drawPath(path, painter);

    ///未完成进度条
    painter.style = PaintingStyle.fill;
    painter.color = surfaceVariantColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * controller.progress,
          (size.height / 2 - 2),
          size.width * (1 - controller.progress),
          4.0,
        ),
        const Radius.circular(2.0),
      ),
      painter,
    );

    ///滑块
    painter.color = primaryColor;
    canvas.drawCircle(
      Offset(size.width * controller.progress, (size.height / 2)),
      8.0,
      painter,
    );
  }

  @override
  bool shouldRepaint(covariant WaveLinearPainter oldDelegate) => false;
}

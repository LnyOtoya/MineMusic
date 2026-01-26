import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subsonic_api.dart';
import 'audio_handler.dart';
import 'play_history_service.dart';
import 'playback_state_service.dart';
import 'color_manager_service.dart';
import '../models/lyrics_api_type.dart';

class PlayerService extends ChangeNotifier {
  late MyAudioHandler _audioHandler;
  final SubsonicApi? _api;
  final PlayHistoryService _historyService = PlayHistoryService();
  final PlaybackStateService _playbackStateService = PlaybackStateService();

  // 歌词API类型
  static final ValueNotifier<LyricsApiType> lyricsApiTypeNotifier =
      ValueNotifier(LyricsApiType.disabled);
  static final ValueNotifier<bool> lyricsEnabledNotifier = ValueNotifier(false);

  // 播放状态相关变量
  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  String _sourceType = '';
  List<Map<String, dynamic>> _currentPlaylist = [];
  int _currentIndex = -1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  // Getters
  Map<String, dynamic>? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  String get sourceType => _sourceType;
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  List<Map<String, dynamic>> get playlist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  PlayHistoryService get historyService => _historyService;

  PlayerService({SubsonicApi? api}) : _api = api {
    _initialize();
  }

  Future<void> _initialize() async {
    await _initAudioService();
    await _loadLyricsSettings();
    await _loadPlaybackState();
  }

  Future<void> _loadLyricsSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLyricsApiType = prefs.getString('lyricsApiType');
    final savedLyricsEnabled = prefs.getBool('lyricsEnabled') ?? false;

    if (savedLyricsApiType != null) {
      lyricsApiTypeNotifier.value = LyricsApiTypeExtension.fromString(
        savedLyricsApiType,
      );
    }
    lyricsEnabledNotifier.value = savedLyricsEnabled;
  }

  Future<void> _loadPlaybackState() async {
    // 恢复当前歌曲和播放列表
    final savedSong = await _playbackStateService.getCurrentSong();
    final savedPlaylist = await _playbackStateService.getPlaylist();
    print('已获取保存的歌曲: ${savedSong != null}');
    print(
      '已获取保存的播放列表: ${savedPlaylist != null}, 包含 ${savedPlaylist?.length ?? 0} 首歌曲',
    );
    if (savedSong != null && _api != null) {
      // 加载歌曲但不自动播放
      await _loadSongWithoutPlaying(savedSong, playlist: savedPlaylist);
    }
  }

  Future<void> _loadSongWithoutPlaying(
    Map<String, dynamic> song, {
    List<Map<String, dynamic>>? playlist,
  }) async {
    // 检查 audioHandler 是否初始化完成
    if (_audioHandler == null) {
      print('音频处理程序未初始化，无法加载歌曲');
      return;
    }

    print('正在加载歌曲: ${song['title']}, 播放列表包含 ${playlist?.length ?? 0} 首歌曲');

    // 将歌曲添加到音频处理程序的队列中
    await _audioHandler.loadSong(song, playlist: playlist);

    // 恢复播放进度
    final savedPosition = await _playbackStateService.getPlaybackPosition();
    if (savedPosition > Duration.zero) {
      await _audioHandler.seek(savedPosition);
    }

    // 更新当前歌曲信息
    _currentSong = song;
    _totalDuration = song['duration'] != null
        ? Duration(seconds: int.tryParse(song['duration'].toString()) ?? 0)
        : Duration.zero;
    _currentPosition = await _playbackStateService.getPlaybackPosition();

    // 如果 sourceType 为空，设置一个默认值
    if (_sourceType.isEmpty) {
      _sourceType = 'song';
    }

    // 从专辑封面提取颜色方案
    _updateColorSchemeFromCurrentSong();

    notifyListeners();
  }

  static Future<void> setLyricsApiType(LyricsApiType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lyricsApiType', type.name);
    lyricsApiTypeNotifier.value = type;
  }

  static Future<void> setLyricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lyricsEnabled', enabled);
    lyricsEnabledNotifier.value = enabled;
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(_api!),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.minemusic.channel.audio',
        androidNotificationChannelName: 'MineMusic',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'drawable/ic_launcher_monochrome',
      ),
    );

    _setupListeners();
  }

  void _setupListeners() {
    // 监听播放状态
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _currentPosition = state.position;

      // 保存播放进度
      if (_currentSong != null) {
        _playbackStateService.savePlaybackPosition(_currentPosition);
      }

      notifyListeners();
    });

    // 监听当前媒体项
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _currentSong = mediaItem.extras?['song_data'];
        _totalDuration = mediaItem.duration ?? Duration.zero;

        // 保存当前歌曲
        _playbackStateService.saveCurrentSong(_currentSong);

        // 当歌曲切换时，从专辑封面提取颜色方案
        if (_currentSong != null && _api != null) {
          _updateColorSchemeFromCurrentSong();
        }

        notifyListeners();
      }
    });

    // 监听队列
    _audioHandler.queue.listen((queue) {
      if (queue.isNotEmpty) {
        _currentPlaylist = queue
            .where((item) => item.extras?['song_data'] != null)
            .map((item) => item.extras!['song_data'] as Map<String, dynamic>)
            .toList();
        // 保存播放列表
        _playbackStateService.savePlaylist(_currentPlaylist);
        notifyListeners();
      }
    });
  }

  Future<void> playSong(
    Map<String, dynamic> song, {
    required String sourceType,
    List<Map<String, dynamic>>? playlist,
  }) async {
    _sourceType = sourceType;
    await _historyService.addToHistory(song);
    await _audioHandler.playSong(song, playlist: playlist);

    // 保存播放列表
    if (playlist != null && playlist.isNotEmpty) {
      await _playbackStateService.savePlaylist(playlist);
      print('已保存完整播放列表，包含 ${playlist.length} 首歌曲');
    }

    // 恢复播放进度
    final savedPosition = await _playbackStateService.getPlaybackPosition();
    if (savedPosition > Duration.zero) {
      await seekTo(savedPosition);
    }
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    await _audioHandler.play();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> nextSong() async {
    await _audioHandler.skipToNext();
  }

  Future<void> previousSong() async {
    await _audioHandler.skipToPrevious();
  }

  Future<void> playSongAt(int index) async {
    await _audioHandler.skipToIndex(index);
  }

  Future<void> seekTo(Duration position) async {
    await _audioHandler.seek(position);
  }

  void addToPlaylist(List<Map<String, dynamic>> songs) {
    _audioHandler.addToQueue(songs);
  }

  Future<void> clearPlaylist() async {
    await _audioHandler.clearQueue();
    _currentPlaylist.clear();
    _currentIndex = -1;
    _currentSong = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getRecentSongs({int count = 10}) async {
    return await _historyService.getRecentSongs(count: count);
  }

  Future<void> clearHistory() async {
    await _historyService.clearHistory();
  }

  // 从当前播放歌曲的专辑封面提取颜色方案
  void _updateColorSchemeFromCurrentSong() {
    if (_currentSong == null || _api == null) return;

    final coverArt = _currentSong!['coverArt'];
    if (coverArt == null) return;

    // 获取封面艺术URL
    final coverArtUrl = _api!.getCoverArtUrl(coverArt);

    // 提取浅色和深色模式的颜色方案
    _extractColorScheme(coverArt, coverArtUrl, Brightness.light);
    _extractColorScheme(coverArt, coverArtUrl, Brightness.dark);
  }

  // 提取颜色方案
  Future<void> _extractColorScheme(
    String coverArtId,
    String coverArtUrl,
    Brightness brightness,
  ) async {
    try {
      await ColorManagerService().extractColorSchemeFromCover(
        coverArtId,
        coverArtUrl,
        brightness,
      );
    } catch (e) {
      print('提取封面颜色失败: $e');
    }
  }

  @override
  void dispose() {
    _audioHandler.stop();
    _audioHandler.customDispose();
    super.dispose();
  }
}

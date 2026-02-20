import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subsonic_api.dart';
import 'audio_handler.dart';
import 'play_history_service.dart';
import 'playback_state_service.dart';
import '../utils/native_channel.dart';

enum PlaybackMode {
  sequential,
  shuffle,
  repeatAll,
  repeatOne,
}

extension PlaybackModeExtension on PlaybackMode {
  String get displayName {
    switch (this) {
      case PlaybackMode.sequential:
        return '顺序播放';
      case PlaybackMode.shuffle:
        return '随机播放';
      case PlaybackMode.repeatAll:
        return '列表循环';
      case PlaybackMode.repeatOne:
        return '单曲循环';
    }
  }

  IconData get icon {
    switch (this) {
      case PlaybackMode.sequential:
        return Icons.replay;
      case PlaybackMode.shuffle:
        return Icons.shuffle;
      case PlaybackMode.repeatAll:
        return Icons.repeat;
      case PlaybackMode.repeatOne:
        return Icons.repeat_one;
    }
  }

  static PlaybackMode fromString(String value) {
    switch (value) {
      case 'sequential':
        return PlaybackMode.sequential;
      case 'shuffle':
        return PlaybackMode.shuffle;
      case 'repeatOne':
        return PlaybackMode.repeatOne;
      case 'repeat':
        return PlaybackMode.repeatAll;
      case 'repeatAll':
        return PlaybackMode.repeatAll;
      default:
        return PlaybackMode.sequential;
    }
  }
}

class PlayerService extends ChangeNotifier {
  late MyAudioHandler _audioHandler;
  SubsonicApi? _api;
  final PlayHistoryService _historyService = PlayHistoryService();
  final PlaybackStateService _playbackStateService = PlaybackStateService();

  // 播放模式
  PlaybackMode _playbackMode = PlaybackMode.sequential;
  static final ValueNotifier<PlaybackMode> playbackModeNotifier =
      ValueNotifier(PlaybackMode.sequential);

  // 播放进度通知器
  static final ValueNotifier<Duration> positionNotifier =
      ValueNotifier(Duration.zero);

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
  PlaybackMode get playbackMode => _playbackMode;
  PlayHistoryService get historyService => _historyService;

  PlayerService({SubsonicApi? api}) : _api = api;

  // 更新 API 实例
  void updateApi(SubsonicApi? api) {
    _api = api;
  }

  Future<void> initialize() async {
    try {
      if (_api == null) {
        print('PlayerService 初始化警告：SubsonicApi 未设置');
      }
      
      await _initAudioService();
      
      await _loadPlaybackMode();
      await _loadPlaybackState();
      
      print('PlayerService 初始化完成');
    } catch (e) {
      print('PlayerService 初始化失败: $e');
      if (e.toString().contains('AudioServiceException')) {
        print('音频服务初始化失败，请检查音频权限');
      } else if (e.toString().contains('PlatformException')) {
        print('平台异常：可能是权限或配置问题');
      }
      rethrow;
    }
  }

  Future<void> _loadPlaybackMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlaybackMode = prefs.getString('playbackMode');
    if (savedPlaybackMode != null) {
      _playbackMode = PlaybackModeExtension.fromString(savedPlaybackMode);
      playbackModeNotifier.value = _playbackMode;
    }
  }

  Future<void> _savePlaybackMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('playbackMode', _playbackMode.name);
  }

  Future<void> _loadPlaybackState() async {
    // 恢复当前歌曲和播放列表
    final savedSong = await _playbackStateService.getCurrentSong();
    final savedPlaylist = await _playbackStateService.getPlaylist();
    final savedSourceType = await _playbackStateService.getSourceType();
    print('已获取保存的歌曲: ${savedSong != null}');
    print(
      '已获取保存的播放列表: ${savedPlaylist != null}, 包含 ${savedPlaylist?.length ?? 0} 首歌曲',
    );
    print('已获取保存的播放来源: $savedSourceType');
    
    if (savedSong != null && _api != null) {
      // 恢复播放来源
      _sourceType = savedSourceType;
      // 只恢复歌曲信息，不立即加载音频（避免启动时触发解码器初始化）
      _currentSong = savedSong;
      _totalDuration = savedSong['duration'] != null
          ? Duration(seconds: int.tryParse(savedSong['duration'].toString()) ?? 0)
          : Duration.zero;
      _currentPosition = await _playbackStateService.getPlaybackPosition();
      
      // 保存播放列表但不加载到音频播放器
      if (savedPlaylist != null && savedPlaylist.isNotEmpty) {
        _currentPlaylist = savedPlaylist;
      }
      
      print('已恢复播放状态（仅元数据，未加载音频）');
      notifyListeners();
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

    // 立即更新当前歌曲信息，避免播放器初始化过程中显示错误的歌曲
    _currentSong = song;
    _totalDuration = song['duration'] != null
        ? Duration(seconds: int.tryParse(song['duration'].toString()) ?? 0)
        : Duration.zero;
    _currentPosition = await _playbackStateService.getPlaybackPosition();

    // 如果 sourceType 为空，设置一个默认值
    if (_sourceType.isEmpty) {
      _sourceType = 'song';
    }

    // 立即通知监听器，显示正确的歌曲信息
    notifyListeners();

    // 将歌曲添加到音频处理程序的队列中
    await _audioHandler.loadSong(song, playlist: playlist);

    // 恢复播放进度
    final savedPosition = await _playbackStateService.getPlaybackPosition();
    if (savedPosition > Duration.zero) {
      await _audioHandler.seek(savedPosition);
    }
  }

  Future<void> _initAudioService() async {
    if (_api == null) {
      print('警告：SubsonicApi 未初始化，无法初始化音频服务');
      return;
    }

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

  // 启动时忽略错误歌曲事件的标志
  bool _ignoreInitialMediaItemEvents = true;
  
  void _setupListeners() {
    // 监听播放状态
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _currentPosition = state.position;
      positionNotifier.value = state.position;

      // 保存播放进度
      if (_currentSong != null) {
        _playbackStateService.savePlaybackPosition(_currentPosition);
      }

      // 同步播放状态到原生（小部件显示）
      if (_currentSong != null) {
        NativeChannel.syncPlayState(
          songTitle: _currentSong!['title'] ?? '未知歌曲',
          artist: _currentSong!['artist'] ?? '未知艺术家',
          coverId: _currentSong!['coverArt'] ?? '',
          isPlaying: _isPlaying,
        );
      }

      notifyListeners();
    });

    // 监听当前媒体项
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        // 检查是否是启动时的错误歌曲事件
        if (_ignoreInitialMediaItemEvents && _currentSong != null) {
          // 获取媒体项中的歌曲ID
          final mediaItemSongId = mediaItem.id;
          // 获取当前歌曲的ID
          final currentSongId = _currentSong?['id'];
          
          // 只有当媒体项的歌曲ID与当前歌曲的ID不同时，才忽略这个事件
          // 这样可以确保启动时的错误歌曲事件被忽略，而正常的歌曲切换事件仍然会被处理
          if (mediaItemSongId != currentSongId) {
            print('忽略启动时的错误歌曲事件: ${mediaItem.title}');
            return;
          } else {
            // 如果ID相同，说明是正确的歌曲事件，取消忽略标志
            _ignoreInitialMediaItemEvents = false;
          }
        }
        
        // 正常处理歌曲变化事件
        _currentSong = mediaItem.extras?['song_data'];
        _totalDuration = mediaItem.duration ?? Duration.zero;

        print('🎵 歌曲已切换: ${_currentSong?['title']} - ${_currentSong?['artist']}');

        // 保存当前歌曲
        _playbackStateService.saveCurrentSong(_currentSong);

        // 同步播放状态到原生（小部件显示）
        if (_currentSong != null) {
          NativeChannel.syncPlayState(
            songTitle: _currentSong!['title'] ?? '未知歌曲',
            artist: _currentSong!['artist'] ?? '未知艺术家',
            coverId: _currentSong!['coverArt'] ?? '',
            isPlaying: _isPlaying,
          );
        }

        // 启动完成后，允许处理所有歌曲变化事件
        if (_ignoreInitialMediaItemEvents && _currentSong != null) {
          _ignoreInitialMediaItemEvents = false;
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
    await _playbackStateService.saveSourceType(sourceType);
    
    // 重置忽略标志，允许歌曲信息更新
    _ignoreInitialMediaItemEvents = false;
    
    // 检查当前是否已经在播放同一首歌
    if (_currentSong != null && _currentSong!['id'] == song['id']) {
      // 如果已经在播放同一首歌，只需要恢复播放即可
      if (!_isPlaying) {
        await resume();
      }
      return;
    }
    
    await _historyService.addToHistory(song);
    
    // 如果是首次播放（音频播放器中没有歌曲），使用 loadSong 而不是 playSong
    if (_audioHandler.currentSong == null) {
      print('首次播放，使用 loadSong 加载音频');
      await _audioHandler.loadSong(song, playlist: playlist);
      
      // 恢复播放进度
      final savedPosition = await _playbackStateService.getPlaybackPosition();
      if (savedPosition > Duration.zero) {
        await _audioHandler.seek(savedPosition);
      }
      
      // 开始播放
      await _audioHandler.play();
    } else {
      // 正常播放
      await _audioHandler.playSong(song, playlist: playlist);
      
      // 恢复播放进度
      final savedPosition = await _playbackStateService.getPlaybackPosition();
      if (savedPosition > Duration.zero) {
        await seekTo(savedPosition);
      }
    }

    // 保存播放列表
    if (playlist != null && playlist.isNotEmpty) {
      await _playbackStateService.savePlaylist(playlist);
      print('已保存完整播放列表，包含 ${playlist.length} 首歌曲');
    }
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> resume() async {
    // 重置忽略标志，允许歌曲信息更新
    _ignoreInitialMediaItemEvents = false;
    
    // 检查是否需要先加载音频（首次播放时）
    if (_currentSong != null && _audioHandler.currentSong == null) {
      print('首次播放，加载音频到播放器');
      await _audioHandler.loadSong(_currentSong!, playlist: _currentPlaylist);
      
      // 恢复播放进度
      if (_currentPosition > Duration.zero) {
        await _audioHandler.seek(_currentPosition);
      }
    }
    
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
    // 重置忽略标志，允许歌曲信息更新
    _ignoreInitialMediaItemEvents = false;
    
    // 检查是否需要先加载音频（首次播放时）
    if (_currentSong != null && _audioHandler.currentSong == null && _currentPlaylist.isNotEmpty) {
      print('首次播放，加载音频到播放器');
      await _audioHandler.loadSong(_currentSong!, playlist: _currentPlaylist);
    }
    
    switch (_playbackMode) {
      case PlaybackMode.shuffle:
        await _playRandomSong();
        break;
      case PlaybackMode.repeatOne:
        await _audioHandler.seek(Duration.zero);
        await _audioHandler.play();
        break;
      case PlaybackMode.repeatAll:
        if (_currentIndex < _currentPlaylist.length - 1) {
          await _audioHandler.skipToNext();
        } else {
          await _audioHandler.skipToIndex(0);
        }
        break;
      case PlaybackMode.sequential:
        await _audioHandler.skipToNext();
        break;
    }
  }

  Future<void> previousSong() async {
    // 重置忽略标志，允许歌曲信息更新
    _ignoreInitialMediaItemEvents = false;
    
    await _audioHandler.skipToPrevious();
  }

  Future<void> _playRandomSong() async {
    if (_currentPlaylist.isEmpty) return;
    
    final random = Random();
    int randomIndex;
    
    if (_currentPlaylist.length == 1) {
      randomIndex = 0;
    } else {
      do {
        randomIndex = random.nextInt(_currentPlaylist.length);
      } while (randomIndex == _currentIndex);
    }
    
    await _audioHandler.skipToIndex(randomIndex);
  }

  void togglePlaybackMode() {
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        _playbackMode = PlaybackMode.shuffle;
        break;
      case PlaybackMode.shuffle:
        _playbackMode = PlaybackMode.repeatOne;
        break;
      case PlaybackMode.repeatOne:
        _playbackMode = PlaybackMode.sequential;
        break;
      case PlaybackMode.repeatAll:
        _playbackMode = PlaybackMode.sequential;
        break;
    }
    playbackModeNotifier.value = _playbackMode;
    _savePlaybackMode();
  }

  void toggleShuffle() {
    if (_playbackMode == PlaybackMode.shuffle) {
      _playbackMode = PlaybackMode.sequential;
    } else {
      _playbackMode = PlaybackMode.shuffle;
    }
    playbackModeNotifier.value = _playbackMode;
    notifyListeners();
    _savePlaybackMode();
  }

  void toggleRepeat() {
    switch (_playbackMode) {
      case PlaybackMode.sequential:
        _playbackMode = PlaybackMode.repeatAll;
        break;
      case PlaybackMode.repeatAll:
        _playbackMode = PlaybackMode.repeatOne;
        break;
      case PlaybackMode.repeatOne:
        _playbackMode = PlaybackMode.sequential;
        break;
      case PlaybackMode.shuffle:
        _playbackMode = PlaybackMode.repeatAll;
        break;
    }
    playbackModeNotifier.value = _playbackMode;
    notifyListeners();
    _savePlaybackMode();
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

  @override
  void dispose() {
    _audioHandler.stop();
    _audioHandler.customDispose();
    super.dispose();
  }
}

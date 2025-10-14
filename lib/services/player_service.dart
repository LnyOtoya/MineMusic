import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'subsonic_api.dart';
import 'audio_handler.dart';

class PlayerService extends ChangeNotifier {
  late MyAudioHandler _audioHandler;
  final SubsonicApi? _api;

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
  int get currentIndex => _currentIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  PlayerService({SubsonicApi? api}) : _api = api {
    _initAudioService();
  }

  Future<void> _initAudioService() async {
    _audioHandler = await AudioService.init(
      builder: () => MyAudioHandler(_api!),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.minemusic.channel.audio',
        androidNotificationChannelName: 'MineMusic',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    _setupListeners();
  }

  void _setupListeners() {
    // 监听播放状态
    _audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      _currentPosition = state.position;
      notifyListeners();
    });

    // 监听当前媒体项
    _audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        _currentSong = mediaItem.extras?['song_data'];
        _totalDuration = mediaItem.duration ?? Duration.zero;
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
    await _audioHandler.playSong(song, playlist: playlist);
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

  @override
  void dispose() {
    _audioHandler.stop();
    _audioHandler.customDispose();
    super.dispose();
  }
}
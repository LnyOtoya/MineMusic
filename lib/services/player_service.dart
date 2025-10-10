import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'subsonic_api.dart'; // 导入SubsonicApi用于生成播放链接
// import 'package:permission_handler/permission_handler.dart';


class PlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final SubsonicApi? _api; // 用于生成播放链接

  Map<String, dynamic>? _currentSong;
  bool _isPlaying = false;
  String _sourceType = '';
  List<Map<String, dynamic>> _currentPlaylist = [];
  int _currentIndex = -1;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  //  getter方法
  Map<String, dynamic>? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  String get sourceType => _sourceType;
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // 构造函数初始化监听
  PlayerService({SubsonicApi? api}) : _api = api {
    _initAudioListeners();
  }

  // 初始化音频监听
  void _initAudioListeners() {
    // 监听播放状态变化
    _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) {
        notifyListeners();
      }
    });

    // 监听播放进度
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // 监听总时长变化
    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // 监听播放完成（自动播放下一首）
    _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        nextSong();
      }
    });
  }



  // Future<void> requestAndroid13Permissions() async {
  //   // 1. 申请通知权限（媒体通知、后台播放必需）
  //   if (await Permission.notification.isDenied) {
  //     await Permission.notification.request();
  //   }

  //   // 2. 若需要缓存音乐到本地，申请媒体文件访问权限
  //   if (await Permission.audio.isDenied) {
  //     await Permission.audio.request();
  //   }

  //   // 3. 检查网络权限（虽然 INTERNET 是普通权限，但可提示用户检查网络）
  //   if (await Permission.internet.isDenied) {
  //     await Permission.internet.request();
  //   }
  // }


  // 播放指定歌曲，可附带播放列表
  Future<void> playSong(
    Map<String, dynamic> song, {
    required String sourceType,
    List<Map<String, dynamic>>? playlist,
  }) async {
    print('🎵 PlayerService: 开始播放歌曲 - ${song['title']}');
    print('🎵 PlayerService: 来源类型 - $sourceType');

    _currentSong = song;
    _sourceType = sourceType;

    // 更新播放列表
    if (playlist != null) {
      _currentPlaylist = playlist;
      _currentIndex = _currentPlaylist.indexWhere((s) => s['id'] == song['id']);
      if (_currentIndex == -1) {
        _currentPlaylist.add(song);
        _currentIndex = _currentPlaylist.length - 1;
      }
    } else if (_currentPlaylist.isEmpty || !_currentPlaylist.any((s) => s['id'] == song['id'])) {
      _currentPlaylist = [song];
      _currentIndex = 0;
    } else {
      _currentIndex = _currentPlaylist.indexWhere((s) => s['id'] == song['id']);
    }

    // 加载并播放音频
    try {
      if (_api == null) {
        throw Exception("SubsonicApi 未初始化，无法获取播放链接");
      }

      // 获取播放链接（使用Subsonic的stream接口）
      final playUrl = _api.getSongPlayUrl(song['id']!);
      await _audioPlayer.setUrl(playUrl);
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print('播放失败: $e');
      _isPlaying = false;
    }

    notifyListeners();
  }

  // 暂停播放
  Future<void> pause() async {
    if (_isPlaying) {
      print('🎵 PlayerService: 暂停播放');
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  // 恢复播放
  Future<void> resume() async {
    if (!_isPlaying && _currentSong != null) {
      print('🎵 PlayerService: 恢复播放');
      await _audioPlayer.play();
      _isPlaying = true;
      notifyListeners();
    }
  }

  // 切换播放/暂停状态
  Future<void> togglePlayPause() async {
    print('🎵 PlayerService: 切换播放/暂停');
    if (_isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  // 播放下一首
  Future<void> nextSong() async {
    if (_currentPlaylist.isEmpty) return;

    print('🎵 PlayerService: 下一首');
    _currentIndex = (_currentIndex + 1) % _currentPlaylist.length;
    _currentSong = _currentPlaylist[_currentIndex];
    
    try {
      final playUrl = _api!.getSongPlayUrl(_currentSong!['id']!);
      await _audioPlayer.setUrl(playUrl);
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print('下一首播放失败: $e');
      _isPlaying = false;
    }
    
    notifyListeners();
  }

  // 播放上一首
  Future<void> previousSong() async {
    if (_currentPlaylist.isEmpty) return;

    print('🎵 PlayerService: 上一首');
    _currentIndex = (_currentIndex - 1 + _currentPlaylist.length) % _currentPlaylist.length;
    _currentSong = _currentPlaylist[_currentIndex];
    
    try {
      final playUrl = _api!.getSongPlayUrl(_currentSong!['id']!);
      await _audioPlayer.setUrl(playUrl);
      await _audioPlayer.play();
      _isPlaying = true;
    } catch (e) {
      print('上一首播放失败: $e');
      _isPlaying = false;
    }
    
    notifyListeners();
  }

  // 调整播放进度
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  // 添加歌曲到播放列表
  void addToPlaylist(List<Map<String, dynamic>> songs) {
    _currentPlaylist.addAll(songs);
    notifyListeners();
  }

  // 清空播放列表
  Future<void> clearPlaylist() async {
    await _audioPlayer.stop();
    _currentPlaylist.clear();
    _currentIndex = -1;
    _currentSong = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  // 释放资源
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

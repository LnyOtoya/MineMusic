import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'subsonic_api.dart'; // 导入SubsonicApi用于生成播放链接


//ChangeNotifier允许ui组件监听其状态变化，如播放 暂停 切换歌曲等，实现状态同步
class PlayerService extends ChangeNotifier {

  //just_audio实例，处理底层播放
  final AudioPlayer _audioPlayer = AudioPlayer();
  //用于生成播放链接
  final SubsonicApi? _api;


  //播放状态相关变量
  //当前播放的歌曲信息，如id 标题 艺术家等
  Map<String, dynamic>? _currentSong;
  //是否正在播放
  bool _isPlaying = false;
  //歌曲来源，用于ui显示来源信息
  String _sourceType = '';
  //当前播放列表
  List<Map<String, dynamic>> _currentPlaylist = [];
  //当前歌曲在播放列表中的索引
  int _currentIndex = -1;
  //当前播放进度
  Duration _currentPosition = Duration.zero;
  //歌曲总时长
  Duration _totalDuration = Duration.zero;

  //  getter方法：提供只读访问，避免外部直接修改状态
  Map<String, dynamic>? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  String get sourceType => _sourceType;
  List<Map<String, dynamic>> get currentPlaylist => _currentPlaylist;
  int get currentIndex => _currentIndex;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;

  // 构造函数初始化监听:初始化时传入api实例，并设置播放状态监听
  PlayerService({SubsonicApi? api}) : _api = api {
    _initAudioListeners();
  }

  // 初始化音频监听
  void _initAudioListeners() {
    // 监听播放状态变化(播放/暂停)
    _audioPlayer.playerStateStream.listen((state) {
      final wasPlaying = _isPlaying;
      _isPlaying = state.playing;
      if (wasPlaying != _isPlaying) {
        //状态变化时通知ui更新
        notifyListeners();
      }
    });

    // 监听播放进度(用于更新进度条)
    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    // 监听总时长变化(歌曲加载完后获取总时长)
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

    // 更新播放列表,如果传入了新列表，则替换当前列表，否则保留原列表
    if (playlist != null) {
      _currentPlaylist = playlist;
      _currentIndex = _currentPlaylist.indexWhere((s) => s['id'] == song['id']);

      //如果当前歌曲不在新列表中，则添加到列表末尾
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

  // 调整播放进度，例如拖动进度条时调用
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

  // 释放资源(页面销毁时调用)
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

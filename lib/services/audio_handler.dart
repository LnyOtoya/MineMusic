import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'subsonic_api.dart';

class MyAudioHandler extends BaseAudioHandler {
  final AudioPlayer _player = AudioPlayer();
  final SubsonicApi _api;

  // 播放状态相关
  List<MediaItem> _mediaItems = [];
  int _currentIndex = -1;
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  String? _currentSongId; // 添加当前歌曲ID跟踪
  bool _isScrobbled = false; // 是否已提交 scrobble
  DateTime? _playStartTime; // 播放开始时间

  MyAudioHandler(this._api) {
    // 设置监听器
    _player.playerStateStream.listen((state) {
      _updatePlaybackState(state);
      _handleScrobbleLogic(state);
    });
    _player.positionStream.listen((position) {
      _updatePosition(position);
      _checkScrobbleCondition(position);
    });
    _player.durationStream.listen(_updateDuration);
    _player.currentIndexStream.listen(_updateCurrentIndex);
    _player.sequenceStateStream.listen(_updateSequenceState);
  }

  // 处理 scrobble 逻辑
  void _handleScrobbleLogic(PlayerState state) {
    if (_currentSongId == null) return;

    if (state.playing) {
      // 检查是否需要发送 Now Playing 通知
      // 当歌曲开始播放且播放位置接近开始时发送
      if (_playStartTime == null || _player.position < Duration(seconds: 3)) {
        // 确保只发送一次 Now Playing 通知
        if (_playStartTime == null) {
          _playStartTime = DateTime.now();
          _api.notifyNowPlaying(_currentSongId!);
          _isScrobbled = false;
          print('📢 发送 Now Playing: $_currentSongId');
        }
      }
    } else if (state.processingState == ProcessingState.completed) {
      // 歌曲播放完成时检查是否需要提交 scrobble
      if (!_isScrobbled) {
        final position = _player.position;
        final duration = _player.duration ?? Duration.zero;
        if (duration > Duration.zero) {
          final condition1 = position >= Duration(minutes: 4);
          final condition2 = position >= duration * 0.5;
          if (condition1 || condition2) {
            _api.submitScrobble(_currentSongId!);
            _isScrobbled = true;
            print('✅ 提交 Scrobble: $_currentSongId');
          }
        }
      }

      // 检查是否有下一首歌曲
      final hasNext = _player.hasNext;
      print('🎵 播放完成，是否有下一首: $hasNext');

      if (hasNext) {
        // 有下一首，自动切歌（由 just_audio 处理）
        print('🎵 自动切到下一首');
      } else {
        // 没有下一首，调用 pause 停止播放
        print('🎵 播放列表结束，停止播放');
        _player.pause();
        // 重置状态
        _playStartTime = null;
        _isScrobbled = false;
        // 手动更新播放状态，确保 UI 和通知栏一致
        playbackState.add(
          PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              MediaControl.play,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            androidCompactActionIndices: const [0, 1, 2],
            processingState: AudioProcessingState.completed,
            playing: false,
            updatePosition: _player.position,
            bufferedPosition: _player.bufferedPosition,
            speed: _player.speed,
            queueIndex: _player.currentIndex,
          ),
        );
      }
    } else if (state.processingState == ProcessingState.idle) {
      // 播放器空闲时重置状态
      _playStartTime = null;
      _isScrobbled = false;
    }
  }

  // 检查 scrobble 条件
  void _checkScrobbleCondition(Duration currentPosition) {
    if (_isScrobbled || _currentSongId == null) return;

    final duration = _player.duration ?? Duration.zero;
    if (duration == Duration.zero) return;

    // 检查是否满足 scrobble 条件
    final condition1 = currentPosition >= Duration(minutes: 4);
    final condition2 = currentPosition >= duration * 0.5;

    if (condition1 || condition2) {
      // 满足条件，提交 scrobble
      _api.submitScrobble(_currentSongId!);
      _isScrobbled = true;
      print('✅ 已提交 scrobble: $_currentSongId');
    }
  }

  // 检查是否已经加载了指定歌曲
  bool isSongLoaded(String songId) {
    return _currentSongId == songId &&
        _player.playerState != null &&
        _player.playerState!.processingState != ProcessingState.idle;
  }

  // 将歌曲信息转换为 MediaItem
  MediaItem _songToMediaItem(Map<String, dynamic> song) {
    return MediaItem(
      id: song['id']!,
      title: song['title'] ?? '未知歌曲',
      artist: song['artist'] ?? '未知艺术家',
      album: song['album'] ?? '未知专辑',
      artUri: Uri.parse(_api.getCoverArtUrl(song['coverArt'] ?? '')),
      duration: Duration(seconds: int.tryParse(song['duration'] ?? '0') ?? 0),
      extras: {'song_data': song}, // 保存原始数据
    );
  }

  // 更新播放状态 - 修复版本
  void _updatePlaybackState(PlayerState state) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (state.playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          // MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[state.processingState]!,
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  // 更新播放位置
  void _updatePosition(Duration position) {
    playbackState.add(playbackState.value.copyWith(updatePosition: position));
  }

  // 更新总时长
  void _updateDuration(Duration? duration) {
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  // 更新当前索引
  void _updateCurrentIndex(int? index) {
    _currentIndex = index ?? -1;
    if (_currentIndex != -1 && _mediaItems.isNotEmpty) {
      mediaItem.add(_mediaItems[_currentIndex]);
    }
  }

  // 更新播放序列状态
  void _updateSequenceState(SequenceState? sequenceState) {
    if (sequenceState == null || sequenceState.currentIndex == null) return;

    _currentIndex = sequenceState.currentIndex!;
    final source = sequenceState.currentSource;
    if (source != null && source.tag != null) {
      final currentMediaItem = source.tag as MediaItem;
      mediaItem.add(currentMediaItem);

      // 检测歌曲变化，更新当前歌曲ID并重置scrobble状态
      if (_currentSongId != currentMediaItem.id) {
        _currentSongId = currentMediaItem.id;
        _isScrobbled = false;
        _playStartTime = null;
        print('🎵 歌曲切换：${currentMediaItem.title} (${currentMediaItem.id})');
      }
    }
  }

  @override
  Future<void> play() async {
    await _player.play();
    if (_playStartTime == null) {
      _playStartTime = DateTime.now();
      if (_currentSongId != null) {
        _api.notifyNowPlaying(_currentSongId!);
      }
    }
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    // 停止前检查当前歌曲是否需要 scrobble
    if (!_isScrobbled && _currentSongId != null) {
      final position = _player.position;
      final duration = _player.duration ?? Duration.zero;
      if (duration > Duration.zero) {
        final condition1 = position >= Duration(minutes: 4);
        final condition2 = position >= duration * 0.5;
        if (condition1 || condition2) {
          _api.submitScrobble(_currentSongId!);
          _isScrobbled = true;
        }
      }
    }
    await _player.stop();
    // 重置 scrobble 状态
    _isScrobbled = false;
    _playStartTime = null;
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
    // 跳转后检查 scrobble 条件
    _checkScrobbleCondition(position);
  }

  // @override
  // Future<void> skipToNext() => _player.seekToNext();

  // @override
  // Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToNext() async {
    // 切歌前检查当前歌曲是否需要 scrobble
    if (!_isScrobbled && _currentSongId != null) {
      final position = _player.position;
      final duration = _player.duration ?? Duration.zero;
      if (duration > Duration.zero) {
        final condition1 = position >= Duration(minutes: 4);
        final condition2 = position >= duration * 0.5;
        if (condition1 || condition2) {
          _api.submitScrobble(_currentSongId!);
          _isScrobbled = true;
        }
      }
    }
    await _player.seekToNext();
    // 重置 scrobble 状态
    _isScrobbled = false;
    _playStartTime = null;
    if (!_player.playing) {
      await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    // 切歌前检查当前歌曲是否需要 scrobble
    if (!_isScrobbled && _currentSongId != null) {
      final position = _player.position;
      final duration = _player.duration ?? Duration.zero;
      if (duration > Duration.zero) {
        final condition1 = position >= Duration(minutes: 4);
        final condition2 = position >= duration * 0.5;
        if (condition1 || condition2) {
          _api.submitScrobble(_currentSongId!);
          _isScrobbled = true;
        }
      }
    }
    await _player.seekToPrevious();
    // 重置 scrobble 状态
    _isScrobbled = false;
    _playStartTime = null;
    if (!_player.playing) {
      await _player.play();
    }
  }

  Future<void> skipToIndex(int index) async {
    // 切歌前检查当前歌曲是否需要 scrobble
    if (!_isScrobbled && _currentSongId != null) {
      final position = _player.position;
      final duration = _player.duration ?? Duration.zero;
      if (duration > Duration.zero) {
        final condition1 = position >= Duration(minutes: 4);
        final condition2 = position >= duration * 0.5;
        if (condition1 || condition2) {
          _api.submitScrobble(_currentSongId!);
          _isScrobbled = true;
        }
      }
    }
    await _player.seek(Duration.zero, index: index);
    // 重置 scrobble 状态
    _isScrobbled = false;
    _playStartTime = null;
    if (!_player.playing) {
      await _player.play();
    }
  }

  // 实现 skipToQueueItem 方法
  @override
  Future<void> skipToQueueItem(int index) async {
    await skipToIndex(index);
  }

  // 播放指定歌曲
  Future<void> playSong(
    Map<String, dynamic> song, {
    List<Map<String, dynamic>>? playlist,
  }) async {
    try {
      // 检查是否已经加载了同一首歌
      if (isSongLoaded(song['id'])) {
        // 如果已经加载，只需要播放即可
        if (!_player.playing) {
          await _player.play();
        }
        return;
      }

      // 重置 scrobble 状态
      _isScrobbled = false;
      _playStartTime = null;

      List<Map<String, dynamic>> songsToPlay;

      if (playlist != null) {
        songsToPlay = playlist;
      } else {
        songsToPlay = [song];
      }

      // 转换为 MediaItem 和 AudioSource
      _mediaItems = songsToPlay.map(_songToMediaItem).toList();

      final audioSources = songsToPlay.map((song) {
        final playUrl = _api.getSongPlayUrl(song['id']!);
        return AudioSource.uri(Uri.parse(playUrl), tag: _songToMediaItem(song));
      }).toList();

      // 设置播放列表
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: songsToPlay.indexWhere((s) => s['id'] == song['id']),
      );

      // 更新当前歌曲ID
      _currentSongId = song['id'];

      // 更新队列
      queue.add(_mediaItems);

      // 开始播放
      await _player.play();
    } catch (e) {
      print('播放失败: $e');
    }
  }

  // 加载指定歌曲但不自动播放
  Future<void> loadSong(
    Map<String, dynamic> song, {
    List<Map<String, dynamic>>? playlist,
  }) async {
    try {
      // 检查是否已经加载了同一首歌
      if (isSongLoaded(song['id'])) {
        // 如果已经加载，只需要确保暂停即可
        if (_player.playing) {
          await _player.pause();
        }
        return;
      }

      // 重置 scrobble 状态
      _isScrobbled = false;
      _playStartTime = null;

      List<Map<String, dynamic>> songsToPlay;

      print('MyAudioHandler.loadSong: 播放列表包含 ${playlist?.length ?? 0} 首歌曲');

      if (playlist != null) {
        songsToPlay = playlist;
        print(
          'MyAudioHandler.loadSong: 使用传入的播放列表，包含 ${songsToPlay.length} 首歌曲',
        );
      } else {
        songsToPlay = [song];
        print('MyAudioHandler.loadSong: 使用默认播放列表，包含 1 首歌曲');
      }

      // 转换为 MediaItem 和 AudioSource
      _mediaItems = songsToPlay.map(_songToMediaItem).toList();
      print(
        'MyAudioHandler.loadSong: 转换为 MediaItem，包含 ${_mediaItems.length} 首歌曲',
      );

      final audioSources = songsToPlay.map((song) {
        final playUrl = _api.getSongPlayUrl(song['id']!);
        return AudioSource.uri(Uri.parse(playUrl), tag: _songToMediaItem(song));
      }).toList();
      print(
        'MyAudioHandler.loadSong: 转换为 AudioSource，包含 ${audioSources.length} 首歌曲',
      );

      // 设置播放列表
      await _player.setAudioSource(
        ConcatenatingAudioSource(children: audioSources),
        initialIndex: songsToPlay.indexWhere((s) => s['id'] == song['id']),
      );
      print('MyAudioHandler.loadSong: 设置播放列表完成');

      // 更新当前歌曲ID
      _currentSongId = song['id'];

      // 更新队列
      queue.value = _mediaItems;
      print('MyAudioHandler.loadSong: 更新队列完成，包含 ${_mediaItems.length} 首歌曲');

      // 确保处于暂停状态
      await _player.pause();
      print('MyAudioHandler.loadSong: 确保处于暂停状态');
    } catch (e) {
      print('加载歌曲失败: $e');
    }
  }

  // 添加歌曲到播放列表
  Future<void> addToQueue(List<Map<String, dynamic>> songs) async {
    final mediaItems = songs.map(_songToMediaItem).toList();
    final audioSources = songs.map((song) {
      final playUrl = _api.getSongPlayUrl(song['id']!);
      return AudioSource.uri(Uri.parse(playUrl), tag: _songToMediaItem(song));
    }).toList();

    await _playlist.addAll(audioSources);
    _mediaItems.addAll(mediaItems);
    queue.add(_mediaItems);
  }

  // 清空播放列表
  Future<void> clearQueue() async {
    await _player.stop();
    await _player.setAudioSource(ConcatenatingAudioSource(children: []));
    _mediaItems.clear();
    _currentIndex = -1;
    queue.add([]);
    mediaItem.add(null);
  }

  // 获取当前播放状态
  bool get isPlaying => _player.playing;

  // 获取当前歌曲
  Map<String, dynamic>? get currentSong {
    if (_currentIndex >= 0 && _currentIndex < _mediaItems.length) {
      return _mediaItems[_currentIndex].extras?['song_data'];
    }
    return null;
  }

  // 获取播放位置
  Duration get currentPosition => _player.position;

  // 获取总时长
  Duration? get totalDuration => _player.duration;

  @override
  Future<void> onTaskRemoved() async {
    // 不停止播放，保持后台服务运行
    // 只在用户明确停止时才停止播放
    await super.onTaskRemoved();
  }

  // 添加自定义的 dispose 方法
  Future<void> customDispose() async {
    await _player.dispose();
  }
}

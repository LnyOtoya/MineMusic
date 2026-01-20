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

  MyAudioHandler(this._api) {
    // 设置监听器
    _player.playerStateStream.listen(_updatePlaybackState);
    _player.positionStream.listen(_updatePosition);
    _player.durationStream.listen(_updateDuration);
    _player.currentIndexStream.listen(_updateCurrentIndex);
    _player.sequenceStateStream.listen(_updateSequenceState);
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
      mediaItem.add(source.tag as MediaItem);
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  // @override
  // Future<void> skipToNext() => _player.seekToNext();

  // @override
  // Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    if (!_player.playing) {
      await _player.play();
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    if (!_player.playing) {
      await _player.play();
    }
  }

  Future<void> skipToIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
    if (!_player.playing) {
      await _player.play();
    }
  }

  // 播放指定歌曲
  Future<void> playSong(
    Map<String, dynamic> song, {
    List<Map<String, dynamic>>? playlist,
  }) async {
    try {
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

      // 更新队列
      queue.add(_mediaItems);

      // 开始播放
      await _player.play();
    } catch (e) {
      print('播放失败: $e');
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

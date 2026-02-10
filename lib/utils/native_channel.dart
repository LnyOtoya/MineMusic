import 'package:flutter/services.dart';

/// Flutter 与原生通信的通道封装
class NativeChannel {
  // 与原生（Android）通信的通道名
  static const MethodChannel _channel = MethodChannel('mine_music/widget');

  /// 同步播放状态到原生（用于小部件显示）
  /// - songTitle: 当前歌曲标题
  /// - artist: 当前艺术家
  /// - coverId: Subsonic 封面ID
  /// - isPlaying: 是否正在播放
  static Future<void> syncPlayState({
    required String songTitle,
    required String artist,
    required String coverId,
    required bool isPlaying,
  }) async {
    try {
      await _channel.invokeMethod('syncPlayState', {
        'songTitle': songTitle,
        'artist': artist,
        'coverId': coverId,
        'isPlaying': isPlaying,
      });
    } catch (e) {
      print('同步播放状态失败: $e');
    }
  }

  /// 触发小部件更新
  static Future<void> updateWidget() async {
    try {
      await _channel.invokeMethod('updateWidget');
    } catch (e) {
      print('更新小部件失败: $e');
    }
  }
}

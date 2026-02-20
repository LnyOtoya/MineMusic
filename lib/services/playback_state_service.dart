import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlaybackStateService {
  static const String _currentSongKey = 'current_song';
  static const String _playbackPositionKey = 'playback_position';
  static const String _lightColorSchemeKey = 'light_color_scheme';
  static const String _darkColorSchemeKey = 'dark_color_scheme';
  static const String _playlistKey = 'current_playlist';
  static const String _sourceTypeKey = 'source_type';

  Future<void> saveCurrentSong(Map<String, dynamic>? song) async {
    final prefs = await SharedPreferences.getInstance();
    if (song == null) {
      await prefs.remove(_currentSongKey);
    } else {
      final songJson = jsonEncode(song);
      await prefs.setString(_currentSongKey, songJson);
    }
  }

  Future<Map<String, dynamic>?> getCurrentSong() async {
    final prefs = await SharedPreferences.getInstance();
    final songJson = prefs.getString(_currentSongKey);

    if (songJson == null) return null;

    try {
      final decoded = jsonDecode(songJson);
      return decoded.cast<String, dynamic>();
    } catch (e) {
      return null;
    }
  }

  Future<void> savePlaylist(List<Map<String, dynamic>>? playlist) async {
    final prefs = await SharedPreferences.getInstance();
    if (playlist == null || playlist.isEmpty) {
      await prefs.remove(_playlistKey);
      print('播放列表为空，已移除保存的播放列表');
    } else {
      final playlistJson = jsonEncode(playlist);
      await prefs.setString(_playlistKey, playlistJson);
      print('已保存播放列表，包含 ${playlist.length} 首歌曲');
    }
  }

  Future<void> saveSourceType(String sourceType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sourceTypeKey, sourceType);
    print('已保存播放来源: $sourceType');
  }

  Future<String> getSourceType() async {
    final prefs = await SharedPreferences.getInstance();
    final sourceType = prefs.getString(_sourceTypeKey);
    print('已获取播放来源: $sourceType');
    return sourceType ?? 'song';
  }

  Future<List<Map<String, dynamic>>?> getPlaylist() async {
    final prefs = await SharedPreferences.getInstance();
    final playlistJson = prefs.getString(_playlistKey);

    if (playlistJson == null) {
      print('未找到保存的播放列表');
      return null;
    }

    try {
      final decoded = jsonDecode(playlistJson);
      if (decoded is List) {
        final playlist = decoded
            .map((item) {
              if (item is Map) {
                return item.cast<String, dynamic>();
              }
              return null;
            })
            .where((item) => item != null)
            .cast<Map<String, dynamic>>()
            .toList();
        print('已获取保存的播放列表，包含 ${playlist.length} 首歌曲');
        return playlist;
      }
      print('保存的播放列表格式不正确');
      return null;
    } catch (e) {
      print('获取播放列表失败: $e');
      return null;
    }
  }

  Future<void> savePlaybackPosition(Duration position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_playbackPositionKey, position.inMilliseconds);
  }

  Future<Duration> getPlaybackPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final milliseconds = prefs.getInt(_playbackPositionKey);
    return Duration(milliseconds: milliseconds ?? 0);
  }

  Future<void> saveColorScheme(String colorSchemeJson, bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDark ? _darkColorSchemeKey : _lightColorSchemeKey;
    await prefs.setString(key, colorSchemeJson);
  }

  Future<String?> getColorScheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    final key = isDark ? _darkColorSchemeKey : _lightColorSchemeKey;
    return prefs.getString(key);
  }

  Future<void> clearPlaybackState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentSongKey);
    await prefs.remove(_playbackPositionKey);
    await prefs.remove(_playlistKey);
  }
}

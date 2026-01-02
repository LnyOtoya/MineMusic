import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlayHistoryService {
  static const String _historyKey = 'play_history';
  static const int _maxHistorySize = 50;

  Future<void> addToHistory(Map<String, dynamic> song) async {
    if (song['id'] == null) return;

    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    final songId = song['id'];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final songWithTimestamp = Map<String, dynamic>.from(song);
    songWithTimestamp['timestamp'] = timestamp;

    history.removeWhere((s) => s['id'] == songId);
    history.insert(0, songWithTimestamp);

    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    final historyJson = jsonEncode(history);
    await prefs.setString(_historyKey, historyJson);
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_historyKey);

    if (historyJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentSongs({int count = 10}) async {
    final history = await getHistory();
    return history.take(count).toList();
  }

  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> removeFromHistory(String songId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();

    history.removeWhere((s) => s['id'] == songId);

    final historyJson = jsonEncode(history);
    await prefs.setString(_historyKey, historyJson);
  }
}

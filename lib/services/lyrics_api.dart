import 'package:http/http.dart' as http;
import 'dart:convert';

class LyricsApi {
  static const String _baseUrl = 'https://oiapi.net/api/QQMusicLyric';

  Future<List<Map<String, dynamic>>> searchSongs(
    String title,
    String artist,
  ) async {
    try {
      final cleanTitle = _cleanString(title);
      final cleanArtist = _cleanString(artist);
      final keyword = '$cleanTitle $cleanArtist';
      final url = Uri.parse('$_baseUrl?keyword=${Uri.encodeComponent(keyword)}&limit=10');

      print('🔍 搜索歌词: $keyword');
      print('📡 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 响应数据: ${json.encode(data)}');

        if (data['code'] == 1 && data['data'] != null) {
          final List<dynamic> songs = data['data'];
          return songs.map<Map<String, dynamic>>((song) {
            return {
              'mid': song['mid'],
              'title': song['title'],
              'artist': song['artist'],
              'album': song['album'],
              'duration': song['duration'],
            };
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ 搜索歌曲失败: $e');
      return [];
    }
  }

  String _cleanString(String input) {
    return input
        .replaceAll("'", "")
        .replaceAll('"', "")
        .replaceAll('`', '')
        .replaceAll('´', '')
        .replaceAll('’', '')
        .replaceAll('‘', '')
        .trim();
  }

  Future<String> getLrcLyrics(String mid) async {
    try {
      final url = Uri.parse('$_baseUrl?id=$mid&format=lrc');

      print('🎵 获取歌词: mid=$mid');
      print('📡 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 响应数据: ${json.encode(data)}');

        if (data['code'] == 1 && data['data'] != null) {
          final lyrics = data['data']['content'];
          if (lyrics != null && lyrics.isNotEmpty) {
            print('✅ 成功获取歌词，长度: ${lyrics.length}');
            return lyrics;
          }
        }
      }

      return '';
    } catch (e) {
      print('❌ 获取歌词失败: $e');
      return '';
    }
  }

  Future<String> getLyricsByKeyword(String title, String artist) async {
    try {
      final songs = await searchSongs(title, artist);

      if (songs.isEmpty) {
        print('⚠️ 未找到匹配的歌曲');
        return '';
      }

      final bestMatch = _findBestMatch(title, artist, songs);
      if (bestMatch == null) {
        print('⚠️ 未找到最佳匹配');
        return '';
      }

      print('✅ 找到最佳匹配: ${bestMatch['title']} - ${bestMatch['artist']}');
      return await getLrcLyrics(bestMatch['mid']);
    } catch (e) {
      print('❌ 获取歌词失败: $e');
      return '';
    }
  }

  Map<String, dynamic>? _findBestMatch(
    String title,
    String artist,
    List<Map<String, dynamic>> songs,
  ) {
    if (songs.isEmpty) return null;

    int bestScore = -1;
    Map<String, dynamic>? bestMatch;

    for (var song in songs) {
      int score = 0;

      final songTitle = song['title']?.toLowerCase() ?? '';
      final songArtist = song['artist']?.toLowerCase() ?? '';
      final targetTitle = title.toLowerCase();
      final targetArtist = artist.toLowerCase();

      if (songTitle == targetTitle) score += 10;
      if (songTitle.contains(targetTitle) || targetTitle.contains(songTitle)) {
        score += 5;
      }

      if (songArtist == targetArtist) score += 10;
      if (songArtist.contains(targetArtist) || targetArtist.contains(songArtist)) {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = song;
      }
    }

    return bestScore >= 10 ? bestMatch : songs.first;
  }
}

import 'package:http/http.dart' as http;
import 'dart:convert';

class LyricsApi {
  static const String _baseUrl = 'https://oiapi.net/api/QQMusicLyric';
  static const String _txmusic2BaseUrl =
      'https://api.vkeys.cn/v2/music/tencent/lyric';
  static const String _txmusic2SearchUrl =
      'https://api.vkeys.cn/v2/music/tencent/search/song';

  Future<List<Map<String, dynamic>>> searchSongs(
    String title,
    String artist,
  ) async {
    try {
      final cleanTitle = _cleanString(title);
      final cleanArtist = _cleanString(artist);
      final keyword = '$cleanTitle $cleanArtist';
      final url = Uri.parse(
        '$_baseUrl?keyword=${Uri.encodeComponent(keyword)}&limit=10',
      );

      print('🔍 搜索歌词: $keyword');
      print('📡 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 响应数据: ${json.encode(data)}');

        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> songs = data['data'];
          return songs.map<Map<String, dynamic>>((song) {
            return {
              'mid': song['mid'],
              'title': song['song'],
              'artist': song['singer'],
              'album': song['album'],
              'duration': song['interval'],
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

  Future<Map<String, String>> getTxMusic2Lyrics(
    String title,
    String artist,
  ) async {
    try {
      final songs = await searchSongsForTxMusic2(title, artist);

      if (songs.isEmpty) {
        print('⚠️ 未找到匹配的歌曲');
        return {'lyrics': '', 'translation': ''};
      }

      final bestMatch = _findBestMatch(title, artist, songs);
      if (bestMatch == null) {
        print('⚠️ 未找到最佳匹配');
        return {'lyrics': '', 'translation': ''};
      }

      print('✅ 找到最佳匹配: ${bestMatch['title']} - ${bestMatch['artist']}');
      return await getTxMusic2LrcLyrics(bestMatch['mid']);
    } catch (e) {
      print('❌ 获取歌词失败: $e');
      return {'lyrics': '', 'translation': ''};
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

  Future<List<Map<String, dynamic>>> searchSongsForTxMusic2(
    String title,
    String artist,
  ) async {
    try {
      final cleanTitle = _cleanString(title);
      final cleanArtist = _cleanString(artist);
      final word = '$cleanTitle $cleanArtist';
      final url = Uri.parse(
        '$_txmusic2SearchUrl?word=${Uri.encodeComponent(word)}&num=10',
      );

      print('🔍 搜索txmusic2歌曲: $word');
      print('📡 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 响应数据: ${json.encode(data)}');

        if (data['code'] == 200 && data['data'] != null) {
          final List<dynamic> songs = data['data'];
          return songs.map<Map<String, dynamic>>((song) {
            return {
              'mid': song['mid'],
              'title': song['song'],
              'artist': song['singer'],
              'album': song['album'],
              'duration': song['interval'],
            };
          }).toList();
        }
      }

      return [];
    } catch (e) {
      print('❌ 搜索txmusic2歌曲失败: $e');
      return [];
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
      if (songArtist.contains(targetArtist) ||
          targetArtist.contains(songArtist)) {
        score += 5;
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = song;
      }
    }

    return bestScore >= 10 ? bestMatch : songs.first;
  }

  Future<Map<String, String>> getTxMusic2LrcLyrics(String mid) async {
    try {
      final url = Uri.parse('$_txmusic2BaseUrl?mid=$mid');

      print('🎵 获取txmusic2歌词: mid=$mid');
      print('📡 请求URL: $url');

      final response = await http.get(url);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('📄 响应数据: ${json.encode(data)}');

        if (data['code'] == 200 && data['data'] != null) {
          final lyrics = data['data']['lrc'];
          final translation = data['data']['trans'];

          if (lyrics != null && lyrics.isNotEmpty) {
            print('✅ 成功获取txmusic2歌词，长度: ${lyrics.length}');
            print('✅ 翻译长度: ${translation?.length ?? 0}');
            print('📝 Data keys: ${data['data'].keys.toList()}');

            return {'lyrics': lyrics, 'translation': translation ?? ''};
          }
        }
      }

      return {'lyrics': '', 'translation': ''};
    } catch (e) {
      print('❌ 获取txmusic2歌词失败: $e');
      return {'lyrics': '', 'translation': ''};
    }
  }
}

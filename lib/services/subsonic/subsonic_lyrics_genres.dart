import 'package:xml/xml.dart';
import 'dart:convert';
import '../subsonic/subsonic_api_base.dart';

// 歌词和流派相关API
class SubsonicLyricsGenres extends SubsonicApiBase {
  SubsonicLyricsGenres({
    required super.baseUrl,
    required super.username,
    required super.password,
  });

  //获取流派列表
  Future<List<Map<String, dynamic>>> getGenres() async {
    // 检查缓存
    if (SubsonicApiBase.cachedGenres != null) {
      print('✅ 使用缓存的流派列表数据');
      return SubsonicApiBase.cachedGenres!;
    }

    try {
      final response = await sendGetRequest('getGenres');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final genreElements = document.findAllElements('genre');

        List<Map<String, dynamic>> genres = [];

        for (var element in genreElements) {
          final name = element.text;
          final songCount = element.getAttribute('songCount');
          final albumCount = element.getAttribute('albumCount');

          print(
            '🔍 处理流派: name=$name, songCount=$songCount, albumCount=$albumCount',
          );

          if (name.isNotEmpty) {
            genres.add({
              'name': name,
              'songCount': songCount ?? '0',
              'albumCount': albumCount ?? '0',
              'iconName': _getGenreIconName(name),
            });
          }
        }

        // 缓存数据
        SubsonicApiBase.cachedGenres = genres;
        print('✅ 获取到 ${genres.length} 个流派并缓存');
        return genres;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取流派列表失败: $e');
      return [];
    }
  }

  // 获取歌曲歌词（Subsonic API，纯文本）
  Future<Map<String, dynamic>?> getLyrics({
    required String artist,
    required String title,
  }) async {
    try {
      final extraParams = {
        'artist': artist,
        'title': title,
      };

      final response = await sendGetRequest('getLyrics', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);

        // 解析歌词节点
        final lyricsElement = document
            .findElements('subsonic-response')
            .firstOrNull
            ?.findElements('lyrics')
            .firstOrNull;

        if (lyricsElement != null) {
          return {
            'artist': lyricsElement.getAttribute('artist') ?? artist,
            'title': lyricsElement.getAttribute('title') ?? title,
            'text': lyricsElement.text.trim(),
          };
        }
        return null;
      } else {
        throw Exception('获取歌词失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌词出错: $e');
      return null;
    }
  }

  // 获取歌曲歌词（OpenSubsonic API，带时间轴）
  Future<Map<String, dynamic>?> getLyricsBySongId({
    required String songId,
  }) async {
    try {
      final extraParams = {
        'id': songId,
        'f': 'json',
        'c': 'MineMusic',
      };

      final response = await sendGetRequest('getLyricsBySongId', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        print('📄 歌词响应数据: ${json.encode(data)}');

        // 解析歌词列表
        final lyricsList = data['subsonic-response']?['lyricsList'];
        if (lyricsList != null) {
          final structuredLyrics = lyricsList['structuredLyrics'];
          if (structuredLyrics is List && structuredLyrics.isNotEmpty) {
            // 返回第一个歌词（通常是最佳匹配）
            return {
              'structuredLyrics': structuredLyrics,
              'openSubsonic': true,
            };
          }
        }
        return null;
      } else {
        throw Exception('获取带时间轴歌词失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取带时间轴歌词出错: $e');
      return null;
    }
  }

  // 检查服务器是否支持OpenSubsonic API
  Future<bool> checkOpenSubsonicSupport() async {
    try {
      final extraParams = {
        'f': 'json',
        'c': 'MineMusic',
      };

      final response = await sendGetRequest('getOpenSubsonicExtensions', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final data = json.decode(responseBody);
        print('📄 响应数据: ${json.encode(data)}');

        // 检查是否有songLyrics扩展
        final extensions = data['subsonic-response']?['openSubsonicExtensions']?['extensions'];
        if (extensions is List) {
          return extensions.contains('songLyrics');
        }
      }
      return false;
    } catch (e) {
      print('检查OpenSubsonic支持出错: $e');
      return false;
    }
  }

  //获取流派名图标
  String _getGenreIconName(String genreName) {
    final name = genreName.toLowerCase();

    if (name.contains('rock')) return 'guitar_amplifier';
    if (name.contains('pop')) return 'mic';
    if (name.contains('jazz')) return 'saxophone';
    if (name.contains('classical')) return 'piano';
    if (name.contains('electronic') || name.contains('dance'))
      return 'music_note';
    if (name.contains('hip') || name.contains('rap')) return 'graphic_eq';
    if (name.contains('country')) return 'album';
    if (name.contains('blues')) return 'piano';
    if (name.contains('folk')) return 'audiotrack';
    if (name.contains('metal')) return 'guitar_amplifier';
    if (name.contains('r&b') || name.contains('soul')) return 'mic';
    if (name.contains('latin')) return 'music_note';
    if (name.contains('reggae')) return 'music_note';
    return 'music_note';
  }
}

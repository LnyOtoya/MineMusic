import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';

//核心类：封装与 subsonic 服务器的交互
class SubsonicApi {
  final String baseUrl;
  final String username;
  final String password;

  SubsonicApi({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  //核心方法：与服务器交互的各种接口[ping 获取音乐文件夹 获取艺术家等]

  //ping接口
  Future<bool> ping() async {
    try {
      //构建请求url(subsonic 的 ping 接口)
      final url = Uri.parse('$baseUrl/rest/ping');

      //配置请求参数(subsonic 接口要求的认证参数)
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'otimeum',
        'f': 'xml',
      };

      //拼接参数到url
      final urlWithParams = url.replace(queryParameters: params);

      //发送get请求
      final response = await http.get(urlWithParams);

      //处理响应：检查状态码和响应内容
      if (response.statusCode == 200) {
        return response.body.contains('status="ok"');
      } else {
        return false;
      }
    } catch (e) {
      print('连接测试失败: $e');
      return false;
    }
  }

  //音乐文件夹目录接口
  Future<List<Map<String, dynamic>>> getMusicFolders() async {
    try {
      //构建请求url
      final url = Uri.parse('$baseUrl/rest/getMusicFolders');
      //配置请求参数
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
      };
      //拼接参数到url
      final urlWithParams = url.replace(queryParameters: params);
      print('🌐 请求URL: $urlWithParams');

      //发送请求
      final response = await http.get(urlWithParams);
      print('📡 响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        //解析xml响应

        //处理编码
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 响应内容: ${response.body}');

        //解析为xml文档
        final document = XmlDocument.parse(responseBody);

        //解析数据：查找所有 musicFolder 元素
        final musicFolderElements = document.findAllElements('musicFolder');

        //转换为 map 列表
        List<Map<String, dynamic>> folders = [];

        for (var element in musicFolderElements) {
          final id = element.getAttribute('id');
          final name = element.getAttribute('name');

          if (id != null && name != null) {
            folders.add({'id': id, 'name': name});
          }
        }

        print('✅ 解析到 ${folders.length} 个音乐库');
        return folders;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取音乐库失败: $e');
      return [];
    }
  }

  //获取艺术家列表
  Future<List<Map<String, dynamic>>> getArtists() async {
    try {
      final url = Uri.parse('$baseUrl/rest/getArtists');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final artistElements = document.findAllElements('artist');

        List<Map<String, dynamic>> artists = [];

        for (var element in artistElements) {
          final id = element.getAttribute('id');
          final name = element.getAttribute('name');
          final albumCount = element.getAttribute('albumCount');

          if (id != null && name != null) {
            artists.add({'id': id, 'name': name, 'albumCount': albumCount});
          }
        }

        return artists;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺术家列表失败: $e');
      return [];
    }
  }

  //获取随机歌曲
  Future<List<Map<String, dynamic>>> getRandomSongs({int count = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getRandomSongs');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'size': count.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      // print('🎲 请求随机歌曲 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      // print('📡 随机歌曲响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final title = element.getAttribute('title') ?? '未知标题';
          final artist = element.getAttribute('artist') ?? '未知艺术家';
          final album = element.getAttribute('album') ?? '未知专辑';
          songs.add({
            'id': element.getAttribute('id'),
            'title': title,
            'artist': artist,
            'album': album,
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        // print('✅ 获取到 ${songs.length} 首随机歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      // print('获取随机歌曲失败: $e');
      return [];
    }
  }

  //获取专辑列表
  Future<List<Map<String, dynamic>>> getAlbums({
    int size = 50,
    int offset = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getAlbumList2');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'type': 'alphabeticalByName',
        'size': size.toString(),
        'offset': offset.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final albumElements = document.findAllElements('album');

        List<Map<String, dynamic>> albums = [];

        for (var element in albumElements) {
          albums.add({
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'artist': element.getAttribute('artist'),
            'songCount': element.getAttribute('songCount'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        return albums;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取专辑列表失败: $e');
      return [];
    }
  }

  //获取所有歌曲
  Future<List<Map<String, dynamic>>> getAllSongs() async {
    try {
      print('🎵 开始获取所有歌曲（通过专辑列表）...');

      final albums = await getAlbums();
      List<Map<String, dynamic>> allSongs = [];

      int albumCount = albums.length > 5 ? 5 : albums.length;
      print('📀 将从 $albumCount 个专辑中获取歌曲...');

      for (int i = 0; i < albumCount; i++) {
        var album = albums[i];
        var albumSongs = await getSongsByAlbum(album['id']!);
        allSongs.addAll(albumSongs);

        print('   📦 专辑 "${album['name']}" 有 ${albumSongs.length} 首歌曲');
      }

      print('✅ 总共获取到 ${allSongs.length} 首歌曲');
      return allSongs;
    } catch (e) {
      print('获取所有歌曲失败: $e');
      return [];
    }
  }

  //获取专辑内歌曲
  Future<List<Map<String, dynamic>>> getSongsByAlbum(String albumId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getAlbum');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': albumId,
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final title = element.getAttribute('title') ?? '未知标题';
          final artist = element.getAttribute('artist') ?? '未知艺术家';
          final album = element.getAttribute('album') ?? '未知专辑';

          songs.add({
            'id': element.getAttribute('id'),
            'title': title,
            'artist': artist,
            'album': album,
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        return songs;
      } else {
        return [];
      }
    } catch (e) {
      print('获取专辑歌曲失败: $e');
      return [];
    }
  }

  //创建播放列表
  Future<bool> createPlaylist(String name, List<String> songIds) async {
    try {
      final url = Uri.parse('$baseUrl/rest/createPlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'name': name,
        'songId': songIds.join(','),
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表 "$name" 创建成功');
        return true;
      } else {
        print('❌ 播放列表创建失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('创建播放列表失败: $e');
      return false;
    }
  }

  //获取歌曲搜索
  Future<List<Map<String, dynamic>>> getAllSongsViaSearch() async {
    try {
      final url = Uri.parse('$baseUrl/rest/search3');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'query': '',
        'songCount': '500',
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🔍 搜索所有歌曲 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 搜索响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('📄 搜索响应内容: ${response.body}');

        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final title = element.getAttribute('title') ?? '未知标题';
          final artist = element.getAttribute('artist') ?? '未知艺术家';
          final album = element.getAttribute('album') ?? '未知专辑';

          songs.add({
            'id': element.getAttribute('id'),
            'title': title,
            'artist': artist,
            'album': album,
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        print('✅ 通过搜索获取到 ${songs.length} 首歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索所有歌曲失败: $e');
      return [];
    }
  }

  //获取流派列表
  Future<List<Map<String, dynamic>>> getGenres() async {
    try {
      final url = Uri.parse('$baseUrl/rest/getGenres');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🎵 请求流派列表 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 流派列表响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('🔍 原始响应: ${response.body}');
        print('🔍 解码后: $responseBody');

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

        print('✅ 获取到 ${genres.length} 个流派');
        return genres;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取流派列表失败: $e');
      return [];
    }
  }

  // 获取指定艺术家的所有歌曲
  Future<List<Map<String, dynamic>>> getSongsByArtist(String artistId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getArtist');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': artistId,
      };
      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];
        for (var element in songElements) {
          songs.add({
            'id': element.getAttribute('id'),
            'title': element.getAttribute('title'),
            'artist': element.getAttribute('artist'),
            'album': element.getAttribute('album'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }
        return songs;
      } else {
        throw Exception('获取艺人歌曲失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺人歌曲失败: $e');
      return [];
    }
  }

  // 获取指定歌单的所有歌曲
  Future<List<Map<String, dynamic>>> getPlaylistSongs(String playlistId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getPlaylist');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': playlistId,
      };
      final urlWithParams = url.replace(queryParameters: params);
      print('获取歌单歌曲，URL: $urlWithParams');
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        print('歌单响应: $responseBody');
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('entry');
        print('找到 ${songElements.length} 首歌曲');

        List<Map<String, dynamic>> songs = [];
        for (var element in songElements) {
          songs.add({
            'id': element.getAttribute('id'),
            'title': element.getAttribute('title'),
            'artist': element.getAttribute('artist'),
            'album': element.getAttribute('album'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }
        print('解析后的歌曲列表: $songs');
        return songs;
      } else {
        throw Exception('获取歌单歌曲失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌单歌曲失败: $e');
      return [];
    }
  }

  // 获取所有歌单
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    try {
      final url = Uri.parse('$baseUrl/rest/getPlaylists');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
      };
      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final playlistElements = document.findAllElements('playlist');

        List<Map<String, dynamic>> playlists = [];
        for (var element in playlistElements) {
          playlists.add({
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'songCount': element.getAttribute('songCount'),
            'comment': element.getAttribute('comment'),
          });
        }
        return playlists;
      } else {
        throw Exception('获取歌单失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌单失败: $e');
      return [];
    }
  }

  // 获取艺术家的专辑
  Future<List<Map<String, dynamic>>> getAlbumsByArtist(String artistId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getArtist');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'json',
        'id': artistId,
      };
      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(
          utf8.decode(response.bodyBytes),
        );
        final artistInfo = data['subsonic-response']['artist'];

        if (artistInfo != null && artistInfo['album'] != null) {
          List<dynamic> albumsData = artistInfo['album'];
          return albumsData.map<Map<String, dynamic>>((album) {
            return {
              'id': album['id'],
              'name': album['name'],
              'artist': album['artist'],
              'artistId': album['artistId'],
              'songCount': album['songCount'],
              'duration': album['duration'],
              'coverArt': album['coverArt'],
              'year': album['year'],
            };
          }).toList();
        }
        return [];
      } else {
        throw Exception('获取艺术家专辑失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺术家专辑失败: $e');
      return [];
    }
  }

  // 添加按时间排序的专辑获取方法
  Future<List<Map<String, dynamic>>> getRecentAlbums({int size = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getAlbumList2');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'type': 'recent', // 按最近添加排序
        'size': size.toString(),
      };
      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final albumElements = document.findAllElements('album');

        List<Map<String, dynamic>> albums = [];
        for (var element in albumElements) {
          albums.add({
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'artist': element.getAttribute('artist'),
            'songCount': element.getAttribute('songCount'),
            'coverArt': element.getAttribute('coverArt'),
            'year': element.getAttribute('year'), // 发行年份
          });
        }
        return albums;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取最近专辑失败: $e');
      return [];
    }
  }

  // 获取随机专辑
  Future<List<Map<String, dynamic>>> getRandomAlbums({int size = 20}) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getAlbumList2');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'type': 'random', // 随机排序
        'size': size.toString(),
      };
      final urlWithParams = url.replace(queryParameters: params);
      print('🎲 请求随机专辑 URL: $urlWithParams');
      final response = await http.get(urlWithParams);
      print('📡 随机专辑响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final albumElements = document.findAllElements('album');

        List<Map<String, dynamic>> albums = [];
        for (var element in albumElements) {
          albums.add({
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'artist': element.getAttribute('artist'),
            'songCount': element.getAttribute('songCount'),
            'coverArt': element.getAttribute('coverArt'),
            'year': element.getAttribute('year'),
          });
        }
        print('✅ 获取到 ${albums.length} 个随机专辑');
        return albums;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取随机专辑失败: $e');
      return [];
    }
  }

  // 获取歌曲歌词
  Future<Map<String, dynamic>?> getLyrics({
    required String artist,
    required String title,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getLyrics');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'artist': artist, // 歌曲艺术家
        'title': title, // 歌曲标题
      };
      final urlWithParams = url.replace(queryParameters: params);
      print('📜 请求歌词 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 歌词响应状态: ${response.statusCode}');

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
            'text': lyricsElement.text.trim(), // 歌词内容
          };
        }
        return null; // 未找到歌词
      } else {
        throw Exception('获取歌词失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌词出错: $e');
      return null;
    }
  }

  // 获取封面图片URL
  String getCoverArtUrl(String coverArtId) {
    return Uri.parse('$baseUrl/rest/getCoverArt')
        .replace(
          queryParameters: {
            'u': username,
            'p': password,
            'v': '1.16.0',
            'c': 'MyMusicPlayer',
            'f': 'json',
            'id': coverArtId,
          },
        )
        .toString();
  }

  // 获取歌曲播放链接
  String getSongPlayUrl(String songId) {
    final params = {
      'u': username,
      'p': password,
      'v': '1.16.0',
      'c': 'MyMusicPlayer',
      'f': 'xml',
      'id': songId,
    };

    final uri = Uri.parse(
      '$baseUrl/rest/stream',
    ).replace(queryParameters: params);
    return uri.toString();
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
    if (name.contains('punk')) return 'guitar_amplifier';
    if (name.contains('funk')) return 'graphic_eq';
    if (name.contains('disco')) return 'graphic_eq';

    return 'music_note';
  }

  //获取相似歌曲
  Future<List<Map<String, dynamic>>> getSimilarSongs({
    required String id,
    int count = 20,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getSimilarSongs');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': id,
        'count': count.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🎵 请求相似歌曲 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 相似歌曲响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final title = element.getAttribute('title') ?? '未知标题';
          final artist = element.getAttribute('artist') ?? '未知艺术家';
          final album = element.getAttribute('album') ?? '未知专辑';

          songs.add({
            'id': element.getAttribute('id'),
            'title': title,
            'artist': artist,
            'album': album,
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        print('✅ 获取到 ${songs.length} 首相似歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取相似歌曲失败: $e');
      return [];
    }
  }

  //通过艺术家名称获取歌曲
  Future<List<Map<String, dynamic>>> getSongsByArtistName(
    String artistName,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/rest/search3');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'query': artistName,
        'songCount': '100',
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🎵 搜索艺术家歌曲 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 搜索响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final artist = element.getAttribute('artist') ?? '未知艺术家';

          if (artist == artistName) {
            songs.add({
              'id': element.getAttribute('id'),
              'title': element.getAttribute('title') ?? '未知标题',
              'artist': artist,
              'album': element.getAttribute('album') ?? '未知专辑',
              'duration': element.getAttribute('duration'),
              'coverArt': element.getAttribute('coverArt'),
              'year': element.getAttribute('year'),
            });
          }
        }

        print('✅ 获取到 ${songs.length} 首艺术家歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺术家歌曲失败: $e');
      return [];
    }
  }

  //获取指定年份范围内的歌曲
  Future<List<Map<String, dynamic>>> getSongsByYearRange(
    int startYear,
    int endYear, {
    int count = 20,
    String? excludeArtist,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/search3');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'query': '',
        'songCount': (count * 2).toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🎵 搜索年份范围歌曲 URL: $urlWithParams');
      print('📅 年份范围: $startYear - $endYear');

      final response = await http.get(urlWithParams);
      print('📡 搜索响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final songElements = document.findAllElements('song');

        List<Map<String, dynamic>> songs = [];

        for (var element in songElements) {
          final yearStr = element.getAttribute('year');
          final artist = element.getAttribute('artist') ?? '未知艺术家';

          if (yearStr != null) {
            try {
              final year = int.parse(yearStr);
              if (year >= startYear && year <= endYear) {
                if (excludeArtist == null || artist != excludeArtist) {
                  songs.add({
                    'id': element.getAttribute('id'),
                    'title': element.getAttribute('title') ?? '未知标题',
                    'artist': artist,
                    'album': element.getAttribute('album') ?? '未知专辑',
                    'duration': element.getAttribute('duration'),
                    'coverArt': element.getAttribute('coverArt'),
                    'year': yearStr,
                  });
                }
              }
            } catch (e) {
              continue;
            }
          }
        }

        print('✅ 获取到 ${songs.length} 首年份范围内歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取年份范围歌曲失败: $e');
      return [];
    }
  }

  Future<Map<String, List<Map<String, dynamic>>>> search3({
    required String query,
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
    int artistOffset = 0,
    int albumOffset = 0,
    int songOffset = 0,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/search3');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'query': query,
        'artistCount': artistCount.toString(),
        'albumCount': albumCount.toString(),
        'songCount': songCount.toString(),
        'artistOffset': artistOffset.toString(),
        'albumOffset': albumOffset.toString(),
        'songOffset': songOffset.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      print('🔍 搜索 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 搜索响应状态: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);

        final searchResult = document
            .findAllElements('searchResult3')
            .firstOrNull;
        if (searchResult == null) {
          return {'artists': [], 'albums': [], 'songs': []};
        }

        final List<Map<String, dynamic>> artists = [];
        final List<Map<String, dynamic>> albums = [];
        final List<Map<String, dynamic>> songs = [];

        final queryLower = query.toLowerCase();

        for (var element in searchResult.findAllElements('artist')) {
          final artistName = element.getAttribute('name') ?? '';
          if (artistName.toLowerCase().contains(queryLower)) {
            artists.add({
              'id': element.getAttribute('id'),
              'name': artistName,
              'albumCount': element.getAttribute('albumCount'),
              'coverArt': element.getAttribute('coverArt'),
            });
          }
        }

        final Map<String, Map<String, dynamic>> albumMap = {};
        for (var element in searchResult.findAllElements('album')) {
          final albumName = element.getAttribute('name') ?? '';
          if (albumName.toLowerCase().contains(queryLower)) {
            final artist = element.getAttribute('artist') ?? '';
            final songCount =
                int.tryParse(element.getAttribute('songCount') ?? '0') ?? 0;
            final albumKey = '$artist-$albumName';

            final albumData = {
              'id': element.getAttribute('id'),
              'name': albumName,
              'artist': artist,
              'artistId': element.getAttribute('artistId'),
              'songCount': element.getAttribute('songCount'),
              'duration': element.getAttribute('duration'),
              'coverArt': element.getAttribute('coverArt'),
              'created': element.getAttribute('created'),
            };

            if (albumMap.containsKey(albumKey)) {
              final existingSongCount =
                  int.tryParse(albumMap[albumKey]!['songCount'] ?? '0') ?? 0;
              if (songCount > existingSongCount) {
                albumMap[albumKey] = albumData;
              }
            } else {
              albumMap[albumKey] = albumData;
            }
          }
        }

        albums.addAll(albumMap.values.toList());

        for (var element in searchResult.findAllElements('song')) {
          final songTitle = element.getAttribute('title') ?? '';
          if (songTitle.toLowerCase().contains(queryLower)) {
            songs.add({
              'id': element.getAttribute('id'),
              'title': songTitle,
              'artist': element.getAttribute('artist'),
              'album': element.getAttribute('album'),
              'duration': element.getAttribute('duration'),
              'coverArt': element.getAttribute('coverArt'),
              'year': element.getAttribute('year'),
              'genre': element.getAttribute('genre'),
            });
          }
        }

        print(
          '✅ 搜索结果: ${artists.length} 艺术家, ${albums.length} 专辑, ${songs.length} 歌曲',
        );
        return {'artists': artists, 'albums': albums, 'songs': songs};
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索失败: $e');
      return {'artists': [], 'albums': [], 'songs': []};
    }
  }
}

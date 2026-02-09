import 'package:xml/xml.dart';
import 'dart:convert';
import '../subsonic/subsonic_api_base.dart';

// 音乐库相关API
class SubsonicMusicLibrary extends SubsonicApiBase {
  SubsonicMusicLibrary({
    required super.baseUrl,
    required super.username,
    required super.password,
  });

  // 获取音乐文件夹目录
  Future<List<Map<String, dynamic>>> getMusicFolders() async {
    // 检查缓存
    if (SubsonicApiBase.cachedMusicFolders != null) {
      print('✅ 使用缓存的音乐文件夹数据');
      return SubsonicApiBase.cachedMusicFolders!;
    }

    try {
      final response = await sendGetRequest('getMusicFolders');

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);
        final musicFolderElements = document.findAllElements('musicFolder');

        List<Map<String, dynamic>> folders = [];

        for (var element in musicFolderElements) {
          final id = element.getAttribute('id');
          final name = element.getAttribute('name');

          if (id != null && name != null) {
            folders.add({'id': id, 'name': name});
          }
        }

        // 缓存数据
        SubsonicApiBase.cachedMusicFolders = folders;
        print('✅ 解析到 ${folders.length} 个音乐库并缓存');
        return folders;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取音乐库失败: $e');
      return [];
    }
  }

  // 获取艺术家列表
  Future<List<Map<String, dynamic>>> getArtists() async {
    // 检查缓存
    if (SubsonicApiBase.cachedArtists != null) {
      print('✅ 使用缓存的艺术家列表数据');
      return SubsonicApiBase.cachedArtists!;
    }

    try {
      final response = await sendGetRequest('getArtists');

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

        // 缓存数据
        SubsonicApiBase.cachedArtists = artists;
        print('✅ 解析到 ${artists.length} 个艺术家并缓存');
        return artists;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺术家列表失败: $e');
      return [];
    }
  }

  // 获取专辑列表
  Future<List<Map<String, dynamic>>> getAlbums({
    int size = 50,
    int offset = 0,
  }) async {
    // 检查缓存（仅当offset为0时使用缓存，因为offset不为0表示分页加载）
    if (offset == 0 && SubsonicApiBase.cachedAlbums != null) {
      print('✅ 使用缓存的专辑列表数据');
      // 如果缓存的数量大于等于请求的数量，返回缓存的子集
      if (SubsonicApiBase.cachedAlbums!.length >= size) {
        return SubsonicApiBase.cachedAlbums!.take(size).toList();
      }
      return SubsonicApiBase.cachedAlbums!;
    }

    try {
      final extraParams = {
        'type': 'alphabeticalByName',
        'size': size.toString(),
        'offset': offset.toString(),
      };

      final response = await sendGetRequest('getAlbumList2', extraParams: extraParams);

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

        // 仅当offset为0时缓存数据
        if (offset == 0) {
          SubsonicApiBase.cachedAlbums = albums;
          print('✅ 解析到 ${albums.length} 个专辑并缓存');
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

  // 获取随机歌曲
  Future<List<Map<String, dynamic>>> getRandomSongs({int count = 20}) async {
    try {
      final extraParams = {
        'size': count.toString(),
      };

      final response = await sendGetRequest('getRandomSongs', extraParams: extraParams);

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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        print('✅ 获取到 ${songs.length} 首随机歌曲');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('获取随机歌曲失败: $e');
      return [];
    }
  }

  // 获取专辑内歌曲
  Future<List<Map<String, dynamic>>> getSongsByAlbum(String albumId) async {
    // 检查缓存
    if (SubsonicApiBase.cachedAlbumSongs.containsKey(albumId)) {
      print('✅ 使用缓存的专辑歌曲数据: $albumId');
      return SubsonicApiBase.cachedAlbumSongs[albumId]!;
    }

    try {
      final extraParams = {
        'id': albumId,
      };

      final response = await sendGetRequest('getAlbum', extraParams: extraParams);

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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        // 缓存数据
        SubsonicApiBase.cachedAlbumSongs[albumId] = songs;
        print('✅ 解析到 ${songs.length} 首专辑歌曲并缓存: $albumId');
        return songs;
      } else {
        return [];
      }
    } catch (e) {
      print('获取专辑歌曲失败: $e');
      return [];
    }
  }

  // 获取指定艺术家的所有歌曲
  Future<List<Map<String, dynamic>>> getSongsByArtist(String artistId) async {
    // 检查缓存
    if (SubsonicApiBase.cachedArtistSongs.containsKey(artistId)) {
      print('✅ 使用缓存的艺术家歌曲数据: $artistId');
      return SubsonicApiBase.cachedArtistSongs[artistId]!;
    }

    try {
      final extraParams = {
        'id': artistId,
      };

      final response = await sendGetRequest('getArtist', extraParams: extraParams);

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
            'artistId': element.getAttribute('artistId'),
            'album': element.getAttribute('album'),
            'albumId': element.getAttribute('albumId'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          });
        }

        // 缓存数据
        SubsonicApiBase.cachedArtistSongs[artistId] = songs;
        print('✅ 解析到 ${songs.length} 首艺术家歌曲并缓存: $artistId');
        return songs;
      } else {
        throw Exception('获取艺人歌曲失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取艺人歌曲失败: $e');
      return [];
    }
  }

  // 获取艺术家的专辑
  Future<List<Map<String, dynamic>>> getAlbumsByArtist(String artistId) async {
    try {
      final extraParams = {
        'id': artistId,
        'f': 'json',
      };

      final response = await sendGetRequest('getArtist', extraParams: extraParams);

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

  // 获取所有歌曲
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

  // 添加按时间排序的专辑获取方法
  Future<List<Map<String, dynamic>>> getRecentAlbums({int size = 20}) async {
    try {
      final extraParams = {
        'type': 'newest',
        'size': size.toString(),
      };

      final response = await sendGetRequest('getAlbumList2', extraParams: extraParams);

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
      final extraParams = {
        'type': 'random',
        'size': size.toString(),
      };

      final response = await sendGetRequest('getAlbumList2', extraParams: extraParams);

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
}

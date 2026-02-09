import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'dart:convert';

//核心类：封装与 subsonic 服务器的交互
class SubsonicApi {
  final String baseUrl;
  final String username;
  final String password;

  static List<Map<String, dynamic>>? _cachedPlaylists;

  SubsonicApi({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  void clearPlaylistCache() {
    _cachedPlaylists = null;
  }

  //核心方法：与服务器交互的各种接口[ping 获取音乐文件夹 获取艺术家等]

  // 获取歌手头像
  Future<String?> getArtistAvatar(
    String artistName, {
    String? artistId,
    String? songTitle,
  }) async {
    try {
      // 构建搜索请求，使用歌曲名+歌手名作为关键词，这样更准确
      final searchKeyword = songTitle != null && songTitle.isNotEmpty
          ? '$songTitle+$artistName'
          : artistName;
      final searchUrl = Uri.parse(
        'http://192.168.2.3:4555/search/search_by_type',
      );
      final searchParams = {'keyword': searchKeyword, 'searchtype': 'singer'};
      final searchRequestUrl = searchUrl.replace(queryParameters: searchParams);
      print('🔍 搜索歌手: $searchKeyword');
      print('📡 搜索URL: $searchRequestUrl');

      // 发送搜索请求
      final searchResponse = await http.get(searchRequestUrl);
      print('📡 搜索响应状态: ${searchResponse.statusCode}');

      if (searchResponse.statusCode == 200) {
        // 解析搜索响应
        final searchData = json.decode(searchResponse.body);
        print('📄 搜索响应数据: ${json.encode(searchData)}');

        // 检查搜索结果
        if (searchData['code'] == 200 &&
            searchData['data'] is List &&
            searchData['data'].isNotEmpty) {
          // 遍历搜索结果，找到与歌手名完全匹配的结果
          for (final result in searchData['data']) {
            // 检查是否有singer字段
            if (result['singer'] is List && result['singer'].isNotEmpty) {
              // 遍历歌手列表，找到与歌手名完全匹配的歌手
              for (final singerInfo in result['singer']) {
                final singerName = singerInfo['name'] as String?;
                print('🔍 搜索到歌手: $singerName');
                // 检查歌手名是否与目标歌手名完全匹配（忽略大小写）
                if (singerName != null &&
                    singerName.toLowerCase() == artistName.toLowerCase()) {
                  // 提取歌手的mid
                  final singerMid = singerInfo['mid'] as String?;
                  if (singerMid != null && singerMid.isNotEmpty) {
                    print('✅ 找到匹配的歌手mid: $singerMid');

                    // 使用歌手mid调用歌手API获取头像
                    final singerUrl = Uri.parse(
                      'http://192.168.2.3:4555/singer/get_info',
                    );
                    final singerParams = {'mid': singerMid};
                    final singerRequestUrl = singerUrl.replace(
                      queryParameters: singerParams,
                    );
                    print('📡 歌手API URL: $singerRequestUrl');

                    // 发送歌手API请求
                    final singerResponse = await http.get(singerRequestUrl);
                    print('📡 歌手API响应状态: ${singerResponse.statusCode}');

                    if (singerResponse.statusCode == 200) {
                      // 解析歌手API响应
                      final singerData = json.decode(singerResponse.body);
                      print('📄 歌手API响应数据: ${json.encode(singerData)}');

                      // 检查歌手API响应
                      if (singerData['code'] == 200 &&
                          singerData['data'] != null) {
                        final data = singerData['data'];
                        // 提取头像URL（优先使用BackgroundImage字段）
                        if (data['Info'] != null &&
                            data['Info']['BaseInfo'] != null) {
                          final baseInfo = data['Info']['BaseInfo'];
                          final avatarUrl =
                              baseInfo['BackgroundImage'] as String?;
                          if (avatarUrl != null && avatarUrl.isNotEmpty) {
                            print('✅ 从BackgroundImage获取到歌手头像: $avatarUrl');
                            return avatarUrl;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
          // 如果没有找到完全匹配的结果，使用第一个搜索结果
          print('⚠️ 没有找到完全匹配的歌手，使用第一个搜索结果');
          final firstResult = searchData['data'][0];
          if (firstResult['singer'] is List &&
              firstResult['singer'].isNotEmpty) {
            final singerInfo = firstResult['singer'][0];
            final singerMid = singerInfo['mid'] as String?;
            if (singerMid != null && singerMid.isNotEmpty) {
              print('✅ 使用第一个搜索结果的歌手mid: $singerMid');

              // 使用歌手mid调用歌手API获取头像
              final singerUrl = Uri.parse(
                'http://192.168.2.3:4555/singer/get_info',
              );
              final singerParams = {'mid': singerMid};
              final singerRequestUrl = singerUrl.replace(
                queryParameters: singerParams,
              );
              print('📡 歌手API URL: $singerRequestUrl');

              // 发送歌手API请求
              final singerResponse = await http.get(singerRequestUrl);
              print('📡 歌手API响应状态: ${singerResponse.statusCode}');

              if (singerResponse.statusCode == 200) {
                // 解析歌手API响应
                final singerData = json.decode(singerResponse.body);
                print('📄 歌手API响应数据: ${json.encode(singerData)}');

                // 检查歌手API响应
                if (singerData['code'] == 200 && singerData['data'] != null) {
                  final data = singerData['data'];
                  // 提取头像URL（优先使用BackgroundImage字段）
                  if (data['Info'] != null &&
                      data['Info']['BaseInfo'] != null) {
                    final baseInfo = data['Info']['BaseInfo'];
                    final avatarUrl = baseInfo['BackgroundImage'] as String?;
                    if (avatarUrl != null && avatarUrl.isNotEmpty) {
                      print('✅ 从BackgroundImage获取到歌手头像: $avatarUrl');
                      return avatarUrl;
                    }
                  }
                }
              }
            }
          }
        }
      }

      // 如果没有找到头像，返回固定的头像链接
      return 'http://y.gtimg.cn/music/photo_new/T001R800x800M000002hhhmu0fwrK5_3.jpg';
    } catch (e) {
      print('获取歌手头像失败: $e');
      return null;
    }
  }

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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
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
  Future<bool> createPlaylist(
    String name,
    List<String> songIds, {
    String? comment,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/createPlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'name': name,
        if (songIds.isNotEmpty) 'songId': songIds.join(','),
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表 "$name" 创建成功');
        
        // 如果提供了注释，创建后立即更新注释
        if (comment != null && comment.isNotEmpty) {
          // 获取刚创建的歌单ID
          final playlists = await getPlaylists();
          // 找到同名的最新歌单（假设最新创建的在最后）
          if (playlists.isNotEmpty) {
            // 按名称过滤并获取最新的
            final namedPlaylists = playlists.where((p) => p['name'] == name).toList();
            if (namedPlaylists.isNotEmpty) {
              final newPlaylist = namedPlaylists.last;
              if (newPlaylist['id'] != null) {
                print('🔄 更新歌单注释');
                await updatePlaylist(newPlaylist['id'], comment: comment);
              }
            }
          }
        }
        
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

  //更新播放列表
  Future<bool> updatePlaylist(
    String playlistId, {
    String? name,
    String? comment,
    bool? isPublic,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/updatePlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'playlistId': playlistId,
        if (name != null && name.isNotEmpty) 'name': name,
        if (comment != null) 'comment': comment,
        if (isPublic != null) 'public': isPublic.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表更新成功');
        return true;
      } else {
        print('❌ 播放列表更新失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('更新播放列表失败: $e');
      return false;
    }
  }

  //删除播放列表
  Future<bool> deletePlaylist(String playlistId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/deletePlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': playlistId,
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表删除成功');
        return true;
      } else {
        print('❌ 播放列表删除失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('删除播放列表失败: $e');
      return false;
    }
  }

  //将歌曲添加到歌单
  Future<bool> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final url = Uri.parse('$baseUrl/rest/updatePlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'playlistId': playlistId,
        'songIdToAdd': songId,
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 歌曲添加到歌单成功');
        clearPlaylistCache();
        return true;
      } else {
        print('❌ 歌曲添加到歌单失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('添加歌曲到歌单失败: $e');
      return false;
    }
  }

  //从歌单中删除歌曲
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      // 首先获取歌单中的所有歌曲，找到要删除歌曲的索引
      final playlistSongs = await getPlaylistSongs(playlistId);
      int songIndex = -1;
      for (int i = 0; i < playlistSongs.length; i++) {
        if (playlistSongs[i]['id'] == songId) {
          songIndex = i;
          break;
        }
      }

      if (songIndex == -1) {
        print('❌ 歌曲不在歌单中');
        return false;
      }

      final url = Uri.parse('$baseUrl/rest/updatePlaylist');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'playlistId': playlistId,
        'songIndexToRemove': songIndex.toString(),
      };

      final urlWithParams = url.replace(queryParameters: params);
      final response = await http.get(urlWithParams);

      if (response.statusCode == 200) {
        print('✅ 歌曲从歌单中删除成功');
        clearPlaylistCache();
        return true;
      } else {
        print('❌ 歌曲从歌单中删除失败: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('从歌单中删除歌曲失败: $e');
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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
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
            'artistId': element.getAttribute('artistId'),
            'album': element.getAttribute('album'),
            'albumId': element.getAttribute('albumId'),
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
            'artistId': element.getAttribute('artistId'),
            'album': element.getAttribute('album'),
            'albumId': element.getAttribute('albumId'),
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
        'type': 'newest', // 按最新排序
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

  // 获取歌曲歌词（Subsonic API，纯文本）
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

  // 获取歌曲歌词（OpenSubsonic API，带时间轴）
  Future<Map<String, dynamic>?> getLyricsBySongId({
    required String songId,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/rest/getLyricsBySongId');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MineMusic',
        'f': 'json',
        'id': songId, // 歌曲ID
      };
      final urlWithParams = url.replace(queryParameters: params);
      print('📜 请求带时间轴歌词 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 歌词响应状态: ${response.statusCode}');

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
        return null; // 未找到歌词
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
      final url = Uri.parse('$baseUrl/rest/getOpenSubsonicExtensions');
      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MineMusic',
        'f': 'json',
      };
      final urlWithParams = url.replace(queryParameters: params);
      print('📜 检查OpenSubsonic支持 URL: $urlWithParams');

      final response = await http.get(urlWithParams);
      print('📡 响应状态: ${response.statusCode}');

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
            'artistId': element.getAttribute('artistId'),
            'album': album,
            'albumId': element.getAttribute('albumId'),
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
              'artistId': element.getAttribute('artistId'),
              'album': element.getAttribute('album') ?? '未知专辑',
              'albumId': element.getAttribute('albumId'),
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

  // 发送 Now Playing 通知
  Future<void> notifyNowPlaying(String songId) async {
    await _scrobble(songId, submission: false);
  }

  // 提交 Scrobble
  Future<void> submitScrobble(String songId) async {
    await _scrobble(songId, submission: true);
  }

  // 内部 scrobble 方法
  Future<void> _scrobble(String songId, {required bool submission}) async {
    try {
      final url = Uri.parse('$baseUrl/rest/scrobble');

      final params = {
        'u': username,
        'p': password,
        'v': '1.16.0',
        'c': 'MyMusicPlayer',
        'f': 'xml',
        'id': songId,
        'submission': submission ? 'true' : 'false',
      };

      // 在 Navidrome + Last.fm 场景下，不传递 time 参数
      // 让 Navidrome 自己处理时间戳，避免格式问题

      final urlWithParams = url.replace(queryParameters: params);
      print(
        '📡 ${submission ? 'Scrobble 提交' : 'Now Playing 通知'} URL: $urlWithParams',
      );

      final response = await http.get(urlWithParams);
      print(
        '📡 ${submission ? 'Scrobble 提交' : 'Now Playing 通知'} 响应状态: ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        print(
          '${submission ? 'Scrobble 提交' : 'Now Playing 通知'} 失败: ${response.statusCode}',
        );
        print('📄 响应内容: ${response.body}');
      }
    } catch (e) {
      print('${submission ? 'Scrobble 提交' : 'Now Playing 通知'} 失败: $e');
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
                    'artistId': element.getAttribute('artistId'),
                    'album': element.getAttribute('album') ?? '未知专辑',
                    'albumId': element.getAttribute('albumId'),
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
              'artistId': element.getAttribute('artistId'),
              'album': element.getAttribute('album'),
              'albumId': element.getAttribute('albumId'),
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

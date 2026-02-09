import 'package:xml/xml.dart';
import 'dart:convert';
import '../subsonic/subsonic_api_base.dart';

// 播放列表相关API
class SubsonicPlaylist extends SubsonicApiBase {
  SubsonicPlaylist({
    required super.baseUrl,
    required super.username,
    required super.password,
  });

  // 获取所有歌单
  Future<List<Map<String, dynamic>>> getPlaylists() async {
    // 检查缓存
    if (SubsonicApiBase.cachedPlaylists != null) {
      print('✅ 使用缓存的歌单数据');
      return SubsonicApiBase.cachedPlaylists!;
    }

    try {
      final response = await sendGetRequest('getPlaylists');

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

        // 缓存数据
        SubsonicApiBase.cachedPlaylists = playlists;
        print('✅ 解析到 ${playlists.length} 个歌单并缓存');
        return playlists;
      } else {
        throw Exception('获取歌单失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌单失败: $e');
      return [];
    }
  }

  // 获取指定歌单的所有歌曲
  Future<List<Map<String, dynamic>>> getPlaylistSongs(String playlistId) async {
    // 检查缓存
    if (SubsonicApiBase.cachedPlaylistSongs.containsKey(playlistId)) {
      print('✅ 使用缓存的歌单歌曲数据: $playlistId');
      return SubsonicApiBase.cachedPlaylistSongs[playlistId]!;
    }

    try {
      final extraParams = {
        'id': playlistId,
      };

      final response = await sendGetRequest('getPlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
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

        // 缓存数据
        SubsonicApiBase.cachedPlaylistSongs[playlistId] = songs;
        print('✅ 解析到 ${songs.length} 首歌单歌曲并缓存: $playlistId');
        return songs;
      } else {
        throw Exception('获取歌单歌曲失败: ${response.statusCode}');
      }
    } catch (e) {
      print('获取歌单歌曲失败: $e');
      return [];
    }
  }

  // 创建播放列表
  Future<bool> createPlaylist(
    String name,
    List<String> songIds, {
    String? comment,
  }) async {
    try {
      final extraParams = {
        'name': name,
        if (songIds.isNotEmpty) 'songId': songIds.join(','),
      };

      final response = await sendGetRequest('createPlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表 "$name" 创建成功');
        
        // 清除歌单缓存
        clearPlaylistCache();
        
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
      final extraParams = {
        'playlistId': playlistId,
        if (name != null && name.isNotEmpty) 'name': name,
        if (comment != null) 'comment': comment,
        if (isPublic != null) 'public': isPublic.toString(),
      };

      final response = await sendGetRequest('updatePlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表更新成功');
        // 清除歌单缓存
        clearPlaylistCache();
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
      final extraParams = {
        'id': playlistId,
      };

      final response = await sendGetRequest('deletePlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        print('✅ 播放列表删除成功');
        // 清除歌单缓存
        clearPlaylistCache();
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
      final extraParams = {
        'playlistId': playlistId,
        'songIdToAdd': songId,
      };

      final response = await sendGetRequest('updatePlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        print('✅ 歌曲添加到歌单成功');
        // 清除歌单缓存
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

      final extraParams = {
        'playlistId': playlistId,
        'songIndexToRemove': songIndex.toString(),
      };

      final response = await sendGetRequest('updatePlaylist', extraParams: extraParams);

      if (response.statusCode == 200) {
        print('✅ 歌曲从歌单中删除成功');
        // 清除歌单缓存
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
}

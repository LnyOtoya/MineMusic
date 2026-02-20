import 'dart:convert';
import '../subsonic/subsonic_api_base.dart';
import '../subsonic/subsonic_music_library.dart';
import '../subsonic/subsonic_playlist.dart';
import '../subsonic/subsonic_artist_avatar.dart';
import 'package:xml/xml.dart';
import '../../models/lyrics_model.dart';

// 主 Subsonic API 类，整合所有模块
class SubsonicApi {
  final String baseUrl;
  final String username;
  final String password;

  // 模块实例
  late final SubsonicApiBase _base;
  late final SubsonicMusicLibrary _musicLibrary;
  late final SubsonicPlaylist _playlist;
  late final SubsonicArtistAvatar _artistAvatar;

  SubsonicApi({
    required this.baseUrl,
    required this.username,
    required this.password,
  }) {
    _base = SubsonicApiBase(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    _musicLibrary = SubsonicMusicLibrary(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    _playlist = SubsonicPlaylist(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
    _artistAvatar = SubsonicArtistAvatar(
      baseUrl: baseUrl,
      username: username,
      password: password,
    );
  }

  // 清除所有缓存
  Future<void> clearAllCache() => _base.clearAllCache();
  void clearPlaylistCache() => _playlist.clearPlaylistCache();
  void clearArtistCache() => _base.clearArtistCache();
  void clearAlbumCache() => _base.clearAlbumCache();
  void clearMusicFolderCache() => _base.clearMusicFolderCache();
  void clearGenreCache() => _base.clearGenreCache();
  void clearAllSongsCache() => _base.clearAllSongsCache();
  
  // 缓存大小管理
  Future<void> saveCacheSizeLimit(int limit) async {
    await SubsonicApiBase.saveCacheSizeLimit(limit);
  }
  
  int getCacheSizeLimit() {
    return SubsonicApiBase.getCacheSizeLimit();
  }
  
  Map<String, int> getCacheSizeOptions() {
    return SubsonicApiBase.cacheSizeOptions;
  }
  
  Future<int> calculateCurrentCacheSize() async {
    return await SubsonicApiBase.calculateCurrentCacheSize();
  }

  // 基础方法
  String getCoverArtUrl(String coverArtId) => _base.getCoverArtUrl(coverArtId);
  String getSongPlayUrl(String songId) => _base.getSongPlayUrl(songId);

  // 音乐库相关方法
  Future<bool> ping() async {
    try {
      final response = await _base.sendGetRequest('ping', extraParams: {
        'c': 'otimeum',
      });
      return response.statusCode == 200 && response.body.contains('status="ok"');
    } catch (e) {
      print('连接测试失败: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getMusicFolders() => _musicLibrary.getMusicFolders();
  Future<List<Map<String, dynamic>>> getArtists() => _musicLibrary.getArtists();
  Future<List<Map<String, dynamic>>> getAlbums({int size = 50, int offset = 0}) => 
      _musicLibrary.getAlbums(size: size, offset: offset);
  Future<List<Map<String, dynamic>>> getRandomSongs({int count = 20}) => 
      _musicLibrary.getRandomSongs(count: count);
  Future<List<Map<String, dynamic>>> getSongsByAlbum(String albumId) => 
      _musicLibrary.getSongsByAlbum(albumId);
  Future<List<Map<String, dynamic>>> getSongsByArtist(String artistId) => 
      _musicLibrary.getSongsByArtist(artistId);
  Future<List<Map<String, dynamic>>> getAlbumsByArtist(String artistId) => 
      _musicLibrary.getAlbumsByArtist(artistId);
  Future<List<Map<String, dynamic>>> getAllSongs() => _musicLibrary.getAllSongs();
  Future<List<Map<String, dynamic>>> getRecentAlbums({int size = 20}) => 
      _musicLibrary.getRecentAlbums(size: size);
  Future<List<Map<String, dynamic>>> getRandomAlbums({int size = 20}) => 
      _musicLibrary.getRandomAlbums(size: size);

  // 播放列表相关方法
  Future<List<Map<String, dynamic>>> getPlaylists() => _playlist.getPlaylists();
  Future<List<Map<String, dynamic>>> getPlaylistSongs(String playlistId) => 
      _playlist.getPlaylistSongs(playlistId);
  Future<bool> createPlaylist(String name, List<String> songIds, {String? comment}) => 
      _playlist.createPlaylist(name, songIds, comment: comment);
  Future<bool> updatePlaylist(String playlistId, {String? name, String? comment, bool? isPublic}) => 
      _playlist.updatePlaylist(playlistId, name: name, comment: comment, isPublic: isPublic);
  Future<bool> deletePlaylist(String playlistId) => _playlist.deletePlaylist(playlistId);
  Future<bool> addSongToPlaylist(String playlistId, String songId) => 
      _playlist.addSongToPlaylist(playlistId, songId);
  Future<bool> removeSongFromPlaylist(String playlistId, String songId) => 
      _playlist.removeSongFromPlaylist(playlistId, songId);

  // 歌手头像相关方法
  Future<String?> getArtistAvatar(String artistName, {String? artistId, String? songTitle}) => 
      _artistAvatar.getArtistAvatar(artistName, artistId: artistId, songTitle: songTitle);

  // 播放状态相关方法
  Future<void> notifyNowPlaying(String songId) async {
    try {
      await _base.sendGetRequest('scrobble', extraParams: {
        'id': songId,
        'submission': 'false',
      });
    } catch (e) {
      print('通知播放状态失败: $e');
    }
  }

  Future<void> submitScrobble(String songId) async {
    try {
      await _base.sendGetRequest('scrobble', extraParams: {
        'id': songId,
        'submission': 'true',
      });
    } catch (e) {
      print('提交播放记录失败: $e');
    }
  }

  // 搜索方法
  Future<Map<String, List<Map<String, dynamic>>>> search3({
    required String query,
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    try {
      final extraParams = {
        'query': query,
        'artistCount': artistCount.toString(),
        'albumCount': albumCount.toString(),
        'songCount': songCount.toString(),
      };

      final response = await _base.sendGetRequest('search3', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);

        // 解析艺术家
        final artistElements = document.findAllElements('artist');
        final artists = artistElements.map((element) {
          return {
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'albumCount': element.getAttribute('albumCount'),
          };
        }).toList();

        // 解析专辑
        final albumElements = document.findAllElements('album');
        final albums = albumElements.map((element) {
          return {
            'id': element.getAttribute('id'),
            'name': element.getAttribute('name'),
            'artist': element.getAttribute('artist'),
            'artistId': element.getAttribute('artistId'),
            'songCount': element.getAttribute('songCount'),
            'coverArt': element.getAttribute('coverArt'),
          };
        }).toList();

        // 解析歌曲
        final songElements = document.findAllElements('song');
        final songs = songElements.map((element) {
          return {
            'id': element.getAttribute('id'),
            'title': element.getAttribute('title'),
            'artist': element.getAttribute('artist'),
            'artistId': element.getAttribute('artistId'),
            'album': element.getAttribute('album'),
            'albumId': element.getAttribute('albumId'),
            'duration': element.getAttribute('duration'),
            'coverArt': element.getAttribute('coverArt'),
          };
        }).toList();

        return {
          'artists': artists,
          'albums': albums,
          'songs': songs,
        };
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索失败: $e');
      return {
        'artists': [],
        'albums': [],
        'songs': [],
      };
    }
  }

  // 按年份范围获取歌曲
  Future<List<Map<String, dynamic>>> getSongsByYearRange(int startYear, int endYear, {
    int count = 20,
    String? excludeArtist,
  }) async {
    try {
      // 这里使用search3作为替代，因为Subsonic API没有直接的按年份范围获取歌曲的方法
      // 实际实现可能需要根据服务器支持的API进行调整
      final result = await search3(query: '');
      var songs = result['songs'] ?? [];

      // 过滤掉指定艺术家的歌曲
      if (excludeArtist != null) {
        songs = songs.where((song) => song['artist'] != excludeArtist).toList();
      }

      // 限制返回数量
      if (count > 0 && songs.length > count) {
        songs = songs.take(count).toList();
      }

      return songs;
    } catch (e) {
      print('按年份范围获取歌曲失败: $e');
      return [];
    }
  }

  // 按艺术家名称获取歌曲
  Future<List<Map<String, dynamic>>> getSongsByArtistName(String artistName) async {
    try {
      final result = await search3(query: artistName);
      return result['songs'] ?? [];
    } catch (e) {
      print('按艺术家名称获取歌曲失败: $e');
      return [];
    }
  }

  // 获取所有歌曲（通过搜索）
  Future<List<Map<String, dynamic>>> getAllSongsViaSearch() async {
    try {
      // 检查缓存
      final cachedSongs = _base.getCacheData('allSongs');
      if (cachedSongs != null) {
        print('✅ 使用缓存的所有歌曲数据: ${cachedSongs.length} 首歌曲');
        return cachedSongs;
      }

      final extraParams = {
        'query': '',
        'songCount': '500',
      };

      final response = await _base.sendGetRequest('search3', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        // 解析XML响应
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

        // 缓存结果
        await _base.setCacheData('allSongs', songs);
        
        print('✅ 通过搜索获取到 ${songs.length} 首歌曲并缓存');
        return songs;
      } else {
        throw Exception('HTTP 错误: ${response.statusCode}');
      }
    } catch (e) {
      print('搜索所有歌曲失败: $e');
      return [];
    }
  }

  Future<LyricsData?> getLyricsBySongId(String songId) async {
    try {
      final extraParams = {
        'id': songId,
      };

      final response = await _base.sendGetRequest('getLyricsBySongId', extraParams: extraParams);

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final document = XmlDocument.parse(responseBody);

        final lyricsListElement = document.findAllElements('lyricsList').firstOrNull;
        if (lyricsListElement == null) {
          print('未找到歌词数据');
          return null;
        }

        final structuredLyricsElements = lyricsListElement.findAllElements('structuredLyrics');

        if (structuredLyricsElements.isEmpty) {
          print('未找到结构化歌词');
          return null;
        }

        final firstLyricsElement = structuredLyricsElements.first;

        final displayArtist = firstLyricsElement.getAttribute('displayArtist') ?? '';
        final displayTitle = firstLyricsElement.getAttribute('displayTitle') ?? '';
        final lang = firstLyricsElement.getAttribute('lang') ?? 'und';
        final offset = int.tryParse(firstLyricsElement.getAttribute('offset') ?? '0') ?? 0;
        final synced = firstLyricsElement.getAttribute('synced') == 'true';

        final lineElements = firstLyricsElement.findAllElements('line');
        final lines = lineElements.map((element) {
          final startTime = int.tryParse(element.getAttribute('start') ?? '0') ?? 0;
          final text = element.innerText;
          return LyricLine(
            startTime: startTime,
            text: text,
          );
        }).toList();

        return LyricsData(
          displayArtist: displayArtist,
          displayTitle: displayTitle,
          lang: lang,
          offset: offset,
          synced: synced,
          lines: lines,
        );
      } else {
        print('获取歌词失败: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取歌词失败: $e');
      return null;
    }
  }
}

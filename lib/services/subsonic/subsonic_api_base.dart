import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/constants.dart';

// Subsonic API 基础类，包含通用方法和缓存管理
class SubsonicApiBase {
  final String baseUrl;
  final String username;
  final String password;

  // 缓存数据
  static List<Map<String, dynamic>>? cachedPlaylists;
  static List<Map<String, dynamic>>? cachedArtists;
  static List<Map<String, dynamic>>? cachedAlbums;
  static List<Map<String, dynamic>>? cachedMusicFolders;
  static List<Map<String, dynamic>>? cachedGenres;
  static Map<String, List<Map<String, dynamic>>> cachedAlbumSongs = {};
  static Map<String, List<Map<String, dynamic>>> cachedArtistSongs = {};
  static Map<String, List<Map<String, dynamic>>> cachedPlaylistSongs = {};

  // 缓存过期时间（毫秒）
  static final Duration _cacheExpiration = Duration(hours: CACHE_EXPIRATION_HOURS);
  
  // 缓存时间戳
  static Map<String, int> _cacheTimestamps = {
    'playlists': 0,
    'artists': 0,
    'albums': 0,
    'musicFolders': 0,
    'genres': 0,
  };
  
  // 缓存键前缀
  static const String _cacheKeyPrefix = CACHE_KEY_PREFIX;

  // 初始化持久化缓存
  static Future<void> initializeCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载缓存数据
      cachedPlaylists = _loadCacheData(prefs, 'playlists');
      cachedArtists = _loadCacheData(prefs, 'artists');
      cachedAlbums = _loadCacheData(prefs, 'albums');
      cachedMusicFolders = _loadCacheData(prefs, 'musicFolders');
      cachedGenres = _loadCacheData(prefs, 'genres');
      
      // 加载缓存时间戳
      _loadCacheTimestamps(prefs);
      
      print('✅ 持久化缓存初始化完成');
    } catch (e) {
      print('初始化持久化缓存失败: $e');
    }
  }
  
  // 加载缓存数据
  static List<Map<String, dynamic>>? _loadCacheData(SharedPreferences prefs, String key) {
    try {
      final timestampKey = '${_cacheKeyPrefix}${key}_timestamp';
      final dataKey = '${_cacheKeyPrefix}${key}_data';
      
      // 检查缓存是否过期
      final timestamp = prefs.getInt(timestampKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      if (now - timestamp > _cacheExpiration.inMilliseconds) {
        print('⏰ 缓存已过期: $key');
        return null;
      }
      
      // 加载缓存数据
      final jsonData = prefs.getString(dataKey);
      if (jsonData != null) {
        final List<dynamic> data = jsonDecode(jsonData);
        return data.map((item) => item as Map<String, dynamic>).toList();
      }
      
      return null;
    } catch (e) {
      print('加载缓存数据失败 ($key): $e');
      return null;
    }
  }
  
  // 加载缓存时间戳
  static void _loadCacheTimestamps(SharedPreferences prefs) {
    try {
      for (final key in _cacheTimestamps.keys) {
        final timestampKey = '${_cacheKeyPrefix}${key}_timestamp';
        _cacheTimestamps[key] = prefs.getInt(timestampKey) ?? 0;
      }
    } catch (e) {
      print('加载缓存时间戳失败: $e');
    }
  }
  
  // 保存缓存数据
  static Future<void> _saveCacheData(String key, List<Map<String, dynamic>>? data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampKey = '${_cacheKeyPrefix}${key}_timestamp';
      final dataKey = '${_cacheKeyPrefix}${key}_data';
      
      if (data != null) {
        // 保存缓存数据和时间戳
        prefs.setString(dataKey, jsonEncode(data));
        prefs.setInt(timestampKey, DateTime.now().millisecondsSinceEpoch);
        _cacheTimestamps[key] = DateTime.now().millisecondsSinceEpoch;
        print('✅ 缓存数据已保存: $key (${data.length} 项)');
      } else {
        // 清除缓存数据
        prefs.remove(dataKey);
        prefs.remove(timestampKey);
        _cacheTimestamps[key] = 0;
        print('🗑️ 缓存数据已清除: $key');
      }
    } catch (e) {
      print('保存缓存数据失败 ($key): $e');
    }
  }
  
  // 检查缓存是否有效
  static bool _isCacheValid(String key) {
    final timestamp = _cacheTimestamps[key] ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - timestamp < _cacheExpiration.inMilliseconds;
  }

  // 请求队列
  static final List<Map<String, dynamic>> _requestQueue = [];
  static bool _isProcessingQueue = false;
  static const int _maxConcurrentRequests = MAX_CONCURRENT_REQUESTS;
  static final Map<String, Completer<http.Response>> _inFlightRequests = {};

  SubsonicApiBase({
    required this.baseUrl,
    required this.username,
    required this.password,
  });

  // 清理所有缓存
  Future<void> clearAllCache() async {
    // 清理内存缓存
    cachedPlaylists = null;
    cachedArtists = null;
    cachedAlbums = null;
    cachedMusicFolders = null;
    cachedGenres = null;
    cachedAlbumSongs.clear();
    cachedArtistSongs.clear();
    cachedPlaylistSongs.clear();
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.startsWith(_cacheKeyPrefix)) {
          await prefs.remove(key);
        }
      }
      // 重置缓存时间戳
      _cacheTimestamps.forEach((key, value) {
        _cacheTimestamps[key] = 0;
      });
      print('✅ 所有缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理持久化缓存失败: $e');
    }
  }

  // 清理歌单缓存
  Future<void> clearPlaylistCache() async {
    // 清理内存缓存
    cachedPlaylists = null;
    cachedPlaylistSongs.clear();
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}playlists_data');
      await prefs.remove('${_cacheKeyPrefix}playlists_timestamp');
      _cacheTimestamps['playlists'] = 0;
      print('✅ 歌单缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理歌单持久化缓存失败: $e');
    }
  }

  // 清理艺术家缓存
  Future<void> clearArtistCache() async {
    // 清理内存缓存
    cachedArtists = null;
    cachedArtistSongs.clear();
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}artists_data');
      await prefs.remove('${_cacheKeyPrefix}artists_timestamp');
      _cacheTimestamps['artists'] = 0;
      print('✅ 艺术家缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理艺术家持久化缓存失败: $e');
    }
  }

  // 清理专辑缓存
  Future<void> clearAlbumCache() async {
    // 清理内存缓存
    cachedAlbums = null;
    cachedAlbumSongs.clear();
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}albums_data');
      await prefs.remove('${_cacheKeyPrefix}albums_timestamp');
      _cacheTimestamps['albums'] = 0;
      print('✅ 专辑缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理专辑持久化缓存失败: $e');
    }
  }

  // 清理音乐文件夹缓存
  Future<void> clearMusicFolderCache() async {
    // 清理内存缓存
    cachedMusicFolders = null;
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}musicFolders_data');
      await prefs.remove('${_cacheKeyPrefix}musicFolders_timestamp');
      _cacheTimestamps['musicFolders'] = 0;
      print('✅ 音乐文件夹缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理音乐文件夹持久化缓存失败: $e');
    }
  }

  // 清理流派缓存
  Future<void> clearGenreCache() async {
    // 清理内存缓存
    cachedGenres = null;
    
    // 清理持久化缓存
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_cacheKeyPrefix}genres_data');
      await prefs.remove('${_cacheKeyPrefix}genres_timestamp');
      _cacheTimestamps['genres'] = 0;
      print('✅ 流派缓存已清理（内存和持久化）');
    } catch (e) {
      print('清理流派持久化缓存失败: $e');
    }
  }

  // 设置缓存数据（同时更新内存和持久化缓存）
  Future<void> setCacheData(String key, List<Map<String, dynamic>> data) async {
    // 更新内存缓存
    switch (key) {
      case 'playlists':
        cachedPlaylists = data;
        break;
      case 'artists':
        cachedArtists = data;
        break;
      case 'albums':
        cachedAlbums = data;
        break;
      case 'musicFolders':
        cachedMusicFolders = data;
        break;
      case 'genres':
        cachedGenres = data;
        break;
    }
    
    // 更新持久化缓存
    await _saveCacheData(key, data);
  }

  // 获取缓存数据（带过期检查）
  List<Map<String, dynamic>>? getCacheData(String key) {
    if (!_isCacheValid(key)) {
      print('⏰ 缓存已过期: $key');
      return null;
    }
    
    switch (key) {
      case 'playlists':
        return cachedPlaylists;
      case 'artists':
        return cachedArtists;
      case 'albums':
        return cachedAlbums;
      case 'musicFolders':
        return cachedMusicFolders;
      case 'genres':
        return cachedGenres;
      default:
        return null;
    }
  }

  // 构建请求参数
  Map<String, String> buildParams({Map<String, String>? extraParams}) {
    final params = {
      'u': username,
      'p': password,
      'v': API_VERSION,
      'c': APP_NAME,
      'f': API_FORMAT,
    };

    if (extraParams != null) {
      params.addAll(extraParams);
    }

    return params;
  }

  // 发送GET请求（带重试机制和请求队列）
  Future<http.Response> sendGetRequest(String endpoint, {Map<String, String>? extraParams}) async {
    final params = buildParams(extraParams: extraParams);
    final requestKey = '$endpoint-${params.toString()}';

    // 检查是否有相同的请求正在进行
    if (_inFlightRequests.containsKey(requestKey)) {
      print('🔄 等待相同请求完成: $endpoint');
      return _inFlightRequests[requestKey]!.future;
    }

    // 创建请求完成器
    final completer = Completer<http.Response>();
    _inFlightRequests[requestKey] = completer;

    // 添加到请求队列
    _requestQueue.add({
      'completer': completer,
      'endpoint': endpoint,
      'extraParams': extraParams,
      'requestKey': requestKey,
      'api': this,
    });
    print('📋 请求加入队列: $endpoint (队列长度: ${_requestQueue.length})');

    // 开始处理队列
    _processQueue();

    // 等待请求完成
    try {
      final response = await completer.future;
      return response;
    } finally {
      _inFlightRequests.remove(requestKey);
    }
  }

  // 处理请求队列
  static void _processQueue() async {
    if (_isProcessingQueue || _requestQueue.isEmpty) {
      return;
    }

    _isProcessingQueue = true;

    try {
      while (_requestQueue.isNotEmpty && _inFlightRequests.length < _maxConcurrentRequests) {
        final requestInfo = _requestQueue.removeAt(0);
        final completer = requestInfo['completer'] as Completer<http.Response>;
        final endpoint = requestInfo['endpoint'] as String;
        final extraParams = requestInfo['extraParams'] as Map<String, String>?;
        final requestKey = requestInfo['requestKey'] as String;
        final api = requestInfo['api'] as SubsonicApiBase;

        print('🔄 开始处理请求: $endpoint (队列剩余: ${_requestQueue.length})');

        // 处理请求
        api._sendSingleRequest(endpoint, extraParams: extraParams).then((response) {
          if (!completer.isCompleted) {
            completer.complete(response);
          }
        }).catchError((error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        });
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  // 发送单个请求（带重试机制）
  Future<http.Response> _sendSingleRequest(String endpoint, {Map<String, String>? extraParams, int retryCount = MAX_RETRY_COUNT}) async {
    final url = Uri.parse('$baseUrl/rest/$endpoint');
    final params = buildParams(extraParams: extraParams);
    final urlWithParams = url.replace(queryParameters: params);
    
    print('🌐 请求URL: $urlWithParams');
    
    int attempts = 0;
    while (attempts < retryCount) {
      try {
        final response = await http.get(urlWithParams, headers: {
          'Cache-Control': 'max-age=3600', // 添加缓存控制头
        }).timeout(
          Duration(seconds: REQUEST_TIMEOUT_SECONDS),
          onTimeout: () {
            print('⏰ 请求超时');
            throw Exception(ERROR_NETWORK_TIMEOUT);
          },
        );
        
        print('📡 响应状态: ${response.statusCode}');
        return response;
      } catch (e) {
        attempts++;
        print('发送请求失败 (尝试 $attempts/$retryCount): $e');
        
        if (attempts >= retryCount) {
          print('达到最大重试次数，请求失败');
          rethrow;
        }
        
        // 指数退避策略
        final delay = Duration(milliseconds: 500 * attempts);
        print('等待 ${delay.inMilliseconds}ms 后重试...');
        await Future.delayed(delay);
      }
    }
    
    throw Exception('请求失败');
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
}

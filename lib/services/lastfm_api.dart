import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../utils/lastfm_config.dart';
import 'secure_storage_service.dart';

class LastFMApi {
  static const String baseUrl = 'https://ws.audioscrobbler.com/2.0/';
  static const String authUrl = 'https://www.last.fm/api/auth/';
  
  final SecureStorageService _storage = SecureStorageService();

  Future<String> getAuthToken() async {
    if (!LastFMConfig.isConfigured) {
      throw Exception('LastFM API未配置，请设置LASTFM_API_KEY和LASTFM_SHARED_SECRET');
    }

    final url = Uri.parse('$baseUrl?method=auth.gettoken&api_key=${LastFMConfig.apiKey}');
    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取token失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final tokenElement = document.findAllElements('token').firstOrNull;

    if (tokenElement == null) {
      throw Exception('解析token失败');
    }

    return tokenElement.innerText;
  }

  String _generateSignature(Map<String, String> params) {
    final sortedKeys = params.keys.toList()..sort();
    final signatureString = sortedKeys.map((key) => '$key${params[key]}').join('') + LastFMConfig.sharedSecret;
    
    final bytes = utf8.encode(signatureString);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  Future<String> getSessionKey(String token) async {
    final params = {
      'method': 'auth.getsession',
      'api_key': LastFMConfig.apiKey,
      'token': token,
    };

    final apiSig = _generateSignature(params);
    final url = Uri.parse('$baseUrl?method=auth.getsession&api_key=${LastFMConfig.apiKey}&token=$token&api_sig=$apiSig');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取session失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final sessionElement = document.findAllElements('session').firstOrNull;

    if (sessionElement == null) {
      throw Exception('解析session失败');
    }

    final sessionKey = sessionElement.findAllElements('key').firstOrNull?.innerText;
    final username = sessionElement.findAllElements('name').firstOrNull?.innerText;

    if (sessionKey == null) {
      throw Exception('获取session key失败');
    }

    await _storage.write(key: 'lastfm_session', value: sessionKey);
    await _storage.write(key: 'lastfm_username', value: username ?? '');

    return sessionKey;
  }

  Future<bool> isAuthenticated() async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    return sessionKey != null && sessionKey.isNotEmpty;
  }

  Future<String?> getUsername() async {
    return await _storage.read(key: 'lastfm_username');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'lastfm_session');
    await _storage.delete(key: 'lastfm_username');
  }

  Future<Map<String, dynamic>> getRecentTracks({int limit = 50}) async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    if (sessionKey == null) {
      throw Exception('未授权，请先登录');
    }

    final username = await getUsername();
    if (username == null) {
      throw Exception('未找到用户名');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$baseUrl?method=user.getrecenttracks&user=$username&api_key=${LastFMConfig.apiKey}&limit=$limit&_=$timestamp');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取最近播放失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final tracksElement = document.findAllElements('recenttracks').firstOrNull;

    if (tracksElement == null) {
      return {'tracks': []};
    }

    final trackElements = tracksElement.findAllElements('track');
    final tracks = trackElements.map((element) {
      final artistElement = element.findAllElements('artist').firstOrNull;
      final albumElement = element.findAllElements('album').firstOrNull;
      final nameElement = element.findAllElements('name').firstOrNull;
      final imageElements = element.findAllElements('image');

      final images = imageElements.map((img) => img.innerText).toList();

      final nowplayingAttr = element.getAttribute('nowplaying');
      final isNowPlaying = nowplayingAttr == 'true';

      final dateElement = element.findAllElements('date').firstOrNull;
      final uts = dateElement?.getAttribute('uts');
      final playedAt = uts != null ? DateTime.fromMillisecondsSinceEpoch(int.parse(uts) * 1000) : null;

      return {
        'name': nameElement?.innerText ?? '',
        'artist': artistElement?.innerText ?? '',
        'album': albumElement?.innerText ?? '',
        'images': images,
        'isNowPlaying': isNowPlaying,
        'playedAt': playedAt,
      };
    }).toList();

    return {'tracks': tracks};
  }

  Future<Map<String, dynamic>> getTopArtists({int limit = 50, String period = 'overall'}) async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    if (sessionKey == null) {
      throw Exception('未授权，请先登录');
    }

    final username = await getUsername();
    if (username == null) {
      throw Exception('未找到用户名');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$baseUrl?method=user.gettopartists&user=$username&api_key=${LastFMConfig.apiKey}&limit=$limit&period=$period&_=$timestamp');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取顶级艺术家失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final topArtistsElement = document.findAllElements('topartists').firstOrNull;

    if (topArtistsElement == null) {
      return {'artists': []};
    }

    final artistElements = topArtistsElement.findAllElements('artist');
    final artists = artistElements.map((element) {
      final imageElements = element.findAllElements('image');
      final images = imageElements.map((img) => img.innerText).toList();

      return {
        'name': element.findAllElements('name').firstOrNull?.innerText ?? '',
        'playcount': element.findAllElements('playcount').firstOrNull?.innerText ?? '0',
        'rank': element.getAttribute('rank'),
        'images': images,
      };
    }).toList();

    return {'artists': artists};
  }

  Future<Map<String, dynamic>> getTopAlbums({int limit = 50, String period = 'overall'}) async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    if (sessionKey == null) {
      throw Exception('未授权，请先登录');
    }

    final username = await getUsername();
    if (username == null) {
      throw Exception('未找到用户名');
    }

    final url = Uri.parse('$baseUrl?method=user.gettopalbums&user=$username&api_key=${LastFMConfig.apiKey}&limit=$limit&period=$period');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取顶级专辑失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final topAlbumsElement = document.findAllElements('topalbums').firstOrNull;

    if (topAlbumsElement == null) {
      return {'albums': []};
    }

    final albumElements = topAlbumsElement.findAllElements('album');
    final albums = albumElements.map((element) {
      final artistElement = element.findAllElements('artist').firstOrNull;
      final artistName = artistElement?.findAllElements('name').firstOrNull?.innerText ?? '';
      
      final imageElements = element.findAllElements('image');
      final images = imageElements.map((img) => img.innerText).toList();

      return {
        'name': element.findAllElements('name').firstOrNull?.innerText ?? '',
        'artist': artistName,
        'playcount': element.findAllElements('playcount').firstOrNull?.innerText ?? '0',
        'rank': element.getAttribute('rank'),
        'images': images,
      };
    }).toList();

    return {'albums': albums};
  }

  Future<Map<String, dynamic>> getTopTracks({int limit = 50, String period = 'overall'}) async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    if (sessionKey == null) {
      throw Exception('未授权，请先登录');
    }

    final username = await getUsername();
    if (username == null) {
      throw Exception('未找到用户名');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url = Uri.parse('$baseUrl?method=user.gettoptracks&user=$username&api_key=${LastFMConfig.apiKey}&limit=$limit&period=$period&_=$timestamp');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取顶级歌曲失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final topTracksElement = document.findAllElements('toptracks').firstOrNull;

    if (topTracksElement == null) {
      return {'tracks': []};
    }

    final trackElements = topTracksElement.findAllElements('track');
    final tracks = trackElements.map((element) {
      final artistElement = element.findAllElements('artist').firstOrNull;
      final artistName = artistElement?.findAllElements('name').firstOrNull?.innerText ?? '';
      
      final imageElements = element.findAllElements('image');
      final images = imageElements.map((img) => img.innerText).toList();

      return {
        'name': element.findAllElements('name').firstOrNull?.innerText ?? '',
        'artist': artistName,
        'playcount': element.findAllElements('playcount').firstOrNull?.innerText ?? '0',
        'rank': element.getAttribute('rank'),
        'images': images,
      };
    }).toList();

    return {'tracks': tracks};
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final sessionKey = await _storage.read(key: 'lastfm_session');
    if (sessionKey == null) {
      throw Exception('未授权，请先登录');
    }

    final username = await getUsername();
    if (username == null) {
      throw Exception('未找到用户名');
    }

    final url = Uri.parse('$baseUrl?method=user.getinfo&user=$username&api_key=${LastFMConfig.apiKey}');

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('获取用户信息失败: ${response.statusCode}');
    }

    final document = XmlDocument.parse(response.body);
    final userElement = document.findAllElements('user').firstOrNull;

    if (userElement == null) {
      throw Exception('解析用户信息失败');
    }

    final imageElements = userElement.findAllElements('image');
    final images = imageElements.map((img) => img.innerText).toList();

    return {
      'name': userElement.findAllElements('name').firstOrNull?.innerText ?? '',
      'realname': userElement.findAllElements('realname').firstOrNull?.innerText ?? '',
      'url': userElement.findAllElements('url').firstOrNull?.innerText ?? '',
      'country': userElement.findAllElements('country').firstOrNull?.innerText ?? '',
      'age': userElement.findAllElements('age').firstOrNull?.innerText ?? '',
      'gender': userElement.findAllElements('gender').firstOrNull?.innerText ?? '',
      'playcount': userElement.findAllElements('playcount').firstOrNull?.innerText ?? '0',
      'artist_count': userElement.findAllElements('artist_count').firstOrNull?.innerText ?? '0',
      'album_count': userElement.findAllElements('album_count').firstOrNull?.innerText ?? '0',
      'track_count': userElement.findAllElements('track_count').firstOrNull?.innerText ?? '0',
      'registered': userElement.findAllElements('registered').firstOrNull?.getAttribute('unixtime') ?? '',
      'images': images,
    };
  }
}

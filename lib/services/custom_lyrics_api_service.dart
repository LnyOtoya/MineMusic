import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/custom_lyrics_api_config.dart';

class CustomLyricsApiService {
  static const String _storageKey = 'custom_lyrics_apis';
  static const String _selectedApiKey = 'selected_custom_lyrics_api';

  static List<CustomLyricsApiConfig> _cachedApis = [];
  static CustomLyricsApiConfig? _selectedApi;

  static Future<List<CustomLyricsApiConfig>> getCustomApis() async {
    if (_cachedApis.isNotEmpty) {
      return _cachedApis;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final apisJson = prefs.getStringList(_storageKey);

      if (apisJson != null && apisJson.isNotEmpty) {
        _cachedApis = apisJson
            .map(
              (json) => CustomLyricsApiConfig.fromJson(
                jsonDecode(json) as Map<String, dynamic>,
              ),
            )
            .toList();
        return _cachedApis;
      }
    } catch (e) {
      print('❌ 加载自定义API失败: $e');
    }

    return [];
  }

  static Future<void> saveCustomApis(List<CustomLyricsApiConfig> apis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apisJson = apis.map((api) => jsonEncode(api.toJson())).toList();
      await prefs.setStringList(_storageKey, apisJson);
      _cachedApis = apis;
      print('✅ 保存了 ${apis.length} 个自定义API');
    } catch (e) {
      print('❌ 保存自定义API失败: $e');
    }
  }

  static Future<void> addCustomApi(CustomLyricsApiConfig api) async {
    final apis = await getCustomApis();

    if (apis.any((a) => a.name == api.name)) {
      throw Exception('API名称已存在');
    }

    apis.add(api);
    await saveCustomApis(apis);
  }

  static Future<void> updateCustomApi(CustomLyricsApiConfig api) async {
    final apis = await getCustomApis();
    final index = apis.indexWhere((a) => a.name == api.name);

    if (index != -1) {
      apis[index] = api;
      await saveCustomApis(apis);
    }
  }

  static Future<void> deleteCustomApi(String name) async {
    final apis = await getCustomApis();
    apis.removeWhere((a) => a.name == name);
    await saveCustomApis(apis);

    if (_selectedApi?.name == name) {
      await clearSelectedApi();
    }
  }

  static Future<CustomLyricsApiConfig?> getSelectedApi() async {
    if (_selectedApi != null) {
      return _selectedApi;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final apiJson = prefs.getString(_selectedApiKey);

      if (apiJson != null && apiJson.isNotEmpty) {
        _selectedApi = CustomLyricsApiConfig.fromJson(
          jsonDecode(apiJson) as Map<String, dynamic>,
        );
        return _selectedApi;
      }
    } catch (e) {
      print('❌ 加载选中的API失败: $e');
    }

    return null;
  }

  static Future<void> setSelectedApi(CustomLyricsApiConfig? api) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (api == null) {
        await prefs.remove(_selectedApiKey);
      } else {
        await prefs.setString(_selectedApiKey, jsonEncode(api.toJson()));
      }

      _selectedApi = api;
      print('✅ 选中的API: ${api?.name}');
    } catch (e) {
      print('❌ 保存选中的API失败: $e');
    }
  }

  static Future<void> clearSelectedApi() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_selectedApiKey);
    _selectedApi = null;
  }

  static void clearCache() {
    _cachedApis = [];
    _selectedApi = null;
  }

  static Future<void> initializeDefaultApis() async {
    final apis = await getCustomApis();

    if (apis.isEmpty) {
      final defaultApi = CustomLyricsApiConfig(
        name: '我的自建API',
        baseUrl: 'http://192.168.31.215:4555',
        searchEndpoint: '/search/search_by_type',
        lyricEndpoint: '/lyric/get_lyric',
        searchMethod: 'GET',
        lyricMethod: 'GET',
        searchParams: {'search_type': 'song'},
        lyricParams: {'qrc': 'true', 'roma': 'true', 'trans': 'true'},
        songIdField: 'mid',
        titleField: 'title',
        artistField: 'artist',
        lyricField: 'lyric',
        translationField: 'trans',
        successCode: '200',
        dataField: 'data',
        artistPath: 'singer[0].name',
        isEnabled: true,
      );

      await addCustomApi(defaultApi);
      print('✅ 已添加默认自建API配置');
    }
  }
}

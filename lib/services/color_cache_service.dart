import 'package:flutter/material.dart';
import 'color_extractor_service.dart';

class ColorCacheService {
  static final Map<String, ColorScheme> _colorCache = {};
  static const int _maxCacheSize = 50;

  static Future<ColorScheme?> getColorScheme(
    String coverArtId,
    String coverArtUrl,
    Brightness brightness,
  ) async {
    final cacheKey = '${coverArtId}_${brightness.name}';

    if (_colorCache.containsKey(cacheKey)) {
      print('✅ 从缓存获取颜色方案: $coverArtId');
      return _colorCache[cacheKey];
    }

    print('🔄 开始提取颜色: $coverArtId');
    final colorScheme =
        await ColorExtractorService.extractFromImageWithBrightness(
          coverArtUrl,
          brightness,
        );

    if (colorScheme != null) {
      _addColorToCache(cacheKey, colorScheme);
    }

    return colorScheme;
  }

  static void _addColorToCache(String key, ColorScheme colorScheme) {
    if (_colorCache.length >= _maxCacheSize) {
      // 移除最旧的缓存项
      final oldestKey = _colorCache.keys.first;
      _colorCache.remove(oldestKey);
      print('⚠️ 缓存已满，移除最旧项: $oldestKey');
    }

    _colorCache[key] = colorScheme;
    print('✅ 添加颜色到缓存: $key');
    print('📊 缓存大小: ${_colorCache.length}/$_maxCacheSize');
  }

  static void clearCache() {
    _colorCache.clear();
    print('🗑️ 清空颜色缓存');
  }

  static int get cacheSize {
    return _colorCache.length;
  }
}

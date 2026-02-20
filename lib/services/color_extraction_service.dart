import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ColorExtractionService {
  static final ColorExtractionService _instance = ColorExtractionService._internal();
  factory ColorExtractionService() => _instance;
  ColorExtractionService._internal();

  final Map<String, ColorScheme> _colorSchemeCache = {};
  static const String _cacheKeyPrefix = 'album_color_';
  static const Duration _cacheExpiration = Duration(days: 7);

  Future<ColorScheme?> getColorSchemeFromImage(
    String imageUrl,
    Brightness brightness,
  ) async {
    final cacheKey = '$_cacheKeyPrefix${imageUrl.hashCode}_$brightness';
    
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(cacheKey);
    
    if (cachedData != null) {
      final parts = cachedData.split('|');
      if (parts.length == 3) {
        final timestamp = int.tryParse(parts[0]) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        
        if (now - timestamp < _cacheExpiration.inMilliseconds) {
          final seedColor = Color(int.parse(parts[1]));
          return ColorScheme.fromSeed(
            seedColor: seedColor,
            brightness: brightness,
          );
        }
      }
    }

    try {
      final paletteGenerator = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(100, 100),
        maximumColorCount: 16,
      );

      final dominantColor = paletteGenerator.dominantColor?.color ?? Colors.blue;
      
      final colorScheme = ColorScheme.fromSeed(
        seedColor: dominantColor,
        brightness: brightness,
      );

      await _cacheColorScheme(cacheKey, dominantColor, prefs);
      
      return colorScheme;
    } catch (e) {
      print('提取颜色失败: $e');
      return null;
    }
  }

  Future<void> _cacheColorScheme(
    String cacheKey,
    Color seedColor,
    SharedPreferences prefs,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final data = '$now|${seedColor.value}|';
    await prefs.setString(cacheKey, data);
  }

  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    for (final key in keys) {
      if (key.startsWith(_cacheKeyPrefix)) {
        await prefs.remove(key);
      }
    }
    
    _colorSchemeCache.clear();
  }

  ColorScheme getDefaultColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );
  }
}

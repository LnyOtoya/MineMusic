import 'package:flutter/material.dart';

class ColorExtractorService {
  static Future<ColorScheme?> extractFromImage(String imageUrl) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: Brightness.light,
      );
      print('✅ 成功提取颜色方案');
      print('   Primary: ${colorScheme.primary}');
      print('   Secondary: ${colorScheme.secondary}');
      print('   Surface: ${colorScheme.surface}');
      print('   OnSurface: ${colorScheme.onSurface}');
      return colorScheme;
    } catch (e) {
      print('❌ 提取颜色失败: $e');
      return null;
    }
  }

  static Future<ColorScheme?> extractFromImageWithBrightness(
    String imageUrl,
    Brightness brightness,
  ) async {
    try {
      final imageProvider = NetworkImage(imageUrl);
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: brightness,
      );
      return colorScheme;
    } catch (e) {
      print('❌ 提取颜色失败: $e');
      return null;
    }
  }
}

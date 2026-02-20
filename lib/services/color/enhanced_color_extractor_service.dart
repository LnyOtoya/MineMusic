import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'color_analyzer.dart';
import 'adaptive_color_handler.dart';

class ColorExtractionResult {
  final ColorScheme colorScheme;
  final Color seedColor;
  final List<Color> dominantColors;
  final String extractionTime;

  const ColorExtractionResult({
    required this.colorScheme,
    required this.seedColor,
    required this.dominantColors,
    required this.extractionTime,
  });

  @override
  String toString() =>
      'ColorExtractionResult(seed: $seedColor, '
      'dominantColors: ${dominantColors.length}, '
      'time: $extractionTime)';
}

class EnhancedColorExtractorService {
  static const int _maxImageSize = 112;
  static const int _minColorCount = 5;
  static const int _maxColorCount = 16;

  static Future<ColorExtractionResult> extractFromImage({
    required String imageUrl,
    required Brightness brightness,
    Color? preferredSeedColor,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final imageProvider = NetworkImage(imageUrl);

      final extractedScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: brightness,
      );

      final dominantColors = ColorAnalyzer.extractDominantColors(extractedScheme);

      final seedColor = preferredSeedColor ??
          _selectBestSeedColor(extractedScheme, dominantColors);

      final adaptedScheme = AdaptiveColorHandler.adjustColorSchemeForImageType(
        extractedScheme,
        dominantColors,
        brightness,
      );

      final finalScheme = AdaptiveColorHandler.ensureAccessibilityContrast(adaptedScheme);

      stopwatch.stop();

      print('✅ 颜色提取成功');
      print('   种子颜色: $seedColor');
      print('   主导颜色数量: ${dominantColors.length}');
      print('   提取时间: ${stopwatch.elapsedMilliseconds}ms');

      return ColorExtractionResult(
        colorScheme: finalScheme,
        seedColor: seedColor,
        dominantColors: dominantColors,
        extractionTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      stopwatch.stop();
      print('❌ 颜色提取失败: $e');
      rethrow;
    }
  }

  static Color _selectBestSeedColor(
    ColorScheme scheme,
    List<Color> dominantColors,
  ) {
    if (dominantColors.isEmpty) {
      return scheme.primary;
    }

    final frequencyMap = <Color, int>{};
    for (final color in dominantColors) {
      frequencyMap[color] = (frequencyMap[color] ?? 0) + 1;
    }

    final bestColor = ColorAnalyzer.findBestSeedColor(
      dominantColors,
      frequencyMap,
    );

    print('🎯 智能选择种子颜色: $bestColor');

    return bestColor;
  }

  static Future<ColorExtractionResult> extractWithRetry({
    required String imageUrl,
    required Brightness brightness,
    int maxRetries = 2,
  }) async {
    Exception? lastError;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await extractFromImage(
          imageUrl: imageUrl,
          brightness: brightness,
        );
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        print('⚠️ 提取失败 (尝试 ${attempt + 1}/${maxRetries + 1}): $e');

        if (attempt < maxRetries) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    print('❌ 所有重试失败，使用默认颜色方案');
    return _getDefaultColorScheme(brightness);
  }

  static ColorExtractionResult _getDefaultColorScheme(Brightness brightness) {
    final defaultSeed = Colors.blue;
    final defaultScheme = ColorScheme.fromSeed(
      seedColor: defaultSeed,
      brightness: brightness,
    );

    return ColorExtractionResult(
      colorScheme: defaultScheme,
      seedColor: defaultSeed,
      dominantColors: [defaultSeed],
      extractionTime: 'default',
    );
  }

  static Future<ColorExtractionResult> extractFromLocalImage({
    required Uint8List imageBytes,
    required Brightness brightness,
  }) async {
    final stopwatch = Stopwatch()..start();

    try {
      final extractedScheme = await ColorScheme.fromImageProvider(
        provider: MemoryImage(imageBytes),
        brightness: brightness,
      );

      final dominantColors = ColorAnalyzer.extractDominantColors(extractedScheme);
      final seedColor = _selectBestSeedColor(extractedScheme, dominantColors);

      final adaptedScheme = AdaptiveColorHandler.adjustColorSchemeForImageType(
        extractedScheme,
        dominantColors,
        brightness,
      );

      final finalScheme = AdaptiveColorHandler.ensureAccessibilityContrast(adaptedScheme);

      stopwatch.stop();

      return ColorExtractionResult(
        colorScheme: finalScheme,
        seedColor: seedColor,
        dominantColors: dominantColors,
        extractionTime: '${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      stopwatch.stop();
      print('❌ 本地图片颜色提取失败: $e');
      rethrow;
    }
  }

  static bool isColorExtractionSuccessful(ColorExtractionResult result) {
    return result.extractionTime != 'default';
  }

  static ColorScheme getFallbackColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );
  }
}

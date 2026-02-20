import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'playback_state_service.dart';
import 'color/enhanced_color_extractor_service.dart';

class ColorSchemePair {
  final ColorScheme light;
  final ColorScheme dark;
  final Color seedColor;
  final DateTime updatedAt;

  const ColorSchemePair({
    required this.light,
    required this.dark,
    required this.seedColor,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'light': _colorSchemeToJson(light),
      'dark': _colorSchemeToJson(dark),
      'seedColor': seedColor.value,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ColorSchemePair fromJson(Map<String, dynamic> json) {
    return ColorSchemePair(
      light: _jsonToColorScheme(json['light'] as String),
      dark: _jsonToColorScheme(json['dark'] as String),
      seedColor: Color(json['seedColor'] as int),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static String _colorSchemeToJson(ColorScheme scheme) {
    final colorMap = {
      'primary': scheme.primary.value,
      'onPrimary': scheme.onPrimary.value,
      'primaryContainer': scheme.primaryContainer.value,
      'onPrimaryContainer': scheme.onPrimaryContainer.value,
      'secondary': scheme.secondary.value,
      'onSecondary': scheme.onSecondary.value,
      'secondaryContainer': scheme.secondaryContainer.value,
      'onSecondaryContainer': scheme.onSecondaryContainer.value,
      'tertiary': scheme.tertiary.value,
      'onTertiary': scheme.onTertiary.value,
      'tertiaryContainer': scheme.tertiaryContainer.value,
      'onTertiaryContainer': scheme.onTertiaryContainer.value,
      'error': scheme.error.value,
      'onError': scheme.onError.value,
      'errorContainer': scheme.errorContainer.value,
      'onErrorContainer': scheme.onErrorContainer.value,
      'surface': scheme.surface.value,
      'onSurface': scheme.onSurface.value,
      'surfaceContainerHighest': scheme.surfaceContainerHighest.value,
      'onSurfaceVariant': scheme.onSurfaceVariant.value,
      'outline': scheme.outline.value,
      'outlineVariant': scheme.outlineVariant.value,
      'shadow': scheme.shadow.value,
      'scrim': scheme.scrim.value,
      'inverseSurface': scheme.inverseSurface.value,
      'onInverseSurface': scheme.onInverseSurface.value,
      'inversePrimary': scheme.inversePrimary.value,
      'brightness': scheme.brightness.index,
    };
    return jsonEncode(colorMap);
  }

  static ColorScheme _jsonToColorScheme(String json) {
    final colorMap = jsonDecode(json) as Map<String, dynamic>;
    final brightness = Brightness.values[colorMap['brightness'] as int];

    return ColorScheme(
      primary: Color(colorMap['primary'] as int),
      onPrimary: Color(colorMap['onPrimary'] as int),
      primaryContainer: Color(colorMap['primaryContainer'] as int),
      onPrimaryContainer: Color(colorMap['onPrimaryContainer'] as int),
      secondary: Color(colorMap['secondary'] as int),
      onSecondary: Color(colorMap['onSecondary'] as int),
      secondaryContainer: Color(colorMap['secondaryContainer'] as int),
      onSecondaryContainer: Color(colorMap['onSecondaryContainer'] as int),
      tertiary: Color(colorMap['tertiary'] as int),
      onTertiary: Color(colorMap['onTertiary'] as int),
      tertiaryContainer: Color(colorMap['tertiaryContainer'] as int),
      onTertiaryContainer: Color(colorMap['onTertiaryContainer'] as int),
      error: Color(colorMap['error'] as int),
      onError: Color(colorMap['onError'] as int),
      errorContainer: Color(colorMap['errorContainer'] as int),
      onErrorContainer: Color(colorMap['onErrorContainer'] as int),
      surface: Color(colorMap['surface'] as int),
      onSurface: Color(colorMap['onSurface'] as int),
      surfaceContainerHighest: Color(colorMap['surfaceContainerHighest'] as int),
      onSurfaceVariant: Color(colorMap['onSurfaceVariant'] as int),
      outline: Color(colorMap['outline'] as int),
      outlineVariant: Color(colorMap['outlineVariant'] as int),
      shadow: Color(colorMap['shadow'] as int),
      scrim: Color(colorMap['scrim'] as int),
      inverseSurface: Color(colorMap['inverseSurface'] as int),
      onInverseSurface: Color(colorMap['onInverseSurface'] as int),
      inversePrimary: Color(colorMap['inversePrimary'] as int),
      brightness: brightness,
    );
  }
}

class EnhancedColorManagerService extends ChangeNotifier {
  static final EnhancedColorManagerService _instance =
      EnhancedColorManagerService._internal();
  factory EnhancedColorManagerService() => _instance;

  EnhancedColorManagerService._internal() {
    _restoreColorSchemes();
  }

  ColorSchemePair? _currentColorPair;
  final Map<String, ColorSchemePair> _cache = {};
  final List<void Function(ColorSchemePair)> _colorListeners = [];

  ColorSchemePair? get currentColorPair => _currentColorPair;

  ColorScheme get lightScheme =>
      _currentColorPair?.light ?? _getDefaultColorScheme(Brightness.light);

  ColorScheme get darkScheme =>
      _currentColorPair?.dark ?? _getDefaultColorScheme(Brightness.dark);

  Color get currentSeedColor =>
      _currentColorPair?.seedColor ?? Colors.blue;

  bool get hasCachedScheme => _currentColorPair != null;

  Future<void> updateColorFromCover({
    required String coverArtId,
    required String coverArtUrl,
  }) async {
    print('🎨 开始从专辑封面提取颜色...');
    print('   Cover ID: $coverArtId');
    print('   Cover URL: $coverArtUrl');

    if (_cache.containsKey(coverArtId)) {
      print('✅ 使用缓存的颜色方案');
      _setColorPair(_cache[coverArtId]!);
      return;
    }

    try {
      final lightResult = await EnhancedColorExtractorService.extractFromImage(
        imageUrl: coverArtUrl,
        brightness: Brightness.light,
      );

      final darkResult = await EnhancedColorExtractorService.extractFromImage(
        imageUrl: coverArtUrl,
        brightness: Brightness.dark,
      );

      final colorPair = ColorSchemePair(
        light: lightResult.colorScheme,
        dark: darkResult.colorScheme,
        seedColor: lightResult.seedColor,
        updatedAt: DateTime.now(),
      );

      _cache[coverArtId] = colorPair;
      await _saveColorScheme(coverArtId, colorPair);

      _setColorPair(colorPair);

      print('✅ 颜色方案更新成功');
      print('   种子颜色: ${colorPair.seedColor}');
    } catch (e) {
      print('❌ 颜色提取失败: $e');
      print('   使用默认颜色方案');

      final defaultPair = _getDefaultColorSchemePair();
      _setColorPair(defaultPair);
    }
  }

  void _setColorPair(ColorSchemePair pair) {
    if (_colorSchemesAreEqual(_currentColorPair, pair)) {
      print('⏭️ 颜色方案未变化，跳过更新');
      return;
    }

    _currentColorPair = pair;
    notifyListeners();
    _notifyColorListeners(pair);
  }

  bool _colorSchemesAreEqual(ColorSchemePair? a, ColorSchemePair? b) {
    if (a == null || b == null) return a == b;

    return a.light.primary == b.light.primary &&
        a.dark.primary == b.dark.primary &&
        a.seedColor == b.seedColor;
  }

  ColorScheme getCurrentColorScheme(Brightness brightness) {
    if (_currentColorPair == null) {
      return _getDefaultColorScheme(brightness);
    }

    return brightness == Brightness.light
        ? _currentColorPair!.light
        : _currentColorPair!.dark;
  }

  ColorSchemePair _getDefaultColorSchemePair() {
    return ColorSchemePair(
      light: _getDefaultColorScheme(Brightness.light),
      dark: _getDefaultColorScheme(Brightness.dark),
      seedColor: Colors.blue,
      updatedAt: DateTime.now(),
    );
  }

  ColorScheme _getDefaultColorScheme(Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: brightness,
    );
  }

  Future<void> _saveColorScheme(
    String coverArtId,
    ColorSchemePair pair,
  ) async {
    try {
      final json = pair.toJson();
      final playbackService = PlaybackStateService();
      await playbackService.saveColorScheme(
        jsonEncode(json),
        false,
      );
      await playbackService.saveColorScheme(
        jsonEncode(json),
        true,
      );
      print('💾 颜色方案已保存到本地存储');
    } catch (e) {
      print('❌ 保存颜色方案失败: $e');
    }
  }

  Future<void> _restoreColorSchemes() async {
    try {
      final playbackService = PlaybackStateService();
      final lightJson = await playbackService.getColorScheme(false);
      final darkJson = await playbackService.getColorScheme(true);

      if (lightJson != null && darkJson != null) {
        final lightMap = jsonDecode(lightJson) as Map<String, dynamic>;
        final darkMap = jsonDecode(darkJson) as Map<String, dynamic>;

        if (lightMap['seedColor'] == darkMap['seedColor']) {
          final pair = ColorSchemePair(
            light: ColorSchemePair._jsonToColorScheme(lightJson),
            dark: ColorSchemePair._jsonToColorScheme(darkJson),
            seedColor: Color(lightMap['seedColor'] as int),
            updatedAt: DateTime.now(),
          );

          _currentColorPair = pair;
          print('✅ 已恢复保存的颜色方案');
        }
      }
    } catch (e) {
      print('❌ 恢复颜色方案失败: $e');
    }
  }

  void clearCurrentColorScheme() {
    _currentColorPair = null;
    notifyListeners();
    _notifyColorListeners(_getDefaultColorSchemePair());
  }

  void clearCache() {
    _cache.clear();
    print('🗑️ 已清除颜色缓存');
  }

  void addColorListener(void Function(ColorSchemePair) listener) {
    _colorListeners.add(listener);
  }

  void removeColorListener(void Function(ColorSchemePair) listener) {
    _colorListeners.remove(listener);
  }

  void _notifyColorListeners(ColorSchemePair pair) {
    for (final listener in _colorListeners) {
      try {
        listener(pair);
      } catch (e) {
        print('❌ 监听器执行失败: $e');
      }
    }
  }

  Future<void> preloadColorScheme({
    required String coverArtId,
    required String coverArtUrl,
  }) async {
    if (_cache.containsKey(coverArtId)) {
      return;
    }

    try {
      final lightResult = await EnhancedColorExtractorService.extractFromImage(
        imageUrl: coverArtUrl,
        brightness: Brightness.light,
      );

      final darkResult = await EnhancedColorExtractorService.extractFromImage(
        imageUrl: coverArtUrl,
        brightness: Brightness.dark,
      );

      final colorPair = ColorSchemePair(
        light: lightResult.colorScheme,
        dark: darkResult.colorScheme,
        seedColor: lightResult.seedColor,
        updatedAt: DateTime.now(),
      );

      _cache[coverArtId] = colorPair;
      print('✅ 预加载颜色方案成功: $coverArtId');
    } catch (e) {
      print('⚠️ 预加载颜色方案失败: $e');
    }
  }

  Color getTonalSurface(Brightness brightness) {
    final scheme = getCurrentColorScheme(brightness);
    final opacity = brightness == Brightness.light ? 0.06 : 0.11;
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: opacity),
      scheme.surface,
    );
  }
}

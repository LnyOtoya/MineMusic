import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';
import 'playback_state_service.dart';

class ColorManagerService {
  static final ColorManagerService _instance = ColorManagerService._private();
  factory ColorManagerService() => _instance;

  ColorManagerService._private() {
    _restoreColorSchemes();
  }

  // 当前颜色方案（分别存储浅色和深色模式）
  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;

  // 颜色变化监听器
  final List<Function(ColorScheme)> _listeners = [];

  // 比较两个颜色方案是否相同
  bool _colorSchemesAreEqual(ColorScheme? a, ColorScheme? b) {
    if (a == null || b == null) return a == b;
    
    return a.primary == b.primary &&
           a.onPrimary == b.onPrimary &&
           a.primaryContainer == b.primaryContainer &&
           a.onPrimaryContainer == b.onPrimaryContainer &&
           a.secondary == b.secondary &&
           a.onSecondary == b.onSecondary &&
           a.secondaryContainer == b.secondaryContainer &&
           a.onSecondaryContainer == b.onSecondaryContainer &&
           a.surface == b.surface &&
           a.onSurface == b.onSurface &&
           a.surfaceVariant == b.surfaceVariant &&
           a.onSurfaceVariant == b.onSurfaceVariant &&
           a.brightness == b.brightness;
  }

  // 从专辑封面提取颜色方案
  Future<ColorScheme> extractColorSchemeFromCover(
    String coverArtId,
    String coverArtUrl,
    Brightness brightness,
  ) async {
    try {
      // 使用 ColorScheme.fromImageProvider 从专辑封面提取颜色
      final imageProvider = NetworkImage(coverArtUrl);

      // 根据亮度模式设置不同的提取参数
      final colorScheme = await ColorScheme.fromImageProvider(
        provider: imageProvider,
        brightness: brightness,
      );

      // 生成包含 tonal surface 的新颜色方案
      final tonalColorScheme = _createTonalColorScheme(colorScheme, brightness);

      // 检查颜色方案是否真正变化
      bool hasChanged = false;
      if (brightness == Brightness.light) {
        hasChanged = !_colorSchemesAreEqual(_lightColorScheme, tonalColorScheme);
        _lightColorScheme = tonalColorScheme;
      } else {
        hasChanged = !_colorSchemesAreEqual(_darkColorScheme, tonalColorScheme);
        _darkColorScheme = tonalColorScheme;
      }

      // 保存颜色方案到本地存储
      await _saveColorScheme(tonalColorScheme, brightness);

      // 只有当颜色方案真正变化时才通知监听器
      if (hasChanged) {
        _notifyListeners(tonalColorScheme);
      }

      return tonalColorScheme;
    } catch (e) {
      // 如果提取失败，使用默认颜色方案
      final defaultColorScheme = _createDefaultColorScheme(brightness);

      // 检查颜色方案是否真正变化
      bool hasChanged = false;
      if (brightness == Brightness.light) {
        hasChanged = !_colorSchemesAreEqual(_lightColorScheme, defaultColorScheme);
        _lightColorScheme = defaultColorScheme;
      } else {
        hasChanged = !_colorSchemesAreEqual(_darkColorScheme, defaultColorScheme);
        _darkColorScheme = defaultColorScheme;
      }

      // 只有当颜色方案真正变化时才通知监听器
      if (hasChanged) {
        _notifyListeners(defaultColorScheme);
      }
      return defaultColorScheme;
    }
  }

  // 保存颜色方案到本地存储
  Future<void> _saveColorScheme(
    ColorScheme colorScheme,
    Brightness brightness,
  ) async {
    try {
      final colorSchemeJson = _colorSchemeToJson(colorScheme);
      final isDark = brightness == Brightness.dark;
      await PlaybackStateService().saveColorScheme(colorSchemeJson, isDark);
    } catch (e) {
      print('保存颜色方案失败: $e');
    }
  }

  // 从本地存储恢复颜色方案
  Future<void> _restoreColorSchemes() async {
    try {
      final lightColorSchemeJson = await PlaybackStateService().getColorScheme(
        false,
      );
      final darkColorSchemeJson = await PlaybackStateService().getColorScheme(
        true,
      );

      if (lightColorSchemeJson != null) {
        _lightColorScheme = _jsonToColorScheme(lightColorSchemeJson);
      }
      if (darkColorSchemeJson != null) {
        _darkColorScheme = _jsonToColorScheme(darkColorSchemeJson);
      }
    } catch (e) {
      print('恢复颜色方案失败: $e');
    }
  }

  // 将 ColorScheme 转换为 JSON
  String _colorSchemeToJson(ColorScheme colorScheme) {
    final colorMap = {
      'primary': colorScheme.primary.value,
      'onPrimary': colorScheme.onPrimary.value,
      'primaryContainer': colorScheme.primaryContainer.value,
      'onPrimaryContainer': colorScheme.onPrimaryContainer.value,
      'secondary': colorScheme.secondary.value,
      'onSecondary': colorScheme.onSecondary.value,
      'secondaryContainer': colorScheme.secondaryContainer.value,
      'onSecondaryContainer': colorScheme.onSecondaryContainer.value,
      'tertiary': colorScheme.tertiary.value,
      'onTertiary': colorScheme.onTertiary.value,
      'tertiaryContainer': colorScheme.tertiaryContainer.value,
      'onTertiaryContainer': colorScheme.onTertiaryContainer.value,
      'error': colorScheme.error.value,
      'onError': colorScheme.onError.value,
      'errorContainer': colorScheme.errorContainer.value,
      'onErrorContainer': colorScheme.onErrorContainer.value,
      'background': colorScheme.surface.value,
      'onBackground': colorScheme.onSurface.value,
      'surface': colorScheme.surface.value,
      'onSurface': colorScheme.onSurface.value,
      'surfaceVariant': colorScheme.surfaceContainerHighest.value,
      'onSurfaceVariant': colorScheme.onSurfaceVariant.value,
      'outline': colorScheme.outline.value,
      'outlineVariant': colorScheme.outlineVariant.value,
      'shadow': colorScheme.shadow.value,
      'scrim': colorScheme.scrim.value,
      'inverseSurface': colorScheme.inverseSurface.value,
      'onInverseSurface': colorScheme.onInverseSurface.value,
      'inversePrimary': colorScheme.inversePrimary.value,
      'brightness': colorScheme.brightness.index,
    };
    return jsonEncode(colorMap);
  }

  // 从 JSON 恢复 ColorScheme
  ColorScheme _jsonToColorScheme(String json) {
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
      surfaceContainerHighest: Color(colorMap['surfaceVariant'] as int),
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

  // 创建包含 tonal surface 的颜色方案
  ColorScheme _createTonalColorScheme(
    ColorScheme original,
    Brightness brightness,
  ) {
    // 根据亮度模式设置不同的不透明度
    final double opacity = brightness == Brightness.light ? 0.06 : 0.11;

    // 生成 tonal surface 背景色
    final Color tonalSurface = Color.alphaBlend(
      original.primary.withValues(alpha: opacity),
      original.surface,
    );

    // 创建新的颜色方案，替换 surface 为 tonal surface
    return original.copyWith(
      surface: tonalSurface,
      // 确保其他颜色也符合 Material 3 规范
      surfaceContainerHighest: original.surfaceContainerHighest,
    );
  }

  // 创建默认颜色方案
  ColorScheme _createDefaultColorScheme(Brightness brightness) {
    final seedColor = Colors.blue; // 默认种子颜色

    final defaultScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return _createTonalColorScheme(defaultScheme, brightness);
  }

  // 获取当前颜色方案
  ColorScheme getCurrentColorScheme(Brightness brightness) {
    // 根据亮度模式返回对应的颜色方案
    if (brightness == Brightness.light) {
      if (_lightColorScheme != null) {
        return _lightColorScheme!;
      }
    } else {
      if (_darkColorScheme != null) {
        return _darkColorScheme!;
      }
    }

    // 如果还没有颜色方案，返回默认方案
    final defaultScheme = _createDefaultColorScheme(brightness);

    if (brightness == Brightness.light) {
      _lightColorScheme = defaultScheme;
    } else {
      _darkColorScheme = defaultScheme;
    }

    return defaultScheme;
  }

  // 添加颜色变化监听器
  void addListener(Function(ColorScheme) listener) {
    _listeners.add(listener);
  }

  // 移除颜色变化监听器
  void removeListener(Function(ColorScheme) listener) {
    _listeners.remove(listener);
  }

  // 通知所有监听器颜色变化
  void _notifyListeners(ColorScheme colorScheme) {
    for (final listener in _listeners) {
      listener(colorScheme);
    }
  }

  // 清空当前颜色方案（切换歌曲时调用）
  void clearCurrentColorScheme() {
    _lightColorScheme = null;
    _darkColorScheme = null;
  }
}

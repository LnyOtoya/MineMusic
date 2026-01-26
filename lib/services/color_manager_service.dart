import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/subsonic_api.dart';

class ColorManagerService {
  static final ColorManagerService _instance = ColorManagerService._private();
  factory ColorManagerService() => _instance;

  ColorManagerService._private();

  // 当前颜色方案（分别存储浅色和深色模式）
  ColorScheme? _lightColorScheme;
  ColorScheme? _darkColorScheme;

  // 颜色变化监听器
  final List<Function(ColorScheme)> _listeners = [];

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

      // 根据亮度模式存储到对应的变量
      if (brightness == Brightness.light) {
        _lightColorScheme = tonalColorScheme;
      } else {
        _darkColorScheme = tonalColorScheme;
      }

      _notifyListeners(tonalColorScheme);

      return tonalColorScheme;
    } catch (e) {
      // 如果提取失败，使用默认颜色方案
      final defaultColorScheme = _createDefaultColorScheme(brightness);

      // 根据亮度模式存储到对应的变量
      if (brightness == Brightness.light) {
        _lightColorScheme = defaultColorScheme;
      } else {
        _darkColorScheme = defaultColorScheme;
      }

      _notifyListeners(defaultColorScheme);
      return defaultColorScheme;
    }
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
      surfaceVariant: original.surfaceVariant,
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
    // 立即通知新监听器当前颜色方案（两个模式都通知）
    if (_lightColorScheme != null) {
      listener(_lightColorScheme!);
    }
    if (_darkColorScheme != null) {
      listener(_darkColorScheme!);
    }
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

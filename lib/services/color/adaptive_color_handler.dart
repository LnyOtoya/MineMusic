import 'dart:math';
import 'package:flutter/material.dart';
import 'color_analyzer.dart';

class AdaptiveColorHandler {
  static Color handleSpecialImageTypes(
    ColorScheme extractedScheme,
    List<Color> dominantColors,
  ) {
    final primaryColor = extractedScheme.primary;

    if (_isMonochromaticImage(dominantColors)) {
      return _handleMonochromaticImage(extractedScheme);
    }

    if (_isNeutralToneImage(dominantColors)) {
      return _handleNeutralToneImage(extractedScheme);
    }

    if (_isHighContrastImage(dominantColors)) {
      return _handleHighContrastImage(extractedScheme);
    }

    return primaryColor;
  }

  static bool _isMonochromaticImage(List<Color> colors) {
    if (colors.length < 2) return true;

    final firstHue = HSLColor.fromColor(colors[0]).hue;
    final hueVariance = colors
        .map((c) => HSLColor.fromColor(c).hue)
        .map((hue) => (hue - firstHue).abs())
        .reduce((a, b) => a + b) /
        colors.length;

    return hueVariance < 15.0;
  }

  static bool _isNeutralToneImage(List<Color> colors) {
    if (colors.isEmpty) return false;

    final neutralCount = colors
        .where((color) => ColorAnalyzer.isNeutralColor(color))
        .length;

    return neutralCount / colors.length > 0.7;
  }

  static bool _isHighContrastImage(List<Color> colors) {
    if (colors.length < 2) return false;

    final lightnesses = colors
        .map((c) => HSLColor.fromColor(c).lightness)
        .toList();

    final minLightness = lightnesses.reduce((a, b) => a < b ? a : b);
    final maxLightness = lightnesses.reduce((a, b) => a > b ? a : b);

    return (maxLightness - minLightness) > 0.6;
  }

  static Color _handleMonochromaticImage(ColorScheme scheme) {
    final primaryHsl = HSLColor.fromColor(scheme.primary);

    final adjustedHue = (primaryHsl.hue + 30) % 360;
    final adjustedSaturation = (primaryHsl.saturation + 0.2).clamp(0.0, 1.0);
    final adjustedLightness = primaryHsl.lightness.clamp(0.3, 0.7);

    return HSLColor.fromAHSL(
      primaryHsl.alpha,
      adjustedHue,
      adjustedSaturation,
      adjustedLightness,
    ).toColor();
  }

  static Color _handleNeutralToneImage(ColorScheme scheme) {
    final primaryHsl = HSLColor.fromColor(scheme.primary);

    if (primaryHsl.saturation < 0.15) {
      final adjustedHue = 210.0;
      final adjustedSaturation = 0.5;
      final adjustedLightness = 0.5;

      return HSLColor.fromAHSL(
        primaryHsl.alpha,
        adjustedHue,
        adjustedSaturation,
        adjustedLightness,
      ).toColor();
    }

    return scheme.primary;
  }

  static Color _handleHighContrastImage(ColorScheme scheme) {
    final primaryHsl = HSLColor.fromColor(scheme.primary);

    final adjustedSaturation = primaryHsl.saturation.clamp(0.3, 0.8);
    final adjustedLightness = primaryHsl.lightness.clamp(0.3, 0.7);

    return HSLColor.fromAHSL(
      primaryHsl.alpha,
      primaryHsl.hue,
      adjustedSaturation,
      adjustedLightness,
    ).toColor();
  }

  static ColorScheme adjustColorSchemeForImageType(
    ColorScheme originalScheme,
    List<Color> dominantColors,
    Brightness brightness,
  ) {
    final adjustedPrimary = handleSpecialImageTypes(
      originalScheme,
      dominantColors,
    );

    final adjustedScheme = originalScheme.copyWith(
      primary: adjustedPrimary,
      primaryContainer: _adjustContainerColor(
        adjustedPrimary,
        originalScheme.primaryContainer,
        brightness,
      ),
      secondary: _adjustSecondaryColor(
        adjustedPrimary,
        originalScheme.secondary,
      ),
      tertiary: _adjustTertiaryColor(
        adjustedPrimary,
        originalScheme.tertiary,
      ),
    );

    return adjustedScheme;
  }

  static Color _adjustContainerColor(
    Color primary,
    Color originalContainer,
    Brightness brightness,
  ) {
    final primaryHsl = HSLColor.fromColor(primary);
    final containerHsl = HSLColor.fromColor(originalContainer);

    final adjustedLightness = brightness == Brightness.light
        ? (primaryHsl.lightness + 0.1).clamp(0.0, 1.0)
        : (primaryHsl.lightness - 0.1).clamp(0.0, 1.0);

    return HSLColor.fromAHSL(
      containerHsl.alpha,
      primaryHsl.hue,
      primaryHsl.saturation * 0.8,
      adjustedLightness,
    ).toColor();
  }

  static Color _adjustSecondaryColor(Color primary, Color originalSecondary) {
    final primaryHsl = HSLColor.fromColor(primary);
    final secondaryHsl = HSLColor.fromColor(originalSecondary);

    final adjustedHue = (primaryHsl.hue + 180) % 360;

    return HSLColor.fromAHSL(
      secondaryHsl.alpha,
      adjustedHue,
      primaryHsl.saturation * 0.6,
      primaryHsl.lightness,
    ).toColor();
  }

  static Color _adjustTertiaryColor(Color primary, Color originalTertiary) {
    final primaryHsl = HSLColor.fromColor(primary);
    final tertiaryHsl = HSLColor.fromColor(originalTertiary);

    final adjustedHue = (primaryHsl.hue + 120) % 360;

    return HSLColor.fromAHSL(
      tertiaryHsl.alpha,
      adjustedHue,
      primaryHsl.saturation * 0.7,
      primaryHsl.lightness,
    ).toColor();
  }

  static ColorScheme ensureAccessibilityContrast(ColorScheme scheme) {
    final primaryContrast = _calculateContrastRatio(
      scheme.primary,
      scheme.onPrimary,
    );

    final surfaceContrast = _calculateContrastRatio(
      scheme.surface,
      scheme.onSurface,
    );

    if (primaryContrast < 4.5) {
      final adjustedOnPrimary = _adjustTextColorForContrast(
        scheme.primary,
        scheme.onPrimary,
      );
      scheme = scheme.copyWith(onPrimary: adjustedOnPrimary);
    }

    if (surfaceContrast < 4.5) {
      final adjustedOnSurface = _adjustTextColorForContrast(
        scheme.surface,
        scheme.onSurface,
      );
      scheme = scheme.copyWith(onSurface: adjustedOnSurface);
    }

    return scheme;
  }

  static double _calculateContrastRatio(Color foreground, Color background) {
    final fgLuminance = _calculateLuminance(foreground);
    final bgLuminance = _calculateLuminance(background);

    final lighter = max(fgLuminance, bgLuminance);
    final darker = min(fgLuminance, bgLuminance);

    return (lighter + 0.05) / (darker + 0.05);
  }

  static double _calculateLuminance(Color color) {
    final r = _linearizeColorComponent(color.red / 255.0);
    final g = _linearizeColorComponent(color.green / 255.0);
    final b = _linearizeColorComponent(color.blue / 255.0);

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double _linearizeColorComponent(double component) {
    if (component <= 0.03928) {
      return component / 12.92;
    } else {
      return pow((component + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  static Color _adjustTextColorForContrast(Color background, Color text) {
    final bgHsl = HSLColor.fromColor(background);
    final textHsl = HSLColor.fromColor(text);

    final adjustedLightness = bgHsl.lightness > 0.5
        ? textHsl.lightness.clamp(0.0, 0.3)
        : textHsl.lightness.clamp(0.7, 1.0);

    return HSLColor.fromAHSL(
      textHsl.alpha,
      textHsl.hue,
      textHsl.saturation,
      adjustedLightness,
    ).toColor();
  }
}

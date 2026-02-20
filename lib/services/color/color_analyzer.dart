import 'dart:math';
import 'package:flutter/material.dart';

class ColorScore {
  final double saturation;
  final double brightness;
  final double prominence;
  final double totalScore;

  const ColorScore({
    required this.saturation,
    required this.brightness,
    required this.prominence,
    required this.totalScore,
  });

  @override
  String toString() =>
      'ColorScore(saturation: ${saturation.toStringAsFixed(2)}, '
      'brightness: ${brightness.toStringAsFixed(2)}, '
      'prominence: ${prominence.toStringAsFixed(2)}, '
      'total: ${totalScore.toStringAsFixed(2)})';
}

class ColorAnalyzer {
  static const double _optimalSaturation = 0.6;
  static const double _optimalBrightness = 0.5;
  static const double _saturationWeight = 0.4;
  static const double _brightnessWeight = 0.3;
  static const double _prominenceWeight = 0.3;

  static ColorScore analyzeColor(Color color, int frequency) {
    final hsl = HSLColor.fromColor(color);

    final saturation = hsl.saturation;
    final brightness = hsl.lightness;

    final saturationScore = _calculateSaturationScore(saturation);
    final brightnessScore = _calculateBrightnessScore(brightness);
    final prominenceScore = _calculateProminenceScore(frequency);

    final totalScore = saturationScore * _saturationWeight +
        brightnessScore * _brightnessWeight +
        prominenceScore * _prominenceWeight;

    return ColorScore(
      saturation: saturationScore,
      brightness: brightnessScore,
      prominence: prominenceScore,
      totalScore: totalScore,
    );
  }

  static double _calculateSaturationScore(double saturation) {
    final distance = (saturation - _optimalSaturation).abs();
    return max(0.0, 1.0 - distance);
  }

  static double _calculateBrightnessScore(double brightness) {
    final distance = (brightness - _optimalBrightness).abs();
    return max(0.0, 1.0 - distance * 1.5);
  }

  static double _calculateProminenceScore(int frequency) {
    if (frequency <= 0) return 0.0;
    return min(1.0, frequency / 100.0);
  }

  static bool isNeutralColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.saturation < 0.15;
  }

  static bool isTooBright(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness > 0.85;
  }

  static bool isTooDark(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.lightness < 0.15;
  }

  static bool isGoodSeedColor(Color color) {
    if (isNeutralColor(color)) return false;
    if (isTooBright(color)) return false;
    if (isTooDark(color)) return false;
    return true;
  }

  static Color findBestSeedColor(
    List<Color> colors,
    Map<Color, int> frequencyMap,
  ) {
    if (colors.isEmpty) {
      return Colors.blue;
    }

    Color? bestColor;
    double bestScore = -1.0;

    for (final color in colors) {
      if (!isGoodSeedColor(color)) continue;

      final frequency = frequencyMap[color] ?? 0;
      final score = analyzeColor(color, frequency);

      if (score.totalScore > bestScore) {
        bestScore = score.totalScore;
        bestColor = color;
      }
    }

    if (bestColor != null) {
      return bestColor;
    }

    for (final color in colors) {
      final frequency = frequencyMap[color] ?? 0;
      final score = analyzeColor(color, frequency);

      if (score.totalScore > bestScore) {
        bestScore = score.totalScore;
        bestColor = color;
      }
    }

    return bestColor ?? colors.first;
  }

  static List<Color> extractDominantColors(ColorScheme colorScheme) {
    final colors = <Color>[];

    colors.add(colorScheme.primary);
    colors.add(colorScheme.secondary);
    colors.add(colorScheme.tertiary);
    colors.add(colorScheme.primaryContainer);
    colors.add(colorScheme.secondaryContainer);
    colors.add(colorScheme.tertiaryContainer);

    return colors;
  }
}

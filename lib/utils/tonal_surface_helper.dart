import 'package:flutter/material.dart';

class TonalSurfaceHelper {
  static Color getTonalSurface(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return _blendPrimaryWithSurface(colorScheme.primary, colorScheme.surface);
  }

  static Color getTonalSurfaceFromColors(Color primary, Color surface) {
    return _blendPrimaryWithSurface(primary, surface);
  }

  static Color _blendPrimaryWithSurface(Color primary, Color surface) {
    return Color.alphaBlend(
      primary.withValues(alpha: 0.06),
      surface,
    );
  }
}

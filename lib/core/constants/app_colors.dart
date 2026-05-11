import 'package:flutter/material.dart';

class AppColors {
  // Default Premium Palette
  static const Color charcoal = Color(0xFF2D2D2D);
  static const Color brushedGold = Color(0xFFD4AF37);
  static const Color brushedGoldLight = Color(0xFFE8CB5A);
  static const Color brushedGoldDark = Color(0xFFB8931F);

  // Neutral Palette
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surfaceVariant = Color(0xFF252525);
  static const Color surfaceCard = Color(0xFF303030);
  static const Color onSurface = Color(0xFFF5F5F5);
  static const Color onSurfaceMuted = Color(0xFF9E9E9E);

  // Status Colors
  static const Color confirmed = Color(0xFF4CAF50);
  static const Color pending = Color(0xFFFF9800);
  static const Color declined = Color(0xFFF44336);

  // Role Colors
  static const Color padrino = Color(0xFFD4AF37);
  static const Color vip = Color(0xFF9C27B0);
  static const Color regular = Color(0xFF2196F3);

  // Gradient
  static const LinearGradient goldGradient = LinearGradient(
    colors: [brushedGoldDark, brushedGold, brushedGoldLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF2D2D2D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

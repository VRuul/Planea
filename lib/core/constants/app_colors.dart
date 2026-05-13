import 'package:flutter/material.dart';

class AppColors {
  // Champagne Gold Premium Palette (Refined)
  static const Color charcoal = Color(0xFF1E1E1E); // Un poco más profundo
  static const Color brushedGold = Color(0xFFDBC18D); // Champagne Gold Base
  static const Color brushedGoldLight = Color(0xFFF1E4C3); // Champagne Light
  static const Color brushedGoldDark = Color(0xFFB5965E); // Champagne Dark

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
  static const Color padrino = brushedGold;
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

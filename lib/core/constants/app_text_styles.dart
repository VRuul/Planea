import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.outfit(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
  );

  static TextStyle get displayMedium => GoogleFonts.outfit(
    fontSize: 45,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineLarge => GoogleFonts.outfit(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get headlineMedium => GoogleFonts.outfit(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get headlineSmall => GoogleFonts.outfit(
    fontSize: 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get titleLarge => GoogleFonts.outfit(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
  );

  static TextStyle get titleMedium => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );

  static TextStyle get titleSmall => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
  );

  static TextStyle get bodyLarge => GoogleFonts.outfit(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
  );

  static TextStyle get bodyMedium => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
  );

  static TextStyle get bodySmall => GoogleFonts.outfit(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
  );

  static TextStyle get labelLarge => GoogleFonts.outfit(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle get labelSmall => GoogleFonts.outfit(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../data/services/supabase_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const _themePrefKey = 'theme_mode';
  final _service = SupabaseService();
  
  Color _primaryColor = AppColors.charcoal;
  Color _secondaryColor = AppColors.brushedGold;
  ThemeMode _themeMode = ThemeMode.dark;
  String? _userId;

  Color get primaryColor => _primaryColor;
  Color get secondaryColor => _secondaryColor;
  ThemeMode get themeMode => _themeMode;

  /// Actualiza el userId y sincroniza con la base de datos si es necesario
  void updateUserId(String? id) {
    if (_userId == id) return;
    _userId = id;
    if (_userId != null) {
      _syncWithDatabase();
    }
  }

  Future<void> _syncWithDatabase() async {
    if (_userId == null) return;
    final profile = await _service.getProfile(_userId!);
    if (profile != null && profile['theme_mode'] != null) {
      final modeStr = profile['theme_mode'] as String;
      final mode = ThemeMode.values.firstWhere((e) => e.name == modeStr, orElse: () => ThemeMode.dark);
      if (mode != _themeMode) {
        _themeMode = mode;
        notifyListeners();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_themePrefKey, _themeMode.index);
      }
    }
  }

  /// Carga el modo de tema guardado al iniciar la app
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themePrefKey);
    if (themeIndex != null) {
      _themeMode = ThemeMode.values[themeIndex];
      notifyListeners();
    }
  }

  void setPrimaryColor(Color color) {
    _primaryColor = color;
    notifyListeners();
  }

  void setSecondaryColor(Color color) {
    _secondaryColor = color;
    notifyListeners();
  }

  Future<void> toggleThemeMode() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themePrefKey, _themeMode.index);

    if (_userId != null) {
      await _service.updateProfile(_userId!, {'theme_mode': _themeMode.name});
    }
  }

  void applyEventColors(Color primary, Color secondary) {
    _primaryColor = primary;
    _secondaryColor = secondary;
    notifyListeners();
  }

  ThemeData buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _secondaryColor,
      primary: _secondaryColor,
      secondary: _primaryColor,
      brightness: brightness,
      surface: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF8F5EC),
      onPrimary: isDark ? AppColors.charcoal : Colors.white,
      onSecondary: isDark ? Colors.white : AppColors.charcoal,
    );

    final baseTextTheme = GoogleFonts.outfitTextTheme(
      isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      textTheme: baseTextTheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF141414) : const Color(0xFFF5F0E8),

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFFDF8F0),
        foregroundColor: isDark ? Colors.white : AppColors.charcoal,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.white : AppColors.charcoal,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? const Color(0xFF232323) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        shadowColor: _secondaryColor.withValues(alpha: 0.15),
      ),

      // NavigationRail
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFFDF8F0),
        selectedIconTheme: IconThemeData(color: _secondaryColor),
        unselectedIconTheme: IconThemeData(
          color: isDark ? Colors.white54 : Colors.black38,
        ),
        selectedLabelTextStyle: GoogleFonts.outfit(
          color: _secondaryColor,
          fontWeight: FontWeight.w600,
        ),
        indicatorColor: _secondaryColor.withValues(alpha: 0.15),
        useIndicator: true,
      ),

      // NavigationBar (mobile)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFFDF8F0),
        indicatorColor: _secondaryColor.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: _secondaryColor);
          }
          return IconThemeData(
            color: isDark ? Colors.white54 : Colors.black38,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.outfit(
              color: _secondaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return GoogleFonts.outfit(fontSize: 12);
        }),
      ),

      // ElevatedButton
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: AppColors.charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),

      // FilledButton
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _secondaryColor,
          foregroundColor: AppColors.charcoal,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w600),
        ),
      ),

      // InputDecoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _secondaryColor, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),

      // Chip
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedColor: _secondaryColor.withValues(alpha: 0.2),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.08),
        thickness: 1,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';

  Locale? _locale; // null = system/auto

  Locale? get locale => _locale;

  /// Call once at startup
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString(_prefKey);
    if (tag != null && tag != 'auto') {
      _locale = Locale(tag);
    }
    // null stays null → system locale
    notifyListeners();
  }

  Future<void> setLocale(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    if (languageCode == null || languageCode == 'auto') {
      await prefs.setString(_prefKey, 'auto');
      _locale = null;
    } else {
      await prefs.setString(_prefKey, languageCode);
      _locale = Locale(languageCode);
    }
    notifyListeners();
  }

  /// Returns 'auto', 'en', or 'es'
  String get currentCode {
    if (_locale == null) return 'auto';
    return _locale!.languageCode;
  }
}

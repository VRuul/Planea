import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/supabase_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefKey = 'app_locale';
  final _service = SupabaseService();

  Locale? _locale; // null = system/auto
  String? _userId;

  Locale? get locale => _locale;

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
    if (profile != null && profile['language_code'] != null) {
      final code = profile['language_code'] as String;
      if (code != currentCode) {
        if (code == 'auto') {
          _locale = null;
        } else {
          _locale = Locale(code);
        }
        notifyListeners();
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, code);
      }
    }
  }

  /// Call once at startup
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final tag = prefs.getString(_prefKey);
    if (tag != null && tag != 'auto') {
      _locale = Locale(tag);
    }
    notifyListeners();
  }

  Future<void> setLocale(String? languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final code = languageCode ?? 'auto';
    
    await prefs.setString(_prefKey, code);
    if (code == 'auto') {
      _locale = null;
    } else {
      _locale = Locale(code);
    }
    notifyListeners();

    if (_userId != null) {
      await _service.updateProfile(_userId!, {'language_code': code});
    }
  }

  /// Returns 'auto', 'en', or 'es'
  String get currentCode {
    if (_locale == null) return 'auto';
    return _locale!.languageCode;
  }
}

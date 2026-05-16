import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      // Nota: Supabase maneja Google Auth de forma diferente.
      // En móvil se suele usar signInWithOAuth, en Web también.
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      // El resultado real se maneja vía deep link o cambio de estado
      notifyListeners();
      return null; 
    } catch (e) {
      throw 'Error al iniciar sesión con Google: $e';
    }
  }

  Future<AuthResponse?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<AuthResponse?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } on AuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    notifyListeners();
  }

  String _mapAuthException(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (message.contains('user already exists')) {
      return 'Este correo ya está en uso.';
    }
    if (message.contains('email not confirmed')) {
      return 'Por favor confirma tu correo electrónico.';
    }
    return e.message;
  }
}

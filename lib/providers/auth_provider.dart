import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  AuthProvider() {
    _supabase.auth.onAuthStateChange.listen((data) {
      notifyListeners();
    });
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  String? get userDisplayName =>
      currentUser?.userMetadata?['display_name'] ??
      currentUser?.userMetadata?['full_name'];
  String? get userPhotoUrl =>
      currentUser?.userMetadata?['avatar_url'] ??
      currentUser?.userMetadata?['picture'];

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // En Web usamos el flujo de OAuth estándar
        await _supabase.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
        );
        return null;
      } else {
        // En Móvil usamos Google Sign-In nativo para una experiencia premium
        // TODO: Configura tus Client IDs en Google Cloud Console
        // Para Android, usa el "Web Client ID"
        // Para iOS, usa el "iOS Client ID"
        const webClientId =
            '316773108743-h6l0vsq2rpumu5g077vers24g2p7q9vv.apps.googleusercontent.com';
        const iosClientId = 'TU_IOS_CLIENT_ID.apps.googleusercontent.com';

        final GoogleSignIn googleSignIn = GoogleSignIn(
          clientId: iosClientId,
          serverClientId: webClientId,
        );

        final googleUser = await googleSignIn.signIn();
        if (googleUser == null) return null;

        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          throw 'No se pudo obtener el ID Token de Google.';
        }

        final response = await _supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        notifyListeners();
        return response;
      }
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

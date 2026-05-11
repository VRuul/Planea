import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  String _mapAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No se encontró una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'email-already-in-use':
        return 'Este correo ya está en uso.';
      case 'invalid-email':
        return 'Correo electrónico inválido.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      default:
        return e.message ?? 'Error de autenticación.';
    }
  }
}

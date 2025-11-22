import 'dart:async';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class IAuthRepository {
  Future<String> login({required String email, required String password});
  Future<void> logout();
  Future<bool> hasValidSession();
}

class FakeAuthRepository implements IAuthRepository {
  String? _token;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw AuthFailure('Email ou mot de passe vide');
    }
    // Stub: accepter tout et générer un token factice
    _token = 'fake-token-for:$email';
    return _token!;
  }

  @override
  Future<void> logout() async {
    _token = null;
  }

  @override
  Future<bool> hasValidSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Forcer la déconnexion au démarrage pour le développement
    return false;
  }
}

// Removed factory/import to avoid circular imports and directive order issues.

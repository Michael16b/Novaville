import 'dart:async';
import 'package:frontend/constants/texts.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class IAuthRepository {
  Future<String> login({required String username, required String password});
  Future<void> logout();
  Future<bool> hasValidSession();
}

class FakeAuthRepository implements IAuthRepository {
  String? _token;

  @override
  Future<String> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (username.isEmpty || password.isEmpty) {
      throw AuthFailure(AppTexts.emptyUsernameOrPassword);
    }
    // Stub: accepter tout et générer un token factice
    _token = 'fake-token-for:$username';
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

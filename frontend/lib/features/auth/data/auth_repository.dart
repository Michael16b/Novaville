import 'dart:async';
import 'package:frontend/constants/texts.dart';

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

  // Récupérer l'access token stocké (ou null)
  Future<String?> getAccessToken();

  // Tenter de rafraîchir l'access token à partir du refresh token.
  // Retourne true si un nouveau access token est obtenu et stocké.
  Future<bool> tryRefresh();
}

class FakeAuthRepository implements IAuthRepository {
  String? _token;
  String? _refresh;

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (email.isEmpty || password.isEmpty) {
      throw AuthFailure(AppTexts.emptyEmailOrPassword);
    }
    // Stub: accepter tout et générer un token factice
    _token = 'fake-token-for:$email';
    _refresh = 'fake-refresh-for:$email';
    return _token!;
  }

  @override
  Future<void> logout() async {
    _token = null;
    _refresh = null;
  }

  @override
  Future<bool> hasValidSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _token != null;
  }

  @override
  Future<String?> getAccessToken() async => _token;

  @override
  Future<bool> tryRefresh() async {
    if (_refresh == null) return false;
    // simulate refresh
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _token = 'refreshed-fake-token';
    return true;
  }
}

// Removed factory/import to avoid circular imports and directive order issues.

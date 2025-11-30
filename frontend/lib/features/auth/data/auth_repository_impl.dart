import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';

/// Petit wrapper d'abstraction pour éviter un import direct de packages
/// de plateforme dans ce fichier. Fournir une implémentation basée sur
/// `FlutterSecureStorage` dans `auth_storage_impl.dart`.
abstract class TokenStorage {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// Implémentation en mémoire (fallback / tests)
class InMemoryTokenStorage implements TokenStorage {
  final Map<String, String?> _map = {};

  @override
  Future<void> write({required String key, required String? value}) async {
    _map[key] = value;
  }

  @override
  Future<String?> read({required String key}) async => _map[key];

  @override
  Future<void> delete({required String key}) async {
    _map.remove(key);
  }
}

class AuthRepositoryImpl implements IAuthRepository {
  AuthRepositoryImpl({required AuthApi api, TokenStorage? storage})
    : _api = api,
      _storage = storage ?? InMemoryTokenStorage();
  final AuthApi _api;
  final TokenStorage _storage;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.login(email: email, password: password);
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access == null || refresh == null) {
        throw AuthFailure(AppTexts.serverInvalidResponse);
      }

      await _storage.write(key: _keyAccess, value: access);
      await _storage.write(key: _keyRefresh, value: refresh);

      return access;
    } catch (e) {
      debugPrint('AuthRepositoryImpl.login error: $e');
      if (e is AuthFailure) rethrow;
      // Convertir d'autres exceptions en AuthFailure pour message clair
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }

  @override
  Future<bool> hasValidSession() async {
    final access = await _storage.read(key: _keyAccess);
    if (access != null) return true;

    final refresh = await _storage.read(key: _keyRefresh);
    if (refresh == null) return false;

    try {
      final res = await _api.refresh(refreshToken: refresh);
      final newAccess = res['access'] as String?;
      if (newAccess == null) return false;
      await _storage.write(key: _keyAccess, value: newAccess);
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }
}

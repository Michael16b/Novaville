import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/user_repository.dart';

/// Thin abstraction wrapper to avoid direct platform package imports in this
/// file. Provide a [FlutterSecureStorage]-based implementation in
/// `auth_storage_impl.dart`.
abstract class TokenStorage {
  Future<void> write({required String key, required String? value});
  Future<String?> read({required String key});
  Future<void> delete({required String key});
}

/// In-memory token storage (fallback / tests).
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
  AuthRepositoryImpl({
    required AuthApi api,
    required IUserRepository userRepository,
    TokenStorage? storage,
  })  : _api = api,
        _userRepository = userRepository,
        _storage = storage ?? InMemoryTokenStorage();

  final AuthApi _api;
  final IUserRepository _userRepository;
  final TokenStorage _storage;

  static const _keyAccess = 'access_token';
  static const _keyRefresh = 'refresh_token';

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    try {
      final data = await _api.login(username: username, password: password);
      final access = data['access'] as String?;
      final refresh = data['refresh'] as String?;
      if (access == null || refresh == null) {
        throw AuthFailure(AppTextsAuth.serverInvalidResponse);
      }

      await _storage.write(key: _keyAccess, value: access);
      await _storage.write(key: _keyRefresh, value: refresh);

      // Extract user info from the login response (already returned by the backend)
      final userData = data['user'] as Map<String, dynamic>?;
      if (userData == null) {
        throw AuthFailure(AppTextsAuth.serverInvalidResponse);
      }

      return User.fromJson(userData);
    } catch (e) {
      debugPrint('AuthRepositoryImpl.login error: $e');
      if (e is AuthFailure) rethrow;
      // Convert other exceptions into AuthFailure for a clear error message
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: _keyAccess);
    await _storage.delete(key: _keyRefresh);
  }

  @override
  Future<User?> hasValidSession() async {
    final access = await _storage.read(key: _keyAccess);
    if (access != null) {
      try {
        return await _userRepository.getCurrentUser();
      } catch (e, stackTrace) {
        debugPrint('AuthRepositoryImpl.hasValidSession getCurrentUser error: $e');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    final refresh = await _storage.read(key: _keyRefresh);
    if (refresh == null) return null;

    try {
      final res = await _api.refresh(refreshToken: refresh);
      final newAccess = res['access'] as String?;
      if (newAccess == null) return null;
      await _storage.write(key: _keyAccess, value: newAccess);
      return await _userRepository.getCurrentUser();
    } catch (_) {
      await logout();
      return null;
    }
  }
}

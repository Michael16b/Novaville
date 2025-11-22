import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage}) :
    _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<void> write({required String key, required String? value}) async {
    if (value == null) {
      await _storage.delete(key: key);
      return;
    }
    await _storage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }
}


import 'dart:async';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract class IAuthRepository {
  Future<User> login({required String username, required String password});
  Future<void> logout();
  Future<User?> hasValidSession();
}

class FakeAuthRepository implements IAuthRepository {
  User? _user;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (username.isEmpty || password.isEmpty) {
      throw AuthFailure(AppTextsAuth.emptyUsernameOrPassword);
    }
    // Stub: accept any credentials and generate a fake user
    _user = User(
      id: 1,
      username: username,
      email: '$username@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.citizen,
    );
    return _user!;
  }

  @override
  Future<void> logout() async {
    _user = null;
  }

  @override
  Future<User?> hasValidSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // Force logout on startup during development
    return null;
  }
}

// Removed factory/import to avoid circular imports and directive order issues.






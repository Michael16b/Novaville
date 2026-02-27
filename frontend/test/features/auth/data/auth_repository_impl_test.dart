import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/auth/data/auth_api.dart';
import 'package:frontend/features/auth/data/auth_repository_impl.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// --- Mocks ---

class _StubUserRepository implements IUserRepository {
  final User? returnUser;
  final bool throwOnGetCurrentUser;

  _StubUserRepository({this.returnUser, this.throwOnGetCurrentUser = false});

  static const _defaultUser = User(
    id: 1,
    username: 'admin',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    role: UserRole.globalAdmin,
  );

  @override
  Future<User> getCurrentUser() async {
    if (throwOnGetCurrentUser) throw Exception('getCurrentUser failed');
    return returnUser ?? _defaultUser;
  }

  @override
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser({required int userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<User> createUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    UserRole role = UserRole.citizen,
    int? neighborhoodId,
  }) async {
    throw UnimplementedError();
  }
}

AuthRepositoryImpl _buildRepo({
  required InMemoryTokenStorage storage,
  required _StubUserRepository userRepo,
  http.Client? httpClient,
}) {
  return AuthRepositoryImpl(
    api: AuthApi(
      baseUrl: 'http://localhost:8000',
      client: httpClient ?? MockClient((_) async => http.Response('{}', 500)),
    ),
    userRepository: userRepo,
    storage: storage,
  );
}

void main() {
  group('AuthRepositoryImpl.hasValidSession', () {
    test(
      'returns user when access token present and getCurrentUser succeeds',
      () async {
        final storage = InMemoryTokenStorage();
        await storage.write(key: 'access_token', value: 'valid-access');

        final repo = _buildRepo(
          storage: storage,
          userRepo: _StubUserRepository(),
        );

        final user = await repo.hasValidSession();
        expect(user, isNotNull);
        expect(user!.username, 'admin');
      },
    );

    test(
      'falls back to refresh path when access token present but getCurrentUser throws',
      () async {
        final storage = InMemoryTokenStorage();
        await storage.write(key: 'access_token', value: 'expired-access');
        await storage.write(key: 'refresh_token', value: 'valid-refresh');

        // First getCurrentUser() call throws (expired access token); second call (after refresh) succeeds.
        final seqRepo = _SequentialUserRepository(
          responses: [
            () => throw Exception('401 Unauthorized'),
            () => const User(
              id: 2,
              username: 'refreshed',
              email: 'r@example.com',
              firstName: 'Refreshed',
              lastName: 'User',
            ),
          ],
        );

        final mockClient = MockClient((request) async {
          if (request.url.path.contains('refresh')) {
            return http.Response('{"access":"new-access-token"}', 200);
          }
          return http.Response('{}', 500);
        });

        final repo = AuthRepositoryImpl(
          api: AuthApi(baseUrl: 'http://localhost:8000', client: mockClient),
          userRepository: seqRepo,
          storage: storage,
        );

        final user = await repo.hasValidSession();
        expect(user, isNotNull);
        expect(user!.username, 'refreshed');
        // New access token should have been stored
        final stored = await storage.read(key: 'access_token');
        expect(stored, 'new-access-token');
      },
    );

    test('returns null when no tokens are stored', () async {
      final storage = InMemoryTokenStorage();
      final repo = _buildRepo(
        storage: storage,
        userRepo: _StubUserRepository(),
      );

      final user = await repo.hasValidSession();
      expect(user, isNull);
    });

    test('returns null and clears tokens when refresh fails', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'expired-access');
      await storage.write(key: 'refresh_token', value: 'expired-refresh');

      final mockClient = MockClient((request) async {
        return http.Response('{"detail":"Token expired"}', 401);
      });

      final repo = AuthRepositoryImpl(
        api: AuthApi(baseUrl: 'http://localhost:8000', client: mockClient),
        userRepository: _StubUserRepository(throwOnGetCurrentUser: true),
        storage: storage,
      );

      final user = await repo.hasValidSession();
      expect(user, isNull);
      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    });

    test(
      'returns null when refresh token missing and access token invalid',
      () async {
        final storage = InMemoryTokenStorage();
        await storage.write(key: 'access_token', value: 'bad-access');
        // No refresh token

        final repo = _buildRepo(
          storage: storage,
          userRepo: _StubUserRepository(throwOnGetCurrentUser: true),
        );

        final user = await repo.hasValidSession();
        expect(user, isNull);
      },
    );
  });

  group('AuthRepositoryImpl.logout', () {
    test('removes both tokens from storage', () async {
      final storage = InMemoryTokenStorage();
      await storage.write(key: 'access_token', value: 'access');
      await storage.write(key: 'refresh_token', value: 'refresh');

      final repo = _buildRepo(
        storage: storage,
        userRepo: _StubUserRepository(),
      );
      await repo.logout();

      expect(await storage.read(key: 'access_token'), isNull);
      expect(await storage.read(key: 'refresh_token'), isNull);
    });
  });
}

/// A [IUserRepository] stub that returns responses from a list in sequence.
class _SequentialUserRepository implements IUserRepository {
  final List<User Function()> responses;
  int _index = 0;

  _SequentialUserRepository({required this.responses});

  @override
  Future<User> getCurrentUser() async {
    if (_index >= responses.length) throw StateError('No more responses');
    return responses[_index++]();
  }

  @override
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser({required int userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<User> createUser({
    required String username,
    required String email,
    required String firstName,
    required String lastName,
    required String password,
    UserRole role = UserRole.citizen,
    int? neighborhoodId,
  }) async {
    throw UnimplementedError();
  }
}

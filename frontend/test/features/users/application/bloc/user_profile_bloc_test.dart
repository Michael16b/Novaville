import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/users/application/bloc/user_profil_bloc/user_profile_bloc.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';

/// Fake repository implementation for tests.
class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository({
    this.userToReturn,
    this.shouldThrow = false,
    this.shouldThrowOnUpdate = false,
    this.errorMessage = 'Network error',
  });

  final User? userToReturn;
  final bool shouldThrow;
  final bool shouldThrowOnUpdate;
  final String errorMessage;

  static const _defaultUser = User(
    id: 1,
    username: 'jdoe',
    email: 'john.doe@example.com',
    firstName: 'John',
    lastName: 'Doe',
  );

  @override
  Future<User> getCurrentUser() async {
    if (shouldThrow) throw Exception(errorMessage);
    return userToReturn ?? _defaultUser;
  }

  @override
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
  }) async {
    if (shouldThrow) throw Exception(errorMessage);
    return UserPage(
      count: 1,
      next: null,
      previous: null,
      results: [userToReturn ?? _defaultUser],
    );
  }

  @override
  Future<User> updateUser({
    required int userId,
    String? firstName,
    String? lastName,
    String? username,
    String? email,
  }) async {
    if (shouldThrow || shouldThrowOnUpdate) throw Exception(errorMessage);
    return User(
      id: userId,
      username: username ?? 'jdoe',
      email: email ?? 'john.doe@example.com',
      firstName: firstName ?? 'John',
      lastName: lastName ?? 'Doe',
    );
  }

  @override
  Future<void> deleteUser({required int userId}) async {
    if (shouldThrow) throw Exception(errorMessage);
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
    if (shouldThrow) throw Exception(errorMessage);
    return User(
      id: 99,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      neighborhoodId: neighborhoodId,
    );
  }
}

void main() {
  group('UserProfileBloc', () {
    const testUser = User(
      id: 1,
      username: 'jdoe',
      email: 'john.doe@example.com',
      firstName: 'John',
      lastName: 'Doe',
    );

    test('initial state is UserProfileStatus.initial', () {
      final bloc = UserProfileBloc(repository: _FakeUserRepository());
      expect(bloc.state.status, UserProfileStatus.initial);
      expect(bloc.state.user, isNull);
      expect(bloc.state.error, isNull);
      bloc.close();
    });

    test(
      'UserProfileLoadRequested emits loading then loaded with the user',
      () async {
        final bloc = UserProfileBloc(
          repository: _FakeUserRepository(userToReturn: testUser),
        );

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loading,
            ),
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.loaded)
                .having((s) => s.user, 'user', testUser)
                .having((s) => s.isUpdate, 'isUpdate', false),
          ]),
        );

        bloc.add(const UserProfileLoadRequested());
        await expectation;

        await bloc.close();
      },
    );

    test(
      'UserProfileLoadRequested emits loading then failure on error',
      () async {
        final bloc = UserProfileBloc(
          repository: _FakeUserRepository(
            shouldThrow: true,
            errorMessage: 'Server error',
          ),
        );

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loading,
            ),
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.failure)
                .having((s) => s.error, 'error', contains('Server error')),
          ]),
        );

        bloc.add(const UserProfileLoadRequested());
        await expectation;

        await bloc.close();
      },
    );

    test(
      'UserProfileUpdateRequested emits updating with current user then loaded with isUpdate=true',
      () async {
        final bloc = UserProfileBloc(
          repository: _FakeUserRepository(userToReturn: testUser),
        );

        // First load the user
        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loading,
            ),
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loaded,
            ),
          ]),
        );
        bloc.add(const UserProfileLoadRequested());
        await loadExpectation;

        // Then update
        final updateExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.updating)
                .having((s) => s.user, 'user', testUser),
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.loaded)
                .having((s) => s.isUpdate, 'isUpdate', true)
                .having((s) => s.user?.firstName, 'firstName', 'Jane')
                .having((s) => s.user?.email, 'email', 'jane.doe@example.com'),
          ]),
        );

        bloc.add(
          const UserProfileUpdateRequested(
            userId: 1,
            firstName: 'Jane',
            lastName: 'Doe',
            username: 'jdoe',
            email: 'jane.doe@example.com',
          ),
        );
        await updateExpectation;

        await bloc.close();
      },
    );

    test(
      'UserProfileUpdateRequested without a current user emits no state',
      () async {
        final bloc = UserProfileBloc(
          repository: _FakeUserRepository(userToReturn: testUser),
        );

        // Do not load the user — initial state has user=null
        final expectation = expectLater(bloc.stream, emitsDone);

        bloc.add(
          const UserProfileUpdateRequested(
            userId: 1,
            firstName: 'Jane',
            lastName: 'Doe',
            username: 'jdoe',
            email: 'jane.doe@example.com',
          ),
        );
        await bloc.close();
        await expectation;
      },
    );

    test(
      'UserProfileUpdateRequested emits updating then failure on error',
      () async {
        final bloc = UserProfileBloc(
          repository: _FakeUserRepository(
            userToReturn: testUser,
            shouldThrowOnUpdate: true,
            errorMessage: 'Update failed',
          ),
        );

        // Load the user successfully
        final loadExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loading,
            ),
            isA<UserProfileState>().having(
              (s) => s.status,
              'status',
              UserProfileStatus.loaded,
            ),
          ]),
        );
        bloc.add(const UserProfileLoadRequested());
        await loadExpectation;

        // The update fails
        final updateExpectation = expectLater(
          bloc.stream,
          emitsInOrder([
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.updating)
                .having((s) => s.user, 'user', testUser),
            isA<UserProfileState>()
                .having((s) => s.status, 'status', UserProfileStatus.failure)
                .having((s) => s.error, 'error', contains('Update failed'))
                .having((s) => s.user, 'user', testUser)
                .having((s) => s.isUpdate, 'isUpdate', true),
          ]),
        );

        bloc.add(
          const UserProfileUpdateRequested(
            userId: 1,
            firstName: 'Jane',
            lastName: 'Doe',
            username: 'jdoe',
            email: 'jane.doe@example.com',
          ),
        );
        await updateExpectation;

        await bloc.close();
      },
    );

    test('UserProfileState.updating preserves the current user', () {
      const user = User(
        id: 42,
        username: 'tester',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
      );

      const state = UserProfileState.updating(user);

      expect(state.status, UserProfileStatus.updating);
      expect(state.user, user);
      expect(state.error, isNull);
      expect(state.isUpdate, isFalse);
    });
  });
}

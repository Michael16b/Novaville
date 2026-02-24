import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/account/application/bloc/user_profile_bloc.dart';
import 'package:frontend/features/account/data/models/user.dart';
import 'package:frontend/features/account/data/user_repository.dart';

/// Fausse implémentation du repository pour les tests
class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository({
    this.userToReturn,
    this.shouldThrow = false,
    this.shouldThrowOnUpdate = false,
    this.errorMessage = 'Erreur réseau',
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

    test('état initial est UserProfileStatus.initial', () {
      final bloc = UserProfileBloc(repository: _FakeUserRepository());
      expect(bloc.state.status, UserProfileStatus.initial);
      expect(bloc.state.user, isNull);
      expect(bloc.state.error, isNull);
      bloc.close();
    });

    test('UserProfileLoadRequested émet loading puis loaded avec l\'utilisateur', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(userToReturn: testUser),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loading),
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loaded)
              .having((s) => s.user, 'user', testUser)
              .having((s) => s.isUpdate, 'isUpdate', false),
        ]),
      );

      bloc.add(const UserProfileLoadRequested());
      await expectation;

      await bloc.close();
    });

    test('UserProfileLoadRequested émet loading puis failure en cas d\'erreur', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(shouldThrow: true, errorMessage: 'Erreur serveur'),
      );

      final expectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loading),
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.failure)
              .having((s) => s.error, 'error', contains('Erreur serveur')),
        ]),
      );

      bloc.add(const UserProfileLoadRequested());
      await expectation;

      await bloc.close();
    });

    test('UserProfileUpdateRequested émet updating avec utilisateur courant puis loaded avec isUpdate=true', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(userToReturn: testUser),
      );

      // D'abord charger l'utilisateur
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loading),
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loaded),
        ]),
      );
      bloc.add(const UserProfileLoadRequested());
      await loadExpectation;

      // Puis mettre à jour
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
    });

    test('UserProfileUpdateRequested sans utilisateur courant n\'émet aucun état', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(userToReturn: testUser),
      );

      // Ne pas charger l'utilisateur, l'état initial a user=null
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
    });

    test('UserProfileUpdateRequested émet updating puis failure en cas d\'erreur', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(
          userToReturn: testUser,
          shouldThrowOnUpdate: true,
          errorMessage: 'Mise à jour impossible',
        ),
      );

      // Charger l'utilisateur avec succès
      final loadExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loading),
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.loaded),
        ]),
      );
      bloc.add(const UserProfileLoadRequested());
      await loadExpectation;

      // La mise à jour échoue
      final updateExpectation = expectLater(
        bloc.stream,
        emitsInOrder([
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.updating)
              .having((s) => s.user, 'user', testUser),
          isA<UserProfileState>()
              .having((s) => s.status, 'status', UserProfileStatus.failure)
              .having((s) => s.error, 'error', contains('Mise à jour impossible'))
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
    });

    test('UserProfileState.updating préserve l\'utilisateur courant', () {
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

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/account/application/bloc/user_profile_bloc.dart';
import 'package:frontend/features/account/data/models/user.dart';
import 'package:frontend/features/account/data/user_repository.dart';

/// Fausse implémentation du repository pour les tests
class _FakeUserRepository implements IUserRepository {
  _FakeUserRepository({
    this.userToReturn,
    this.shouldThrow = false,
    this.errorMessage = 'Erreur réseau',
  });

  final User? userToReturn;
  final bool shouldThrow;
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
    if (shouldThrow) throw Exception(errorMessage);
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

      final states = <UserProfileState>[];
      bloc.stream.listen(states.add);

      bloc.add(const UserProfileLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, 2);
      expect(states[0].status, UserProfileStatus.loading);
      expect(states[1].status, UserProfileStatus.loaded);
      expect(states[1].user, testUser);
      expect(states[1].isUpdate, isFalse);

      await bloc.close();
    });

    test('UserProfileLoadRequested émet loading puis failure en cas d\'erreur', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(shouldThrow: true, errorMessage: 'Erreur serveur'),
      );

      final states = <UserProfileState>[];
      bloc.stream.listen(states.add);

      bloc.add(const UserProfileLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, 2);
      expect(states[0].status, UserProfileStatus.loading);
      expect(states[1].status, UserProfileStatus.failure);
      expect(states[1].error, contains('Erreur serveur'));

      await bloc.close();
    });

    test('UserProfileUpdateRequested émet updating avec utilisateur courant puis loaded avec isUpdate=true', () async {
      // D'abord charger l'utilisateur
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(userToReturn: testUser),
      );

      bloc.add(const UserProfileLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final states = <UserProfileState>[];
      bloc.stream.listen(states.add);

      bloc.add(
        const UserProfileUpdateRequested(
          userId: 1,
          firstName: 'Jane',
          lastName: 'Doe',
          username: 'jdoe',
          email: 'jane.doe@example.com',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, 2);
      // L'état updating doit préserver l'utilisateur courant
      expect(states[0].status, UserProfileStatus.updating);
      expect(states[0].user, testUser);
      // L'état loaded doit avoir isUpdate=true
      expect(states[1].status, UserProfileStatus.loaded);
      expect(states[1].isUpdate, isTrue);
      expect(states[1].user?.firstName, 'Jane');
      expect(states[1].user?.email, 'jane.doe@example.com');

      await bloc.close();
    });

    test('UserProfileUpdateRequested sans utilisateur courant n\'émet aucun état', () async {
      final bloc = UserProfileBloc(
        repository: _FakeUserRepository(userToReturn: testUser),
      );

      // Ne pas charger l'utilisateur, l'état initial a user=null
      final states = <UserProfileState>[];
      bloc.stream.listen(states.add);

      bloc.add(
        const UserProfileUpdateRequested(
          userId: 1,
          firstName: 'Jane',
          lastName: 'Doe',
          username: 'jdoe',
          email: 'jane.doe@example.com',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states, isEmpty);

      await bloc.close();
    });

    test('UserProfileUpdateRequested émet updating puis failure en cas d\'erreur', () async {
      final successRepo = _FakeUserRepository(userToReturn: testUser);
      final failingRepo = _FakeUserRepository(
        userToReturn: testUser,
        shouldThrow: true,
        errorMessage: 'Mise à jour impossible',
      );

      // Charger avec un repo qui réussit
      final bloc = UserProfileBloc(repository: successRepo);
      bloc.add(const UserProfileLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Créer un nouveau bloc qui échoue lors de la mise à jour
      final bloc2 = UserProfileBloc(repository: failingRepo);
      bloc2.add(const UserProfileLoadRequested());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final states = <UserProfileState>[];
      bloc2.stream.listen(states.add);

      bloc2.add(
        const UserProfileUpdateRequested(
          userId: 1,
          firstName: 'Jane',
          lastName: 'Doe',
          username: 'jdoe',
          email: 'jane.doe@example.com',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, 2);
      expect(states[0].status, UserProfileStatus.updating);
      expect(states[1].status, UserProfileStatus.failure);
      expect(states[1].error, contains('Mise à jour impossible'));

      await bloc.close();
      await bloc2.close();
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

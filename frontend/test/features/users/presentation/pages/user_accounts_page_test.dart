import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts/texts_general.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/reports/data/models/neighborhood.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/presentation/pages/user_accounts_page.dart';

// --- Mocks ---

class MockAuthRepository implements IAuthRepository {
  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> hasValidSession() async => const User(
    id: 1,
    username: 'admin',
    email: 'admin@example.com',
    firstName: 'Admin',
    lastName: 'User',
    role: UserRole.globalAdmin,
  );
}

class MockUserRepository implements IUserRepository {
  final bool shouldThrow;
  final bool shouldThrowOnDelete;
  final List<User> users;
  final List<Neighborhood> neighborhoods;

  MockUserRepository({
    this.shouldThrow = false,
    this.shouldThrowOnDelete = false,
    this.users = const [],
    this.neighborhoods = const [
      Neighborhood(id: 1, name: 'Quartier Centre', postalCode: '75001'),
    ],
  });

  @override
  Future<User> getCurrentUser() async {
    return const User(
      id: 1,
      username: 'admin',
      email: 'admin@example.com',
      firstName: 'Admin',
      lastName: 'User',
      role: UserRole.globalAdmin,
    );
  }

  @override
  Future<UserPage> listUsers({
    String? ordering,
    String? search,
    int page = 1,
    String? role,
    int? neighborhood,
  }) async {
    if (shouldThrow) throw Exception('Network error');
    return UserPage(
      count: users.length,
      next: null,
      previous: null,
      results: users,
    );
  }

  @override
  Future<List<Neighborhood>> listNeighborhoods() async {
    return neighborhoods;
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
    if (shouldThrow || shouldThrowOnDelete) throw Exception('Delete failed');
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
    if (shouldThrow) {
      throw Exception('Create failed');
    }
    return User(
      id: 999,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      role: role,
      neighborhoodId: neighborhoodId,
    );
  }

  @override
  Future<void> updatePassword({
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    return;
  }
}

void main() {
  group('UserAccountsPage', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockAuthRepository);
      // Initialize auth bloc with a user
      authBloc.add(const AuthStarted());
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createWidgetUnderTest({required IUserRepository userRepository}) {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: UserAccountsPage(userRepository: userRepository),
        ),
      );
    }

    Future<void> pumpPage(
      WidgetTester tester, {
      required IUserRepository userRepository,
    }) async {
      await tester.pumpWidget(
        createWidgetUnderTest(userRepository: userRepository),
      );
      // Avoid pumpAndSettle because the page can contain repeating animations.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets(
      'renders title and floating add button',
      (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUserRepository = MockUserRepository(users: []);

      await tester.pumpWidget(
        createWidgetUnderTest(userRepository: mockUserRepository),
      );
      await tester.pumpAndSettle(); // Wait for bloc to load

      expect(find.text(UserTexts.title), findsAtLeastNWidgets(1));
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays list of users', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final users = [
        const User(
          id: 1,
          username: 'admin',
          email: 'admin@example.com',
          firstName: 'Admin',
          lastName: 'User',
          role: UserRole.globalAdmin,
        ),
        const User(
          id: 2,
          username: 'user2',
          email: 'user2@example.com',
          firstName: 'John',
          lastName: 'Doe',
          role: UserRole.citizen,
        ),
      ];
      final mockUserRepository = MockUserRepository(users: users);

      await tester.pumpWidget(
        createWidgetUnderTest(userRepository: mockUserRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('user2'), findsOneWidget);
    });

    testWidgets('shows error message when loading fails', (
      WidgetTester tester,
    ) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUserRepository = MockUserRepository(shouldThrow: true);

      await tester.pumpWidget(
        createWidgetUnderTest(userRepository: mockUserRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text(UserTexts.error), findsOneWidget);
      // Expect 2 widgets: one in the body, one in the SnackBar
      expect(find.text('Exception: Network error'), findsAtLeastNWidgets(1));
      expect(find.text(AppTextsGeneral.retry), findsOneWidget);
    });

    testWidgets('shows empty state when no users', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockUserRepository = MockUserRepository(users: []);

      await tester.pumpWidget(
        createWidgetUnderTest(userRepository: mockUserRepository),
      );
      await tester.pumpAndSettle();

      expect(find.text(UserTexts.noUsers), findsOneWidget);
      expect(find.text(UserTexts.noUsersFound), findsOneWidget);
    });

    testWidgets(
      'clears deleted user on failure and does not show success snackbar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(2400, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        // Admin (id=1) is the current user; John (id=2) can be deleted but delete will fail
        final users = [
          const User(
            id: 1,
            username: 'admin',
            email: 'admin@example.com',
            firstName: 'Admin',
            lastName: 'User',
            role: UserRole.globalAdmin,
          ),
          const User(
            id: 2,
            username: 'john',
            email: 'john@example.com',
            firstName: 'John',
            lastName: 'Doe',
            role: UserRole.citizen,
          ),
        ];
        final mockUserRepository = MockUserRepository(
          users: users,
          shouldThrowOnDelete: true,
        );

        await tester.pumpWidget(
          createWidgetUnderTest(userRepository: mockUserRepository),
        );
        await tester.pumpAndSettle(); // Wait for initial load

        // Open the delete dialog for John (the second delete icon)
        final deleteButtons = find.byIcon(Icons.delete_outline_rounded);
        await tester.tap(deleteButtons.last);
        await tester.pumpAndSettle();

        // Confirm delete in the dialog
        await tester.tap(find.text(AppTextsGeneral.delete).last);
        await tester.pumpAndSettle();

        // Error snackbar should appear (from failure state)
        expect(find.text('Exception: Delete failed'), findsOneWidget);

        // Success snackbar must NOT appear (deletedUser was cleared)
        expect(find.textContaining(UserTexts.deleted), findsNothing);
      },
    );
  });
}

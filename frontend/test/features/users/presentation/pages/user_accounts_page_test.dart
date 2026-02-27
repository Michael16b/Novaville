import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts/texts_user_accounts.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/features/users/data/user_repository.dart';
import 'package:frontend/features/users/presentation/pages/user_accounts_page.dart';

// --- Mocks ---

class MockAuthRepository implements IAuthRepository {
  @override
  Future<User> login({required String username, required String password}) async {
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
  final List<User> users;

  MockUserRepository({
    this.shouldThrow = false,
    this.users = const [],
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
  Future<UserPage> listUsers({String? ordering, int page = 1}) async {
    if (shouldThrow) throw Exception('Network error');
    return UserPage(
      count: users.length,
      next: null,
      previous: null,
      results: users,
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
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser({required int userId}) async {
    if (shouldThrow) throw Exception('Delete failed');
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

    testWidgets('renders title and add user button', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUserRepository = MockUserRepository(users: []);
      
      await tester.pumpWidget(createWidgetUnderTest(userRepository: mockUserRepository));
      await tester.pumpAndSettle(); // Wait for bloc to load

      expect(find.text(UserTexts.title), findsAtLeastNWidgets(1));
      expect(find.text(UserTexts.addUser), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('displays list of users', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

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

      await tester.pumpWidget(createWidgetUnderTest(userRepository: mockUserRepository));
      await tester.pumpAndSettle();

      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('admin'), findsOneWidget);
      expect(find.text('user2'), findsOneWidget);
    });

    testWidgets('shows error message when loading fails', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUserRepository = MockUserRepository(shouldThrow: true);

      await tester.pumpWidget(createWidgetUnderTest(userRepository: mockUserRepository));
      await tester.pumpAndSettle();

      expect(find.text(UserTexts.error), findsOneWidget);
      // Expect 2 widgets: one in the body, one in the SnackBar
      expect(find.text('Exception: Network error'), findsNWidgets(2));
      expect(find.text(UserTexts.retry), findsOneWidget);
    });

    testWidgets('shows empty state when no users', (WidgetTester tester) async {
      // Set a large screen size to avoid overflow
      tester.view.physicalSize = const Size(2400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockUserRepository = MockUserRepository(users: []);

      await tester.pumpWidget(createWidgetUnderTest(userRepository: mockUserRepository));
      await tester.pumpAndSettle();

      expect(find.text(UserTexts.noUsers), findsOneWidget);
      expect(find.text(UserTexts.noUsersFound), findsOneWidget);
    });
  });
}

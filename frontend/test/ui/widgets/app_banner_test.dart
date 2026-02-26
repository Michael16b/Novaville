import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_navigation.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/my_account/data/models/user.dart';
import 'package:frontend/features/my_account/data/models/user_role.dart';
import 'package:frontend/ui/assets.dart';
import 'package:frontend/ui/widgets/app_banner.dart';

class MockAuthRepository implements IAuthRepository {
  @override
  Future<User> login({required String username, required String password}) async {
    return User(
      id: 1,
      username: username,
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.citizen,
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<User?> hasValidSession() async => User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.citizen,
  );
}

void main() {
  group('AppBanner', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createWidgetUnderTest({String currentLocation = '/'}) {
      return MaterialApp(
        home: Scaffold(
          body: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: AppBanner(currentLocation: currentLocation),
          ),
        ),
      );
    }

    testWidgets('renders logo image', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.login_logo,
      );

      expect(logoFinder, findsOneWidget);
    });

    testWidgets('renders home button with correct text', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text(AppTextsNavigation.homeButton), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('renders user account icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('opens menu when account icon is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the account icon to open the menu
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();

      // Verify menu items are displayed
      expect(find.text(AppTextsNavigation.personalInfo), findsOneWidget);
      expect(find.text(AppTextsAuth.logout), findsOneWidget);
    });

    testWidgets('menu displays personal info option with correct icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Open the menu
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();

      // Verify personal info menu item has the correct icon
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.text(AppTextsNavigation.personalInfo), findsOneWidget);
    });

    testWidgets('menu displays logout option with correct icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Open the menu
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();

      // Verify logout menu item has the correct icon
      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text(AppTextsAuth.logout), findsOneWidget);
    });

    testWidgets('triggers logout when logout menu item is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Open the menu
      await tester.tap(find.byIcon(Icons.account_circle_outlined));
      await tester.pumpAndSettle();

      // Tap the logout option
      await tester.tap(find.text(AppTextsAuth.logout));
      await tester.pumpAndSettle();

      // Verify that AuthLogoutRequested event was added to the bloc
      expect(authBloc.state.status, AuthStatus.unauthenticated);
    });

    testWidgets('home button is tappable', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final homeButtonFinder = find.text(AppTextsNavigation.homeButton);
      expect(homeButtonFinder, findsOneWidget);

      // Verify the button can be tapped (no exception should be thrown)
      await tester.tap(homeButtonFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('uses SafeArea to avoid system UI overlap', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final safeAreaFinder = find.byWidgetPredicate(
        (widget) => widget is SafeArea && widget.bottom == false,
      );

      expect(safeAreaFinder, findsOneWidget);
    });

    testWidgets('has correct layout structure with logo and buttons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify the main container exists
      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.child is SafeArea,
      );
      expect(containerFinder, findsOneWidget);

      // Verify Row layout exists
      expect(find.byWidgetPredicate((widget) => widget is Row), findsAtLeastNWidgets(1));
    });
  });
}

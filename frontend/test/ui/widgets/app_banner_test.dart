import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/texts/texts_auth.dart';
import 'package:frontend/constants/texts/texts_navigation.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/ui/assets.dart';
import 'package:frontend/ui/widgets/app_banner.dart';
import 'package:go_router/go_router.dart';

class MockAuthRepository implements IAuthRepository {

  MockAuthRepository({this.hasSession = true});
  bool logoutCalled = false;
  final bool hasSession;

  @override
  Future<User> login({
    required String username,
    required String password,
  }) async {
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
  Future<void> logout() async {
    logoutCalled = true;
  }

  @override
  Future<User?> hasValidSession() async {
    if (!hasSession) return null;

    return const User(
      id: 1,
      username: 'testuser',
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
      role: UserRole.citizen,
    );
  }
}

void main() {
  group('AppBanner', () {
    late AuthBloc authBloc;
    late MockAuthRepository mockAuthRepository;

    Future<void> pumpBanner(
      WidgetTester tester, {
      String currentLocation = '/',
      bool authenticated = true,
    }) async {
      mockAuthRepository = MockAuthRepository(hasSession: authenticated);
      authBloc = AuthBloc(repository: mockAuthRepository);
      authBloc.add(const AuthStarted());

      final router = GoRouter(
        initialLocation: currentLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: BlocProvider<AuthBloc>.value(
                value: authBloc,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: 1200,
                    child: AppBanner(currentLocation: currentLocation),
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.userAccounts,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.myAccount,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    Future<void> pumpCompactBanner(
      WidgetTester tester, {
      String currentLocation = '/',
      bool authenticated = true,
    }) async {
      mockAuthRepository = MockAuthRepository(hasSession: authenticated);
      authBloc = AuthBloc(repository: mockAuthRepository);
      authBloc.add(const AuthStarted());

      final router = GoRouter(
        initialLocation: currentLocation,
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: BlocProvider<AuthBloc>.value(
                value: authBloc,
                child: AppBanner(currentLocation: currentLocation),
              ),
            ),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.register,
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: AppRoutes.myAccount,
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      authBloc = AuthBloc(repository: mockAuthRepository);
    });

    tearDown(() {
      authBloc.close();
    });

    testWidgets('renders logo image', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      final logoFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == AppAssets.login_logo,
      );

      expect(logoFinder, findsOneWidget);
    });

    testWidgets('renders home button with correct text', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      expect(find.text(AppTextsNavigation.homeButton), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('renders user account icon for authenticated users', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('opens menu when account icon is tapped', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.text(AppTextsNavigation.personalInfo), findsOneWidget);
      expect(find.text(AppTextsAuth.logout), findsOneWidget);
    });

    testWidgets('menu displays personal info option with correct icon', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person), findsNWidgets(2));
      expect(find.text(AppTextsNavigation.personalInfo), findsOneWidget);
    });

    testWidgets('menu displays logout option with correct icon', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.logout), findsOneWidget);
      expect(find.text(AppTextsAuth.logout), findsOneWidget);
    });

    testWidgets('triggers logout when logout menu item is tapped', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppTextsAuth.logout));
      await tester.pumpAndSettle();

      expect(mockAuthRepository.logoutCalled, isTrue);
    });

    testWidgets('home button is tappable', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      final homeButtonFinder = find.text(AppTextsNavigation.homeButton);
      expect(homeButtonFinder, findsOneWidget);

      await tester.tap(homeButtonFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('uses SafeArea to avoid system UI overlap', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      final safeAreaFinder = find.byWidgetPredicate(
        (widget) => widget is SafeArea && widget.bottom == false,
      );

      expect(safeAreaFinder, findsOneWidget);
    });

    testWidgets('has correct layout structure with logo and buttons', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester);

      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.child is SafeArea,
      );
      expect(containerFinder, findsOneWidget);

      expect(
        find.byWidgetPredicate((widget) => widget is Row),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('shows login button for unauthenticated visitors', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpBanner(tester, authenticated: false);

      expect(find.text(AppTextsAuth.login), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byIcon(Icons.person), findsNothing);
    });

    group('compact layout', () {
      testWidgets('renders hamburger menu icon instead of nav buttons', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(500, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpCompactBanner(tester);

        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text(AppTextsNavigation.homeButton), findsNothing);
      });

      testWidgets(
        'compact menu for authenticated users shows nav and profile/logout',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(500, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await pumpCompactBanner(tester);

          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();

          expect(find.text(AppTextsNavigation.homeButton), findsOneWidget);
          expect(find.text(AppTextsNavigation.personalInfo), findsOneWidget);
          expect(find.text(AppTextsAuth.logout), findsOneWidget);
          expect(find.text(AppTextsAuth.login), findsNothing);
          expect(find.text(AppTextsAuth.register), findsNothing);
        },
      );

      testWidgets(
        'compact menu for unauthenticated users shows nav and login/register',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(500, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await pumpCompactBanner(tester, authenticated: false);

          await tester.tap(find.byIcon(Icons.menu));
          await tester.pumpAndSettle();

          expect(find.text(AppTextsNavigation.homeButton), findsOneWidget);
          expect(find.text(AppTextsAuth.login), findsOneWidget);
          expect(find.text(AppTextsAuth.register), findsOneWidget);
          expect(find.text(AppTextsNavigation.personalInfo), findsNothing);
          expect(find.text(AppTextsAuth.logout), findsNothing);
        },
      );
    });
  });
}

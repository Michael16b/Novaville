import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/auth/application/bloc/auth_bloc.dart';
import 'package:frontend/features/auth/data/auth_repository.dart';
import 'package:frontend/features/users/data/models/user.dart';
import 'package:frontend/features/users/data/models/user_role.dart';
import 'package:frontend/ui/layouts/secured_layout.dart';
import 'package:frontend/ui/widgets/app_banner.dart';
import 'package:go_router/go_router.dart';

class _MockAuthRepository implements IAuthRepository {
  @override
  Future<User> login({
    required String username,
    required String password,
  }) async => User(
    id: 1,
    username: username,
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.citizen,
  );

  @override
  Future<void> logout() async {}

  @override
  Future<User?> hasValidSession() async => const User(
    id: 1,
    username: 'testuser',
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    role: UserRole.citizen,
  );
}

void main() {
  group('SecuredLayout', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(repository: _MockAuthRepository());
    });

    tearDown(() {
      authBloc.close();
    });

    Future<void> createWidgetUnderTest(
      WidgetTester tester, {
      Widget? child,
    }) async {
      authBloc.add(const AuthStarted());

      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (context, state) => BlocProvider<AuthBloc>.value(
              value: authBloc,
              child: SecuredLayout(
                currentLocation: '/test',
                child: child ?? const Center(child: Text('Test Child')),
              ),
            ),
          ),
          GoRoute(
            path: '/login',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/me',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/users',
            builder: (context, state) => const SizedBox.shrink(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const SizedBox.shrink(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
    }

    testWidgets(
      'Given a secured layout when it is rendered then it displays the child widget',
      (WidgetTester tester) async {
        const testText = 'Test Child Content';

        // Given / When
        await createWidgetUnderTest(
          tester,
          child: const Center(child: Text(testText)),
        );

        // Then
        expect(find.text(testText), findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then it contains a Scaffold root',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        final scaffoldFinder = find.byType(Scaffold);
        expect(scaffoldFinder, findsAtLeastNWidgets(1));
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then the Scaffold uses the page background color',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);

        expect(scaffold.backgroundColor, AppColors.page);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then it shows the app banner in the app bar',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        expect(find.byType(AppBanner), findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then the app bar uses the expected preferred size',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        final preferredSizeFinder = find.byWidgetPredicate(
          (widget) =>
              widget is PreferredSize &&
              widget.preferredSize == const Size.fromHeight(110),
        );

        expect(preferredSizeFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then the app bar material wrapper has elevation',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        final materialFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Material &&
              widget.elevation == 6 &&
              widget.color == AppColors.page,
        );

        expect(materialFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then the child is placed in the body',
      (WidgetTester tester) async {
        const childKey = Key('test-child');

        // Given / When
        await createWidgetUnderTest(
          tester,
          child: const SizedBox(key: childKey),
        );

        // Then
        expect(find.byKey(childKey), findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then its layout structure is correct',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        expect(scaffold.appBar, isNotNull);

        expect(find.text('Test Child'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it receives a list view child then it renders that child content',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(
          tester,
          child: ListView(
            children: const [
              ListTile(title: Text('Item 1')),
              ListTile(title: Text('Item 2')),
            ],
          ),
        );

        // Then
        expect(find.text('Item 1'), findsOneWidget);
        expect(find.text('Item 2'), findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when it is rendered then the banner material uses the expected shadow color',
      (WidgetTester tester) async {
        // Given / When
        await createWidgetUnderTest(tester);

        // Then
        final materialFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Material && widget.shadowColor == Colors.black54,
        );

        expect(materialFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Given a secured layout when a stateful child updates then the child state is preserved',
      (WidgetTester tester) async {
        final key = GlobalKey<_TestStatefulWidgetState>();

        // Given / When
        await createWidgetUnderTest(
          tester,
          child: _TestStatefulWidget(key: key),
        );

        // Then
        expect(find.text('Counter: 0'), findsOneWidget);

        await tester.tap(find.widgetWithText(ElevatedButton, 'Increment'));
        await tester.pump();

        expect(find.text('Counter: 1'), findsOneWidget);
      },
    );
  });
}

// Helper widget for testing state preservation
class _TestStatefulWidget extends StatefulWidget {
  const _TestStatefulWidget({super.key});

  @override
  State<_TestStatefulWidget> createState() => _TestStatefulWidgetState();
}

class _TestStatefulWidgetState extends State<_TestStatefulWidget> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Counter: $counter'),
          ElevatedButton(
            onPressed: () => setState(() => counter++),
            child: const Text('Increment'),
          ),
        ],
      ),
    );
  }
}

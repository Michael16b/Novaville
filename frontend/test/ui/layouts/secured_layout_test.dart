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

class _MockAuthRepository implements IAuthRepository {
  @override
  Future<User> login({required String username, required String password}) async => User(
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
  group('SecuredLayout', () {
    late AuthBloc authBloc;

    setUp(() {
      authBloc = AuthBloc(repository: _MockAuthRepository());
    });

    tearDown(() {
      authBloc.close();
    });

    Widget createWidgetUnderTest({Widget? child}) {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: authBloc,
          child: SecuredLayout(
            currentLocation: '/test',
            child: child ?? const Center(child: Text('Test Child')),
          ),
        ),
      );
    }

    testWidgets('renders child widget', (WidgetTester tester) async {
      const testText = 'Test Child Content';
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const Center(child: Text(testText)),
        ),
      );

      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('contains Scaffold as root widget', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final scaffoldFinder = find.byType(Scaffold);
      expect(scaffoldFinder, findsAtLeastNWidgets(1));
    });

    testWidgets('has correct background color', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final scaffold = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );

      expect(scaffold.backgroundColor, AppColors.page);
    });

    testWidgets('renders AppBanner in AppBar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(AppBanner), findsOneWidget);
    });

    testWidgets('AppBar has correct preferred size', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final preferredSizeFinder = find.byWidgetPredicate(
        (widget) =>
            widget is PreferredSize &&
            widget.preferredSize == const Size.fromHeight(110),
      );

      expect(preferredSizeFinder, findsOneWidget);
    });

    testWidgets('AppBar has Material wrapper with elevation', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final materialFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Material &&
            widget.elevation == 6 &&
            widget.color == AppColors.page,
      );

      expect(materialFinder, findsOneWidget);
    });

    testWidgets('child is rendered in body', (WidgetTester tester) async {
      const childKey = Key('test-child');
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: const SizedBox(key: childKey),
        ),
      );

      expect(find.byKey(childKey), findsOneWidget);
    });

    testWidgets('layout structure is correct', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify Scaffold exists
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // Verify AppBanner is in the AppBar
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.appBar, isNotNull);

      // Verify child is in the body
      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('works with different child widgets', (WidgetTester tester) async {
      // Test with ListView
      await tester.pumpWidget(
        createWidgetUnderTest(
          child: ListView(
            children: const [
              ListTile(title: Text('Item 1')),
              ListTile(title: Text('Item 2')),
            ],
          ),
        ),
      );

      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
    });

    testWidgets('banner elevation shadow is configured correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final materialFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Material &&
            widget.shadowColor == Colors.black54,
      );

      expect(materialFinder, findsOneWidget);
    });

    testWidgets('preserves child widget state', (WidgetTester tester) async {
      // Create a stateful child widget
      final key = GlobalKey<_TestStatefulWidgetState>();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthBloc>.value(
            value: authBloc,
            child: SecuredLayout(
              currentLocation: '/test',
              child: _TestStatefulWidget(key: key),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Counter: 0'), findsOneWidget);

      // Interact with the child widget
      await tester.tap(find.widgetWithText(ElevatedButton, 'Increment'));
      await tester.pump();

      // Verify state is preserved
      expect(find.text('Counter: 1'), findsOneWidget);
    });
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

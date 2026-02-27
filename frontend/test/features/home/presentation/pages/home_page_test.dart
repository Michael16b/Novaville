import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts/texts_home.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Verify title is rendered
      expect(find.text(AppTextsHome.homeTitle), findsOneWidget);

      // Verify subtitle is rendered
      expect(find.text(AppTextsHome.homeSubtitle), findsOneWidget);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final titleFinder = find.text(AppTextsHome.homeTitle);
      final Text titleWidget = tester.widget(titleFinder);

      expect(titleWidget.textAlign, TextAlign.center);
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.fontStyle, FontStyle.italic);
      expect(titleWidget.style?.color, AppColors.primary);
    });

    testWidgets('subtitle has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final subtitleFinder = find.text(AppTextsHome.homeSubtitle);
      final Text subtitleWidget = tester.widget(subtitleFinder);

      expect(subtitleWidget.textAlign, TextAlign.center);
      expect(subtitleWidget.style?.fontSize, 24);
      expect(subtitleWidget.style?.color, AppColors.secondaryText);
    });

    testWidgets('renders GridView with 6 MenuCards', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Verify CustomScrollView with SliverGrid exists
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget);

      // Verify 6 MenuCards are rendered
      expect(find.byType(MenuCard), findsNWidgets(6));
    });

    testWidgets('GridView has correct configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final sliverGridFinder = find.byType(SliverGrid);
      final SliverGrid sliverGrid = tester.widget(sliverGridFinder);

      // Verify SliverGrid uses SliverGridDelegateWithFixedCrossAxisCount
      expect(sliverGrid.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());

      final delegate = sliverGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisSpacing, 16);
      expect(delegate.mainAxisSpacing, 16);
    });

    testWidgets('renders Reports menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.reports), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
    });

    testWidgets('renders Surveys menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.surveys), findsOneWidget);
      expect(find.byIcon(Icons.poll_outlined), findsOneWidget);
    });

    testWidgets('renders Agenda menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.agenda), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('renders News menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.news), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('renders My Account menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.myAccount), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('renders Useful Info menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTextsHome.usefulInfo), findsOneWidget);
      expect(find.byIcon(Icons.info_outlined), findsOneWidget);
    });

    testWidgets('has correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final paddingFinder = find.byWidgetPredicate(
        (widget) => widget is SliverPadding && widget.padding == const EdgeInsets.all(16.0),
      );

      expect(paddingFinder, findsOneWidget);
    });

    testWidgets('has correct spacing between title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // SizedBoxes order: height 24 (before title), height 8 (between title/subtitle), height 24 (after subtitle)
      final sizedBoxes = find.byType(SizedBox);
      final SizedBox spacer1 = tester.widget(sizedBoxes.at(1));
      expect(spacer1.height, 8);
    });

    testWidgets('has correct spacing between subtitle and grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // SizedBoxes order: height 24 (before title), height 8 (between title/subtitle), height 24 (after subtitle)
      final sizedBoxes = find.byType(SizedBox);
      final SizedBox spacer2 = tester.widget(sizedBoxes.at(2));
      expect(spacer2.height, 24);
    });

    testWidgets('menu cards are tappable', (WidgetTester tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: AppRoutes.surveys,
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: AppRoutes.agenda,
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: AppRoutes.news,
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: AppRoutes.usefulInfo,
            builder: (_, __) => const Scaffold(),
          ),
          GoRoute(
            path: AppRoutes.myAccount,
            builder: (_, __) => const Scaffold(),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      // Tap on the first MenuCard (Reports)
      await tester.tap(find.byType(MenuCard).first);
      await tester.pumpAndSettle();

      // No exception should be thrown - the tap is handled
    });
  });
}

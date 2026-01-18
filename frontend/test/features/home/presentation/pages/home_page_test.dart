import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/constants/texts.dart';
import 'package:frontend/features/home/presentation/pages/home_page.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';

void main() {
  group('HomePage', () {
    testWidgets('renders title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Verify title is rendered
      expect(find.text(AppTexts.homeTitle), findsOneWidget);

      // Verify subtitle is rendered
      expect(find.text(AppTexts.homeSubtitle), findsOneWidget);
    });

    testWidgets('title has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final titleFinder = find.text(AppTexts.homeTitle);
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

      final subtitleFinder = find.text(AppTexts.homeSubtitle);
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

      // Verify GridView exists
      expect(find.byType(GridView), findsOneWidget);

      // Verify 6 MenuCards are rendered
      expect(find.byType(MenuCard), findsNWidgets(6));
    });

    testWidgets('GridView has correct configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final gridViewFinder = find.byType(GridView);
      final GridView gridView = tester.widget(gridViewFinder);

      // Verify GridView.count is used with correct parameters
      expect(gridView.gridDelegate, isA<SliverGridDelegateWithFixedCrossAxisCount>());
      
      final delegate = gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
      expect(delegate.crossAxisSpacing, 16);
      expect(delegate.mainAxisSpacing, 16);
      expect(delegate.childAspectRatio, 2);
    });

    testWidgets('renders Reports menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.reports), findsOneWidget);
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
    });

    testWidgets('renders Surveys menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.surveys), findsOneWidget);
      expect(find.byIcon(Icons.poll_outlined), findsOneWidget);
    });

    testWidgets('renders Agenda menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.agenda), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('renders News menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.news), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('renders My Account menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.myAccount), findsOneWidget);
      expect(find.byIcon(Icons.account_circle_outlined), findsOneWidget);
    });

    testWidgets('renders Useful Info menu card with correct icon and title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      expect(find.text(AppTexts.usefulInfo), findsOneWidget);
      expect(find.byIcon(Icons.info_outlined), findsOneWidget);
    });

    testWidgets('has correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      final paddingFinder = find.byWidgetPredicate(
        (widget) => widget is Padding && widget.padding == const EdgeInsets.all(16.0),
      );

      expect(paddingFinder, findsOneWidget);
    });

    testWidgets('has correct spacing between title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Find SizedBox with height 8 between title and subtitle
      final sizedBoxes = find.byType(SizedBox);
      final SizedBox spacer1 = tester.widget(sizedBoxes.at(0));
      expect(spacer1.height, 8);
    });

    testWidgets('has correct spacing between subtitle and grid', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Find SizedBox with height 24 between subtitle and grid
      final sizedBoxes = find.byType(SizedBox);
      final SizedBox spacer2 = tester.widget(sizedBoxes.at(1));
      expect(spacer2.height, 24);
    });

    testWidgets('menu cards are tappable', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );

      // Tap on the first MenuCard (Reports)
      await tester.tap(find.byType(MenuCard).first);
      await tester.pumpAndSettle();

      // No exception should be thrown - the tap is handled
    });
  });
}

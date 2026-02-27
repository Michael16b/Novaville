import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/ui/widgets/base_feature_page.dart';

void main() {
  group('BaseFeaturePage', () {
    const testIcon = Icons.star;
    const testTitle = 'Test Title';
    const testDescription = 'Test Description';

    Widget createWidgetUnderTest() {
      return const MaterialApp(
        home: Scaffold(
          body: BaseFeaturePage(
            icon: testIcon,
            title: testTitle,
            description: testDescription,
          ),
        ),
      );
    }

    testWidgets('renders icon with correct properties', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final iconFinder = find.byIcon(testIcon);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.size, 80);
      expect(iconWidget.color, AppColors.primary);
    });

    testWidgets('renders title with correct style', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final titleFinder = find.text(testTitle);
      expect(titleFinder, findsOneWidget);

      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.fontSize, 24);
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
      expect(titleWidget.style?.color, AppColors.primaryText);
    });

    testWidgets('renders description with correct style', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final descriptionFinder = find.text(testDescription);
      expect(descriptionFinder, findsOneWidget);

      final descriptionWidget = tester.widget<Text>(descriptionFinder);
      expect(descriptionWidget.style?.fontSize, 16);
      expect(descriptionWidget.style?.color, AppColors.secondaryText);
    });

    testWidgets('layout is centered', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Scaffold creates a Center widget internally for the body if it's not specified otherwise?
      // No, but BaseFeaturePage uses Center.
      // However, other widgets might use Center too.
      // Let's find the Center that is the direct child of the body or the one wrapping the Column.
      
      final columnFinder = find.byType(Column);
      expect(columnFinder, findsOneWidget);

      final centerFinder = find.ancestor(
        of: columnFinder,
        matching: find.byType(Center),
      );
      expect(centerFinder, findsOneWidget);

      final columnWidget = tester.widget<Column>(columnFinder);
      expect(columnWidget.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('has correct spacing between elements', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Icon widget might use SizedBox internally? No, Icon uses RichText/Text.
      // But let's be more specific about which SizedBoxes we are looking for.
      // We expect SizedBoxes as direct children of the Column.
      
      final columnFinder = find.byType(Column);
      final column = tester.widget<Column>(columnFinder);
      
      final sizedBoxes = column.children.whereType<SizedBox>().toList();
      expect(sizedBoxes.length, 2);
      
      expect(sizedBoxes[0].height, 24);
      expect(sizedBoxes[1].height, 16);
    });
  });
}

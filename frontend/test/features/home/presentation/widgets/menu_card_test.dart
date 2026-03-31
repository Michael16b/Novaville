import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';

void main() {
  group('MenuCard', () {
    testWidgets('renders icon, title and is tappable', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);

      await tester.tap(find.byType(MenuCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('has correct Material and Container styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );

      final materialFinder = find.byWidgetPredicate(
            (widget) => widget is Material && widget.color == AppColors.primary,
      );
      expect(materialFinder, findsOneWidget);

      final Material material = tester.widget(materialFinder);
      expect(material.clipBehavior, Clip.antiAlias);
      expect(material.shape, isA<RoundedRectangleBorder>());

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is! Container) return false;
        final decoration = widget.decoration;
        if (decoration is! BoxDecoration) return false;
        return decoration.boxShadow != null && decoration.boxShadow!.isNotEmpty;
      });

      expect(containerFinder, findsOneWidget);

      final Container container = tester.widget(containerFinder);
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('icon has correct size and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.report_problem_outlined);
      final Icon icon = tester.widget(iconFinder);
      expect(icon.size, 28);
      expect(icon.color, AppColors.secondary);
    });

    testWidgets('title has correct text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Test Title');
      final Text text = tester.widget(textFinder);
      expect(text.style?.fontSize, 21);
      expect(text.style?.fontWeight, FontWeight.w700);
      expect(text.style?.color, Colors.white);
    });

    testWidgets('subtitle has correct text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Test Subtitle');
      final Text text = tester.widget(textFinder);
      expect(text.style?.fontSize, 14);
      expect(text.style?.color, Colors.white70);
    });

    testWidgets('InkWell is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('has correct layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              subtitle: 'Test Subtitle',
              onTap: () {},
            ),
          ),
        ),
      );

      final columnFinder = find.byWidgetPredicate(
            (widget) => widget is Column &&
                widget.crossAxisAlignment == CrossAxisAlignment.start,
      );
      expect(columnFinder, findsOneWidget);

      expect(find.byType(Spacer), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 18,
        ),
        findsOneWidget,
      );
    });
  });
}

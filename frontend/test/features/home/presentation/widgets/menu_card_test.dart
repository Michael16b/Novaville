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
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify icon is rendered
      expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);

      // Verify title is rendered
      expect(find.text('Test Title'), findsOneWidget);

      // Verify card is tappable
      await tester.tap(find.byType(InkWell));
      expect(tapped, isTrue);
    });

    testWidgets('has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              onTap: () {},
            ),
          ),
        ),
      );

      // Find the Card widget
      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final Card card = tester.widget(cardFinder);
      
      // Verify Card properties
      expect(card.color, AppColors.primary);
      expect(card.elevation, 8);
      expect(card.shadowColor, Colors.black.withValues(alpha: 0.3));

      // Verify shape has correct border radius
      final shape = card.shape as RoundedRectangleBorder;
      final borderRadius = shape.borderRadius as BorderRadius;
      expect(borderRadius.topLeft, const Radius.circular(30));
      expect(borderRadius.topRight, const Radius.circular(15));
      expect(borderRadius.bottomLeft, const Radius.circular(15));
      expect(borderRadius.bottomRight, const Radius.circular(50));
    });

    testWidgets('icon has correct size and color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              onTap: () {},
            ),
          ),
        ),
      );

      final iconFinder = find.byIcon(Icons.report_problem_outlined);
      final Icon icon = tester.widget(iconFinder);

      expect(icon.size, 60);
      expect(icon.color, AppColors.secondary);
    });

    testWidgets('title has correct text style', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              onTap: () {},
            ),
          ),
        ),
      );

      final textFinder = find.text('Test Title');
      final Text text = tester.widget(textFinder);

      expect(text.textAlign, TextAlign.center);
      expect(text.style?.fontSize, 32);
      expect(text.style?.fontWeight, FontWeight.w600);
      expect(text.style?.color, AppColors.white);
    });

    testWidgets('InkWell has matching border radius', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              onTap: () {},
            ),
          ),
        ),
      );

      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);

      final InkWell inkWell = tester.widget(inkWellFinder);
      final borderRadius = inkWell.borderRadius as BorderRadius;
      
      expect(borderRadius.topLeft, const Radius.circular(30));
      expect(borderRadius.topRight, const Radius.circular(15));
      expect(borderRadius.bottomLeft, const Radius.circular(15));
      expect(borderRadius.bottomRight, const Radius.circular(50));
    });

    testWidgets('has correct layout structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MenuCard(
              icon: Icons.report_problem_outlined,
              title: 'Test Title',
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify Column layout with icon and title
      final columnFinder = find.byWidgetPredicate(
        (widget) => widget is Column && widget.mainAxisAlignment == MainAxisAlignment.center,
      );
      expect(columnFinder, findsOneWidget);

      // Verify SizedBox spacing exists
      expect(find.byWidgetPredicate((widget) => widget is SizedBox && widget.height == 12), findsOneWidget);
    });
  });
}

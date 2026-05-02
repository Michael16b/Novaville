import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/features/home/presentation/widgets/menu_card.dart';

void main() {
  group('MenuCard', () {
    testWidgets(
      'Given a menu card when it is rendered and tapped then it shows its content and triggers onTap',
      (WidgetTester tester) async {
        var tapped = false;

        // Given / When
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

        // Then
        expect(find.byIcon(Icons.report_problem_outlined), findsOneWidget);
        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Subtitle'), findsOneWidget);

        await tester.tap(find.byType(MenuCard));
        await tester.pumpAndSettle();

        expect(tapped, isTrue);
      },
    );

    testWidgets(
      'Given a menu card when it is rendered then it uses the expected material and container styling',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        final materialFinder = find.byWidgetPredicate(
          (widget) => widget is Material && widget.color == AppColors.primary,
        );
        expect(materialFinder, findsOneWidget);

        final material = tester.widget(materialFinder);
        expect(material.clipBehavior, Clip.antiAlias);
        expect(material.shape, isA<RoundedRectangleBorder>());

        final containerFinder = find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          return decoration.boxShadow != null &&
              decoration.boxShadow!.isNotEmpty;
        });

        expect(containerFinder, findsOneWidget);

        final container = tester.widget(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, isNotNull);
      },
    );

    testWidgets(
      'Given a large menu card when it is rendered then the icon uses the expected size and color',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        final iconFinder = find.byIcon(Icons.report_problem_outlined);
        final icon = tester.widget(iconFinder);
        expect(icon.size, 28);
        expect(icon.color, AppColors.secondary);
      },
    );

    testWidgets(
      'Given a large menu card when it is rendered then the title uses the expected text style',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        final textFinder = find.text('Test Title');
        final text = tester.widget(textFinder);
        expect(text.style?.fontSize, 21);
        expect(text.style?.fontWeight, FontWeight.w700);
        expect(text.style?.color, Colors.white);
      },
    );

    testWidgets(
      'Given a large menu card when it is rendered then the subtitle uses the expected text style',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        final textFinder = find.text('Test Subtitle');
        final text = tester.widget(textFinder);
        expect(text.style?.fontSize, 14);
        expect(text.style?.color, Colors.white70);
      },
    );

    testWidgets(
      'Given a menu card when it is rendered then it contains an InkWell',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        expect(find.byType(InkWell), findsOneWidget);
      },
    );

    testWidgets(
      'Given a large menu card when it is rendered then it uses the expected layout structure',
      (WidgetTester tester) async {
        // Given / When
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

        // Then
        final columnFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Column &&
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
      },
    );
  });
}

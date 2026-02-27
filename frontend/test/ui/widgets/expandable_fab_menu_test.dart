import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/ui/widgets/expandable_fab_menu.dart';

void main() {
  group('ExpandableFabMenu', () {
    late bool action1Called;
    late bool action2Called;
    late List<FabMenuAction> actions;

    setUp(() {
      action1Called = false;
      action2Called = false;
      actions = [
        FabMenuAction(
          label: 'Action One',
          icon: Icons.edit,
          onPressed: () => action1Called = true,
        ),
        FabMenuAction(
          label: 'Action Two',
          icon: Icons.delete,
          onPressed: () => action2Called = true,
        ),
      ];
    });

    Widget buildWidget() {
      return MaterialApp(
        home: Scaffold(
          floatingActionButton: ExpandableFabMenu(
            actions: actions,
            heroTag: 'test-fab',
          ),
        ),
      );
    }

    testWidgets('actions are not interactive by default (collapsed)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      final ignorePointer = tester.widget<IgnorePointer>(
        find.byType(IgnorePointer).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('actions become interactive after tapping the FAB', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.byType(IgnorePointer).first,
      );
      expect(ignorePointer.ignoring, isFalse);
    });

    testWidgets('action labels are visible after expanding', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Action One'), findsOneWidget);
      expect(find.text('Action Two'), findsOneWidget);
    });

    testWidgets('tapping an action fires its callback', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Action One'));
      await tester.pumpAndSettle();

      expect(action1Called, isTrue);
      expect(action2Called, isFalse);
    });

    testWidgets('menu collapses after tapping an action', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Action Two'));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.byType(IgnorePointer).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('tapping FAB again collapses the menu', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildWidget());

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final ignorePointer = tester.widget<IgnorePointer>(
        find.byType(IgnorePointer).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });
  });
}

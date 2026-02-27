import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/design_systems/custom_text_form_field.dart';

void main() {
  group('CustomTextFormField', () {
    const testLabel = 'Test Label';
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('renders correctly with label', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFormField(
              controller: controller,
              labelText: testLabel,
            ),
          ),
        ),
      );

      expect(find.text(testLabel), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('updates controller when text is entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFormField(
              controller: controller,
              labelText: testLabel,
            ),
          ),
        ),
      );

      const inputText = 'Hello World';
      await tester.enterText(find.byType(TextFormField), inputText);
      expect(controller.text, inputText);
    });

    testWidgets('obscures text when obscureText is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFormField(
              controller: controller,
              obscureText: true,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('shows required asterisk when isRequired is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFormField(
              controller: controller,
              labelText: testLabel,
              isRequired: true,
            ),
          ),
        ),
      );

      expect(find.text(' *'), findsOneWidget);
      expect(find.text(testLabel), findsOneWidget);
    });

    testWidgets('validates input correctly', (WidgetTester tester) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: formKey,
              child: CustomTextFormField(
                controller: controller,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Field is required';
                  }
                  return null;
                },
              ),
            ),
          ),
        ),
      );

      // Trigger validation
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Field is required'), findsOneWidget);

      // Enter text and validate again
      await tester.enterText(find.byType(TextFormField), 'Valid input');
      await tester.pump(); // Rebuild to update controller
      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Field is required'), findsNothing);
    });

    testWidgets('has correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextFormField(
              controller: controller,
              labelText: testLabel,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      final decoration = textField.decoration;

      expect(decoration?.filled, isTrue);
      expect(decoration?.fillColor, AppColors.white);
      
      final border = decoration?.enabledBorder as OutlineInputBorder?;
      expect(border?.borderRadius, BorderRadius.circular(4));
    });
  });
}

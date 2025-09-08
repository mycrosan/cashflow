import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/widgets/custom_button.dart';

void main() {
  group('CustomButton Widget Tests', () {
    testWidgets('should render button with text correctly', (WidgetTester tester) async {
      // Arrange
      const buttonText = 'Test Button';
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: buttonText,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('should call onPressed when tapped', (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Test Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isTrue);
    });

    testWidgets('should not call onPressed when disabled', (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Disabled Button',
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isFalse);
    });

    testWidgets('should show loading indicator when isLoading is true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading Button'), findsNothing);
    });

    testWidgets('should render outlined button correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Outlined Button',
              outlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.text('Outlined Button'), findsOneWidget);
    });

    testWidgets('should render button with icon correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Icon Button',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('Icon Button'), findsOneWidget);
    });

    testWidgets('should apply custom colors correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Colored Button',
              backgroundColor: Colors.red,
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.style?.backgroundColor?.resolve({}), equals(Colors.red));
    });

    testWidgets('should apply custom width and height correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Custom Size Button',
              width: 200,
              height: 60,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, equals(200));
      expect(sizedBox.height, equals(60));
    });

    testWidgets('should handle disabled state with custom colors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Disabled Button',
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              onPressed: null, // Disabled
            ),
          ),
        ),
      );

      // Assert
      final elevatedButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(elevatedButton.style?.backgroundColor?.resolve({}), equals(Colors.grey[300]));
    });

    testWidgets('should not be tappable when loading', (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Loading Button',
              isLoading: true,
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isFalse);
    });

    testWidgets('should render outlined button with icon', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Outlined Icon Button',
              icon: Icons.save,
              outlined: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byIcon(Icons.save), findsOneWidget);
      expect(find.text('Outlined Icon Button'), findsOneWidget);
    });

    testWidgets('should show loading indicator in outlined button', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'Outlined Loading Button',
              outlined: true,
              isLoading: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle empty text gracefully', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: '',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text(''), findsOneWidget);
    });

    testWidgets('should maintain button state during rebuilds', (WidgetTester tester) async {
      // Arrange
      bool wasPressed = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'State Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      // Rebuild widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomButton(
              text: 'State Button',
              onPressed: () {
                wasPressed = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(wasPressed, isTrue);
    });
  });
}


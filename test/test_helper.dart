import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// Helper class for common test utilities
class TestHelper {
  /// Creates a mock with default behavior
  static T createMock<T>() {
    return Mock();
  }

  /// Waits for all animations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle();
  }

  /// Pumps widget and waits for frame
  static Future<void> pumpWidget(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(widget);
    await tester.pump();
  }

  /// Creates a test MaterialApp wrapper
  static Widget createTestApp({required Widget child}) {
    return MaterialApp(
      home: Scaffold(body: child),
    );
  }

  /// Creates a test MaterialApp with theme
  static Widget createTestAppWithTheme({
    required Widget child,
    ThemeData? theme,
  }) {
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      home: Scaffold(body: child),
    );
  }
}

/// Extension for WidgetTester to add common test utilities
extension WidgetTesterExtensions on WidgetTester {
  /// Finds a widget by type and taps it
  Future<void> tapByType<T extends Widget>() async {
    await tap(find.byType(T));
    await pump();
  }

  /// Finds a widget by text and taps it
  Future<void> tapByText(String text) async {
    await tap(find.text(text));
    await pump();
  }

  /// Enters text into a text field
  Future<void> enterTextIntoField(String text, {int index = 0}) async {
    final textField = find.byType(TextField).at(index);
    await enterText(textField, text);
    await pump();
  }

  /// Waits for all animations to complete
  Future<void> waitForAnimations() async {
    await pumpAndSettle();
  }
}

/// Mock class for testing
class Mock extends Mockito implements Mockito {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}


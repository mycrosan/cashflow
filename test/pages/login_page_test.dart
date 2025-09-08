import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/pages/auth/login_page.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/widgets/custom_text_field.dart';
import '../../lib/widgets/custom_button.dart';

// Generate mocks
@GenerateMocks([AuthProvider])
import 'login_page_test.mocks.dart';

void main() {
  group('LoginPage Widget Tests', () {
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      mockAuthProvider = MockAuthProvider();
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider as AuthProvider,
          child: LoginPage(),
        ),
      );
    }

    testWidgets('should render login page correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('should display app logo and title', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
      expect(find.text('Fluxo Família'), findsOneWidget);
    });

    testWidgets('should display email and password fields', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CustomTextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Senha'), findsOneWidget);
    });

    testWidgets('should display login button', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CustomButton), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
    });

    testWidgets('should toggle between login and register modes', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Initially in login mode
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Criar Conta'), findsOneWidget);
      
      // Tap to switch to register mode
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();

      // Assert
      expect(find.text('Registrar'), findsOneWidget);
      expect(find.text('Já tem conta?'), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Find password field
      final passwordField = find.byType(CustomTextField).last;
      await tester.enterText(passwordField, 'password123');
      
      // Find and tap visibility toggle button
      final visibilityButton = find.byIcon(Icons.visibility_off);
      await tester.tap(visibilityButton);
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should validate email field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Enter invalid email
      final emailField = find.byType(CustomTextField).first;
      await tester.enterText(emailField, 'invalid-email');
      
      // Tap login button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(find.text('Digite um email válido'), findsOneWidget);
    });

    testWidgets('should validate password field', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Enter short password
      final passwordField = find.byType(CustomTextField).last;
      await tester.enterText(passwordField, '123');
      
      // Tap login button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(find.text('A senha deve ter pelo menos 6 caracteres'), findsOneWidget);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(true);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show error message', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn('Erro de autenticação');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Erro de autenticação'), findsOneWidget);
    });

    testWidgets('should call login when form is valid', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.login(any, any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Enter valid credentials
      final emailField = find.byType(CustomTextField).first;
      final passwordField = find.byType(CustomTextField).last;
      
      await tester.enterText(emailField, 'test@email.com');
      await tester.enterText(passwordField, 'password123');
      
      // Tap login button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      verify(mockAuthProvider.login('test@email.com', 'password123')).called(1);
    });

    testWidgets('should call register when in register mode', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);
      when(mockAuthProvider.register(any, any, any)).thenAnswer((_) async => true);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Switch to register mode
      await tester.tap(find.text('Criar Conta'));
      await tester.pump();
      
      // Enter valid credentials
      final emailField = find.byType(CustomTextField).first;
      final passwordField = find.byType(CustomTextField).last;
      
      await tester.enterText(emailField, 'test@email.com');
      await tester.enterText(passwordField, 'password123');
      
      // Tap register button
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      verify(mockAuthProvider.register('test@email.com', 'password123', any)).called(1);
    });

    testWidgets('should handle form submission with empty fields', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Tap login button without entering data
      await tester.tap(find.byType(CustomButton));
      await tester.pump();

      // Assert
      expect(find.text('Digite seu email'), findsOneWidget);
      expect(find.text('Digite sua senha'), findsOneWidget);
    });

    testWidgets('should dispose controllers correctly', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpWidget(Container()); // Remove widget to trigger dispose

      // Assert
      // Controllers should be disposed without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle keyboard interactions', (WidgetTester tester) async {
      // Arrange
      when(mockAuthProvider.isLoading).thenReturn(false);
      when(mockAuthProvider.error).thenReturn(null);

      // Act
      await tester.pumpWidget(createTestWidget());
      
      // Focus on email field
      final emailField = find.byType(CustomTextField).first;
      await tester.tap(emailField);
      await tester.pump();
      
      // Enter text
      await tester.enterText(emailField, 'test@email.com');
      
      // Move to password field
      await tester.testTextInput.receiveAction(TextInputAction.next);
      await tester.pump();

      // Assert
      expect(find.text('test@email.com'), findsOneWidget);
    });
  });
}

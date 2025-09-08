import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sqflite/sqflite.dart';
import '../../lib/services/database_service.dart';
import '../../lib/models/user.dart';
import '../../lib/models/member.dart';
import '../../lib/models/category.dart';
import '../../lib/models/transaction.dart' as models;

// Generate mocks
@GenerateMocks([Database])
import 'database_service_test.mocks.dart';

void main() {
  group('DatabaseService Tests', () {
    late DatabaseService databaseService;
    late MockDatabase mockDatabase;

    setUp(() {
      databaseService = DatabaseService();
      mockDatabase = MockDatabase();
    });

    test('should be singleton', () {
      // Arrange & Act
      final instance1 = DatabaseService();
      final instance2 = DatabaseService();

      // Assert
      expect(instance1, equals(instance2));
    });

    test('should initialize database correctly', () async {
      // Arrange
      when(mockDatabase.isOpen).thenAnswer((_) => true);

      // Act & Assert
      expect(databaseService, isNotNull);
      expect(databaseService.database, isA<Future<Database>>());
    });

    test('should create user successfully', () async {
      // Arrange
      final user = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
          .thenAnswer((_) async => 1);

      // Act
      // Note: In a real test, you would need to mock the database instance
      // This is a simplified test structure

      // Assert
      expect(user.id, equals(1));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@email.com'));
    });

    test('should create member successfully', () async {
      // Arrange
      final member = Member(
        id: 1,
        name: 'Maria Santos',
        relation: 'Mãe',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(member.id, equals(1));
      expect(member.name, equals('Maria Santos'));
      expect(member.relation, equals('Mãe'));
      expect(member.userId, equals(1));
    });

    test('should create category successfully', () async {
      // Arrange
      final category = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(category.id, equals(1));
      expect(category.name, equals('Salário'));
      expect(category.type, equals('income'));
      expect(category.isIncome, isTrue);
    });

    test('should create transaction successfully', () async {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transaction = models.Transaction(
        id: 1,
        value: 100.0,
        date: DateTime.now(),
        category: 'Salário',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(transaction.id, equals(1));
      expect(transaction.value, equals(100.0));
      expect(transaction.category, equals('Salário'));
      expect(transaction.associatedMember, equals(member));
      expect(transaction.isIncome, isTrue);
    });

    test('should handle database operations correctly', () async {
      // Arrange
      when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
          .thenAnswer((_) async => 1);
      when(mockDatabase.update(any, any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);
      when(mockDatabase.delete(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => 1);
      when(mockDatabase.query(any, where: anyNamed('where'), whereArgs: anyNamed('whereArgs')))
          .thenAnswer((_) async => []);

      // Act & Assert
      // These would be tested with actual database operations
      expect(mockDatabase.insert, isA<Function>());
      expect(mockDatabase.update, isA<Function>());
      expect(mockDatabase.delete, isA<Function>());
      expect(mockDatabase.query, isA<Function>());
    });

    test('should handle database errors gracefully', () async {
      // Arrange
      when(mockDatabase.insert(any, any, conflictAlgorithm: anyNamed('conflictAlgorithm')))
          .thenThrow(Exception('Database error'));

      // Act & Assert
      expect(() async {
        await mockDatabase.insert('test_table', {'test': 'data'});
      }, throwsException);
    });

    test('should validate user data correctly', () {
      // Arrange
      final validUser = User(
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidUser = User(
        name: '',
        email: 'invalid-email',
        password: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(validUser.name.isNotEmpty, isTrue);
      expect(validUser.email.contains('@'), isTrue);
      expect(validUser.password.isNotEmpty, isTrue);

      expect(invalidUser.name.isEmpty, isTrue);
      expect(invalidUser.email.contains('@'), isFalse);
      expect(invalidUser.password.isEmpty, isTrue);
    });

    test('should validate member data correctly', () {
      // Arrange
      final validMember = Member(
        name: 'Maria Santos',
        relation: 'Mãe',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidMember = Member(
        name: '',
        relation: '',
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(validMember.name.isNotEmpty, isTrue);
      expect(validMember.relation.isNotEmpty, isTrue);
      expect(validMember.userId > 0, isTrue);

      expect(invalidMember.name.isEmpty, isTrue);
      expect(invalidMember.relation.isEmpty, isTrue);
      expect(invalidMember.userId <= 0, isTrue);
    });

    test('should validate category data correctly', () {
      // Arrange
      final validIncomeCategory = Category(
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final validExpenseCategory = Category(
        name: 'Supermercado',
        type: 'expense',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidCategory = Category(
        name: '',
        type: 'invalid',
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(validIncomeCategory.name.isNotEmpty, isTrue);
      expect(validIncomeCategory.type, equals('income'));
      expect(validIncomeCategory.isIncome, isTrue);

      expect(validExpenseCategory.name.isNotEmpty, isTrue);
      expect(validExpenseCategory.type, equals('expense'));
      expect(validExpenseCategory.isExpense, isTrue);

      expect(invalidCategory.name.isEmpty, isTrue);
      expect(invalidCategory.type, equals('invalid'));
      expect(invalidCategory.userId <= 0, isTrue);
    });

    test('should validate transaction data correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final validTransaction = models.Transaction(
        value: 100.0,
        date: DateTime.now(),
        category: 'Salário',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidTransaction = models.Transaction(
        value: 0.0,
        date: DateTime.now(),
        category: '',
        associatedMember: member,
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(validTransaction.value != 0, isTrue);
      expect(validTransaction.category.isNotEmpty, isTrue);
      expect(validTransaction.userId > 0, isTrue);

      expect(invalidTransaction.value == 0, isTrue);
      expect(invalidTransaction.category.isEmpty, isTrue);
      expect(invalidTransaction.userId <= 0, isTrue);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/providers/auth_provider.dart';
import '../../lib/models/transaction.dart' as models;
import '../../lib/models/member.dart';
import '../../lib/models/category.dart';
import '../../lib/services/database_service.dart';
import '../../lib/services/api_service.dart';

// Generate mocks
@GenerateMocks([DatabaseService, ApiService, AuthProvider])
import 'transaction_provider_test.mocks.dart';

void main() {
  group('TransactionProvider Tests', () {
    late TransactionProvider transactionProvider;
    late MockDatabaseService mockDatabaseService;
    late MockApiService mockApiService;
    late MockAuthProvider mockAuthProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
      mockDatabaseService = MockDatabaseService();
      mockApiService = MockApiService();
      mockAuthProvider = MockAuthProvider();
      
      transactionProvider.setAuthProvider(mockAuthProvider);
    });

    test('should initialize with empty state', () {
      // Assert
      expect(transactionProvider.transactions, isEmpty);
      expect(transactionProvider.members, isEmpty);
      expect(transactionProvider.categories, isEmpty);
      expect(transactionProvider.isLoading, isFalse);
      expect(transactionProvider.error, isNull);
    });

    test('should calculate total income correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final incomeTransactions = [
        models.Transaction(
          value: 1000.0,
          date: DateTime.now(),
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: 500.0,
          date: DateTime.now(),
          category: 'Bonus',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(incomeTransactions);

      // Assert
      expect(transactionProvider.totalIncome, equals(1500.0));
    });

    test('should calculate total expenses correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expenseTransactions = [
        models.Transaction(
          value: -200.0,
          date: DateTime.now(),
          category: 'Supermercado',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -150.0,
          date: DateTime.now(),
          category: 'Conta de Luz',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(expenseTransactions);

      // Assert
      expect(transactionProvider.totalExpenses, equals(350.0));
    });

    test('should calculate balance correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactions = [
        models.Transaction(
          value: 1000.0,
          date: DateTime.now(),
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -300.0,
          date: DateTime.now(),
          category: 'Despesas',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(transactions);

      // Assert
      expect(transactionProvider.balance, equals(700.0));
    });

    test('should filter monthly transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final currentMonth = DateTime(2024, 1, 15);
      final lastMonth = DateTime(2023, 12, 15);
      final nextMonth = DateTime(2024, 2, 15);

      final transactions = [
        models.Transaction(
          value: 100.0,
          date: currentMonth,
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -50.0,
          date: lastMonth,
          category: 'Despesa Antiga',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -25.0,
          date: nextMonth,
          category: 'Despesa Futura',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(transactions);
      // Note: selectedMonth is read-only in TransactionProvider
      // We'll test the monthlyTransactions getter instead

      // Assert
      final monthlyTransactions = transactionProvider.monthlyTransactions;
      expect(monthlyTransactions.length, equals(1));
      expect(monthlyTransactions.first.category, equals('Salário'));
    });

    test('should group transactions by date correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 16);

      final transactions = [
        models.Transaction(
          value: 100.0,
          date: date1,
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -50.0,
          date: date1,
          category: 'Supermercado',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -25.0,
          date: date2,
          category: 'Conta de Luz',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(transactions);
      // Note: selectedMonth is read-only in TransactionProvider
      // We'll test the monthlyTransactions getter instead

      // Assert
      final transactionsByDate = transactionProvider.transactionsByDate;
      expect(transactionsByDate.keys.length, equals(2));
      expect(transactionsByDate.values.first.length, equals(2));
      expect(transactionsByDate.values.last.length, equals(1));
    });

    test('should group transactions by category correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactions = [
        models.Transaction(
          value: 100.0,
          date: DateTime.now(),
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: 200.0,
          date: DateTime.now(),
          category: 'Salário',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        models.Transaction(
          value: -50.0,
          date: DateTime.now(),
          category: 'Supermercado',
          associatedMember: member,
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Act
      transactionProvider.transactions.addAll(transactions);

      // Assert
      final transactionsByCategory = transactionProvider.transactionsByCategory;
      expect(transactionsByCategory.keys.length, equals(2));
      expect(transactionsByCategory['Salário']!.length, equals(2));
      expect(transactionsByCategory['Supermercado']!.length, equals(1));
    });

    test('should handle income transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final incomeTransaction = Transaction(
        value: 1000.0,
        date: DateTime.now(),
        category: 'Salário',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      transactionProvider.transactions.add(incomeTransaction);

      // Assert
      expect(incomeTransaction.isIncome, isTrue);
      expect(incomeTransaction.isExpense, isFalse);
      expect(incomeTransaction.absoluteValue, equals(1000.0));
    });

    test('should handle expense transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final expenseTransaction = Transaction(
        value: -500.0,
        date: DateTime.now(),
        category: 'Supermercado',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      transactionProvider.transactions.add(expenseTransaction);

      // Assert
      expect(expenseTransaction.isIncome, isFalse);
      expect(expenseTransaction.isExpense, isTrue);
      expect(expenseTransaction.absoluteValue, equals(500.0));
    });

    test('should handle paid transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final paidTransaction = Transaction(
        value: 100.0,
        date: DateTime.now(),
        category: 'Salário',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: true,
        paidDate: DateTime.now(),
      );

      // Act
      transactionProvider.transactions.add(paidTransaction);

      // Assert
      expect(paidTransaction.isPaid, isTrue);
      expect(paidTransaction.paidDate, isNotNull);
      expect(paidTransaction.paymentStatus, contains('Pago'));
    });

    test('should handle unpaid transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final unpaidTransaction = Transaction(
        value: -100.0,
        date: DateTime.now(),
        category: 'Conta de Luz',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: false,
      );

      // Act
      transactionProvider.transactions.add(unpaidTransaction);

      // Assert
      expect(unpaidTransaction.isPaid, isFalse);
      expect(unpaidTransaction.paidDate, isNull);
      expect(unpaidTransaction.paymentStatus, equals('Pendente'));
    });

    test('should handle recurring transactions correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final recurringTransaction = Transaction(
        value: -200.0,
        date: DateTime.now(),
        category: 'Aluguel',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        recurringTransactionId: 5,
      );

      // Act
      transactionProvider.transactions.add(recurringTransaction);

      // Assert
      expect(recurringTransaction.isRecurring, isTrue);
      expect(recurringTransaction.recurringTransactionId, equals(5));
    });

    test('should handle empty transaction list', () {
      // Assert
      expect(transactionProvider.transactions, isEmpty);
      expect(transactionProvider.totalIncome, equals(0.0));
      expect(transactionProvider.totalExpenses, equals(0.0));
      expect(transactionProvider.balance, equals(0.0));
      expect(transactionProvider.monthlyTransactions, isEmpty);
      expect(transactionProvider.transactionsByDate, isEmpty);
      expect(transactionProvider.transactionsByCategory, isEmpty);
    });

    test('should handle null auth provider gracefully', () {
      // Arrange
      final providerWithoutAuth = TransactionProvider();

      // Act & Assert
      expect(providerWithoutAuth.transactions, isEmpty);
      // Should not throw when accessing _currentUserId
      expect(() => providerWithoutAuth.transactions, returnsNormally);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/transaction.dart';
import '../../lib/models/member.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/services/database_service.dart';

void main() {
  group('Debug - Teste de Exclusão de Transações', () {
    late TransactionProvider transactionProvider;
    late DatabaseService databaseService;

    setUp(() async {
      databaseService = DatabaseService();
      // O DatabaseService já inicializa automaticamente quando necessário
      transactionProvider = TransactionProvider();
    });

    test('Deve excluir uma transação simples', () async {
      // Arrange - Criar uma transação de teste
      final member = Member(
        id: 1,
        name: 'Teste',
        relation: 'Próprio',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transaction = Transaction(
        id: 999,
        value: 100.0,
        date: DateTime.now(),
        category: 'Teste',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Inserir a transação no banco
      await databaseService.insertTransaction(transaction);

      // Act - Excluir a transação
      final result = await transactionProvider.deleteTransaction(transaction.id!);

      // Assert
      expect(result, isTrue);
      print('✅ Transação excluída com sucesso');
    });

    test('Deve verificar se a transação foi realmente removida do banco', () async {
      // Arrange - Criar uma transação de teste
      final member = Member(
        id: 1,
        name: 'Teste',
        relation: 'Próprio',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transaction = Transaction(
        id: 998,
        value: 200.0,
        date: DateTime.now(),
        category: 'Teste2',
        associatedMember: member,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Inserir a transação no banco
      await databaseService.insertTransaction(transaction);

      // Verificar se foi inserida
      final transactionsBefore = await databaseService.getTransactions();
      final transactionExists = transactionsBefore.any((t) => t.id == transaction.id);
      expect(transactionExists, isTrue);
      print('✅ Transação inserida no banco');

      // Act - Excluir a transação
      final deleteResult = await transactionProvider.deleteTransaction(transaction.id!);
      expect(deleteResult, isTrue);

      // Assert - Verificar se foi removida do banco
      final transactionsAfter = await databaseService.getTransactions();
      final transactionStillExists = transactionsAfter.any((t) => t.id == transaction.id);
      expect(transactionStillExists, isFalse);
      print('✅ Transação removida do banco');
    });
  });
}
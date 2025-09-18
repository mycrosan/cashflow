import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/models/transaction.dart' as models;
import '../../lib/models/member.dart';
import '../../lib/models/user.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/services/database_service.dart';

void main() {
  group('Teste de Transações Órfãs', () {
    late DatabaseService databaseService;
    late TransactionProvider transactionProvider;
    late Member testMember;
    late User testUser;
    late DateTime baseDate;

    setUpAll(() {
      // Inicializar o sqflite_ffi para testes
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      databaseService = DatabaseService();
      transactionProvider = TransactionProvider();
      
      baseDate = DateTime(2024, 1, 15);
      
      testUser = User(
        id: 1,
        name: 'Usuário Teste',
        email: 'teste@teste.com',
        password: 'senha123',
        createdAt: baseDate,
        updatedAt: baseDate,
      );
      
      testMember = Member(
        id: 1,
        name: 'Membro Teste',
        relation: 'Próprio',
        userId: testUser.id!,
        createdAt: baseDate,
        updatedAt: baseDate,
      );
    });

    test('deve verificar se transações normais (sem recurringTransactionId) são preservadas', () async {
      // Arrange - Criar uma transação normal (sem recorrência)
      final normalTransaction = models.Transaction(
        id: 100,
        value: 150.0,
        date: baseDate,
        category: 'Alimentação',
        associatedMember: testMember,
        userId: testUser.id!,
        recurringTransactionId: null, // Transação normal, sem recorrência
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      // Inserir no banco
      await databaseService.insertTransaction(normalTransaction);
      
      // Verificar se foi inserida
      final transactionsBeforeCleanup = await databaseService.getTransactions(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        userId: testUser.id!,
      );
      
      print('Transações antes da limpeza: ${transactionsBeforeCleanup.length}');
      
      // Act - Executar o método que pode estar removendo transações incorretamente
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      // Assert - Verificar se a transação normal ainda existe
      final transactionsAfterCleanup = await databaseService.getTransactions(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        userId: testUser.id!,
      );
      
      print('Transações após limpeza: ${transactionsAfterCleanup.length}');
      
      // A transação normal deve ainda existir
      expect(transactionsAfterCleanup.length, equals(transactionsBeforeCleanup.length));
      
      final normalTransactionExists = transactionsAfterCleanup.any(
        (t) => t.id == normalTransaction.id && t.recurringTransactionId == null
      );
      
      expect(normalTransactionExists, isTrue, 
        reason: 'Transação normal sem recorrência não deveria ser removida');
    });

    test('deve verificar se transações com recurringTransactionId inexistente são removidas', () async {
      // Arrange - Criar uma transação órfã (com recurringTransactionId que não existe)
      final orphanedTransaction = models.Transaction(
        id: 101,
        value: 200.0,
        date: baseDate,
        category: 'Transporte',
        associatedMember: testMember,
        userId: testUser.id!,
        recurringTransactionId: 999, // ID que não existe
        createdAt: baseDate,
        updatedAt: baseDate,
      );

      // Inserir no banco
      await databaseService.insertTransaction(orphanedTransaction);
      
      // Verificar se foi inserida
      final transactionsBeforeCleanup = await databaseService.getTransactions(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        userId: testUser.id!,
      );
      
      print('Transações órfãs antes da limpeza: ${transactionsBeforeCleanup.length}');
      
      // Act - Executar o método de limpeza
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      // Assert - Verificar se a transação órfã foi removida
      final transactionsAfterCleanup = await databaseService.getTransactions(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        userId: testUser.id!,
      );
      
      print('Transações após limpeza de órfãs: ${transactionsAfterCleanup.length}');
      
      // A transação órfã deve ter sido removida
      final orphanedTransactionExists = transactionsAfterCleanup.any(
        (t) => t.id == orphanedTransaction.id
      );
      
      expect(orphanedTransactionExists, isFalse, 
        reason: 'Transação órfã deveria ter sido removida');
    });
  });
}
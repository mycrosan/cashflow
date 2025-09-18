import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/providers/recurring_transaction_provider.dart';

void main() {
  group('Teste de Recriação de Transações Recorrentes', () {
    late TransactionProvider transactionProvider;
    late RecurringTransactionProvider recurringProvider;

    setUpAll(() {
      // Inicializar sqflite_ffi para testes
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      // Configurar providers para teste
      transactionProvider = TransactionProvider();
      recurringProvider = RecurringTransactionProvider();
    });

    test('Deve evitar recriação de transações após refresh', () async {
      // Adicionar transação recorrente (assumindo membro ID 1 existe)
      await recurringProvider.addRecurringTransaction(
        frequency: 'monthly',
        category: 'Teste',
        value: 100.0,
        associatedMemberId: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
      );
      
      // Carregar transações para janeiro
      final january = DateTime(2024, 1, 15);
      await transactionProvider.loadTransactionsForMonthWithRecurring(january);
      
      // Contar transações iniciais
      final initialCount = transactionProvider.transactions.length;
      print('Transações iniciais: $initialCount');
      
      // Fazer refresh (que antes causava recriação)
      await transactionProvider.refresh();
      
      // Contar transações após refresh
      final afterRefreshCount = transactionProvider.transactions.length;
      print('Transações após refresh: $afterRefreshCount');
      
      // Verificar se não houve duplicação
      expect(afterRefreshCount, equals(initialCount), 
        reason: 'Refresh não deve duplicar transações recorrentes');
      
      // Fazer segundo refresh para garantir estabilidade
      await transactionProvider.refresh();
      final finalCount = transactionProvider.transactions.length;
      print('Transações após segundo refresh: $finalCount');
      
      expect(finalCount, equals(initialCount), 
        reason: 'Múltiplos refreshes não devem criar duplicatas');
    });

    test('Deve remover apenas transações órfãs reais', () async {
      // Carregar transações para fevereiro
      final february = DateTime(2024, 2, 15);
      await transactionProvider.loadTransactionsForMonthWithRecurring(february);
      
      final beforeCleanup = transactionProvider.transactions.length;
      print('Transações antes da limpeza: $beforeCleanup');
      
      // Executar limpeza de órfãs
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      final afterCleanup = transactionProvider.transactions.length;
      print('Transações após limpeza: $afterCleanup');
      
      // Como não há órfãs reais, o número deve permanecer igual
      expect(afterCleanup, equals(beforeCleanup), 
        reason: 'Limpeza não deve remover transações válidas');
    });
  });
}
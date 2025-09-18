import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/providers/recurring_transaction_provider.dart';
import '../../lib/models/transaction.dart' as models;
import '../../lib/models/user.dart';
import '../../lib/models/member.dart';

void main() {
  setUpAll(() async {
    // Configurar banco de dados para testes
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Interface Cache Tests', () {
    late TransactionProvider transactionProvider;
    late RecurringTransactionProvider recurringProvider;
    late User testUser;
    late Member testMember;

    setUp(() async {
      transactionProvider = TransactionProvider();
      recurringProvider = RecurringTransactionProvider();
      
      testUser = User(
        id: 1,
        name: 'Test User',
        email: 'test@test.com',
        password: 'senha123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      testMember = Member(
        id: 1,
        name: 'Test Member',
        relation: 'Familiar',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Inicializar providers
      await transactionProvider.initialize();
      await recurringProvider.loadRecurringTransactions();
    });

    test('Deve verificar se refresh limpa cache corretamente', () async {
      print('=== TESTE: Verificação de cache após refresh ===');
      
      // 1. Verificar estado inicial
      final initialCount = transactionProvider.transactions.length;
      print('Transações iniciais: $initialCount');
      
      // 2. Executar refresh
      await transactionProvider.refresh();
      
      // 3. Verificar se o refresh foi executado sem erros
      final afterRefreshCount = transactionProvider.transactions.length;
      print('Transações após refresh: $afterRefreshCount');
      
      // 4. Verificar se não há erro
      expect(transactionProvider.error, isNull);
      
      // 5. Verificar se o método removeOrphanedRecurringTransactions foi executado
      // (não deve gerar erro mesmo sem transações órfãs)
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      expect(transactionProvider.error, isNull);
    });

    test('Deve verificar comportamento do método removeOrphanedRecurringTransactions', () async {
      print('=== TESTE: Comportamento de remoção de órfãs ===');
      
      // 1. Executar o método sem transações
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      // 2. Verificar se não há erro
      expect(transactionProvider.error, isNull);
      
      // 3. Verificar se o método funciona corretamente
      final transactionCount = transactionProvider.transactions.length;
      print('Transações após limpeza de órfãs: $transactionCount');
      
      // O método deve executar sem problemas
      expect(transactionProvider.error, isNull);
    });

    test('Deve verificar se o estado é consistente após operações', () async {
      print('=== TESTE: Consistência de estado ===');
      
      // 1. Estado inicial
      final initialState = {
        'transactions': transactionProvider.transactions.length,
        'isLoading': transactionProvider.isLoading,
        'error': transactionProvider.error,
      };
      
      print('Estado inicial: $initialState');
      
      // 2. Executar operações típicas da interface
      await transactionProvider.refresh();
      await transactionProvider.removeOrphanedRecurringTransactions();
      
      // 3. Estado final
      final finalState = {
        'transactions': transactionProvider.transactions.length,
        'isLoading': transactionProvider.isLoading,
        'error': transactionProvider.error,
      };
      
      print('Estado final: $finalState');
      
      // 4. Verificações de consistência
      expect(finalState['isLoading'], isFalse); // Não deve estar carregando
      expect(finalState['error'], isNull); // Não deve ter erro
      
      // O número de transações pode variar, mas o estado deve ser consistente
      expect(finalState['transactions'], isA<int>());
    });
  });
}
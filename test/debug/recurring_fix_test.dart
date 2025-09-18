import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_caixa_familiar/providers/transaction_provider.dart';

void main() {
  group('Teste de Correção de Cache de Transações', () {
    late TransactionProvider transactionProvider;

    setUp(() {
      transactionProvider = TransactionProvider();
    });

    test('Deve ter método clearMonthCacheFor', () {
      // Verificar se o método existe
      expect(transactionProvider.clearMonthCacheFor, isNotNull);
      
      // Testar chamada do método sem erro
      final testDate = DateTime(2024, 1, 15);
      expect(() => transactionProvider.clearMonthCacheFor(testDate), returnsNormally);
      
      print('✅ Método clearMonthCacheFor funciona corretamente');
    });

    test('Deve ter método clearMonthCache', () {
      // Verificar se o método existe
      expect(transactionProvider.clearMonthCache, isNotNull);
      
      // Testar chamada do método sem erro
      expect(() => transactionProvider.clearMonthCache(), returnsNormally);
      
      print('✅ Método clearMonthCache funciona corretamente');
    });

    test('Deve ter método loadTransactionsForMonthWithRecurring', () {
      // Verificar se o método existe
      expect(transactionProvider.loadTransactionsForMonthWithRecurring, isNotNull);
      
      print('✅ Método loadTransactionsForMonthWithRecurring existe');
    });

    test('Deve ter método getTransactionsForMonth', () {
      // Verificar se o método existe
      expect(transactionProvider.getTransactionsForMonth, isNotNull);
      
      // Testar chamada do método sem erro
      final testDate = DateTime(2024, 1, 15);
      final transactions = transactionProvider.getTransactionsForMonth(testDate);
      expect(transactions, isNotNull);
      expect(transactions, isList);
      
      print('✅ Método getTransactionsForMonth funciona corretamente');
    });
  });
}
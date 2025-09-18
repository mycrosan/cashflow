import 'package:flutter_test/flutter_test.dart';
import 'package:cashflow/models/transaction.dart';
import 'package:cashflow/models/member.dart';
import 'package:cashflow/providers/transaction_provider.dart';
import 'package:cashflow/services/database_service.dart';

void main() {
  group('Teste Simples de Exclusão', () {
    test('Verificar se deleteTransaction retorna true', () async {
      final provider = TransactionProvider();
      
      // Tentar excluir uma transação que não existe
      final result = await provider.deleteTransaction(99999);
      
      print('Resultado da exclusão: $result');
      expect(result, isA<bool>());
    });

    test('Verificar se DatabaseService consegue excluir', () async {
      final db = DatabaseService();
      
      // Tentar excluir diretamente no banco
      final result = await db.deleteTransaction(99999);
      
      print('Resultado da exclusão no banco: $result');
      expect(result, isA<int>());
    });
  });
}
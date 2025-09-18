import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_caixa_familiar/models/transaction.dart';
import 'package:fluxo_caixa_familiar/models/member.dart';

void main() {
  group('Debug do Fluxo de Exclusão', () {
    test('Deve mostrar exatamente o que acontece durante a exclusão', () {
      print('\n🔍 INICIANDO DEBUG DO FLUXO DE EXCLUSÃO\n');
      
      // 1. Criar transação original
      final member = Member(
        id: 1,
        name: 'João',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final originalTransaction = Transaction(
        id: 123,
        value: 250.50,
        date: DateTime(2025, 9, 15),
        category: 'Alimentação',
        associatedMember: member,
        notes: 'Compras no supermercado',
        userId: 1,
        createdAt: DateTime(2025, 9, 15, 10, 30),
        updatedAt: DateTime(2025, 9, 15, 10, 30),
      );
      
      print('📝 TRANSAÇÃO ORIGINAL:');
      print('   ID: ${originalTransaction.id}');
      print('   Valor: R\$ ${originalTransaction.value}');
      print('   Categoria: ${originalTransaction.category}');
      print('   Data de criação: ${originalTransaction.createdAt}');
      print('   Data de atualização: ${originalTransaction.updatedAt}');
      print('   Data de exclusão: ${originalTransaction.deletedAt}');
      
      final originalJson = originalTransaction.toJson();
      print('\n📄 JSON ORIGINAL:');
      print('   excluido_em: ${originalJson['excluido_em']}');
      print('   atualizado_em: ${originalJson['atualizado_em']}');
      
      // 2. Simular o processo de exclusão (como no TransactionProvider)
      print('\n🗑️ SIMULANDO EXCLUSÃO...');
      final deletionTime = DateTime.now();
      
      final deletedTransaction = originalTransaction.copyWith(
        deletedAt: deletionTime,
        updatedAt: deletionTime,
      );
      
      print('\n📝 TRANSAÇÃO APÓS EXCLUSÃO:');
      print('   ID: ${deletedTransaction.id}');
      print('   Valor: R\$ ${deletedTransaction.value}');
      print('   Categoria: ${deletedTransaction.category}');
      print('   Data de criação: ${deletedTransaction.createdAt}');
      print('   Data de atualização: ${deletedTransaction.updatedAt}');
      print('   Data de exclusão: ${deletedTransaction.deletedAt}');
      
      final deletedJson = deletedTransaction.toJson();
      print('\n📄 JSON APÓS EXCLUSÃO:');
      print('   excluido_em: ${deletedJson['excluido_em']}');
      print('   atualizado_em: ${deletedJson['atualizado_em']}');
      
      // 3. Verificar se o JSON contém todos os campos necessários
      print('\n🔍 VERIFICANDO CAMPOS DO JSON:');
      final requiredFields = [
        'id', 'valor', 'data', 'categoria', 'membro_associado',
        'observacoes', 'user_id', 'criado_em', 'atualizado_em', 'excluido_em'
      ];
      
      for (final field in requiredFields) {
        final value = deletedJson[field];
        print('   $field: ${value != null ? '✅ $value' : '❌ NULL'}');
      }
      
      // 4. Simular o que seria enviado para o banco
      print('\n💾 DADOS QUE SERIAM ENVIADOS PARA O BANCO:');
      print('   UPDATE transactions SET');
      deletedJson.forEach((key, value) {
        if (value != null) {
          print('     $key = \'$value\',');
        }
      });
      print('   WHERE id = ${deletedTransaction.id};');
      
      // 5. Verificar se a data de exclusão está no formato correto
      print('\n📅 VERIFICANDO FORMATO DA DATA:');
      final excluido_em = deletedJson['excluido_em'];
      if (excluido_em != null) {
        try {
          final parsedDate = DateTime.parse(excluido_em);
          print('   ✅ Data válida: $parsedDate');
          print('   ✅ Formato ISO: $excluido_em');
        } catch (e) {
          print('   ❌ Erro ao parsear data: $e');
        }
      } else {
        print('   ❌ Campo excluido_em está NULL!');
      }
      
      print('\n✅ DEBUG CONCLUÍDO\n');
      
      // Assertions para garantir que tudo está correto
      expect(deletedTransaction.deletedAt, isNotNull);
      expect(deletedJson['excluido_em'], isNotNull);
      expect(deletedJson['excluido_em'], equals(deletionTime.toIso8601String()));
    });
  });
}
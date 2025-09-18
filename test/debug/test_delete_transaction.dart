import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_caixa_familiar/models/transaction.dart';
import 'package:fluxo_caixa_familiar/models/member.dart';

void main() {
  group('Teste de Exclusão de Transação', () {
    late Member testMember;

    setUp(() {
      testMember = Member(
        id: 1,
        name: 'Teste',
        relation: 'Familiar',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('Deve verificar se campo excluido_em está sendo mapeado corretamente no toJson', () {
      // Arrange
      final now = DateTime.now();
      final transaction = Transaction(
        id: 1,
        value: 100.0,
        date: now,
        category: 'Teste',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: now,
        updatedAt: now,
        deletedAt: now, // Simular exclusão
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['excluido_em'], isNotNull);
      expect(json['excluido_em'], equals(now.toIso8601String()));
      
      print('✅ Campo excluido_em está sendo mapeado corretamente no toJson');
      print('Valor do campo: ${json['excluido_em']}');
    });

    test('Deve verificar se campo excluido_em está sendo lido corretamente no fromJson', () {
      // Arrange
      final now = DateTime.now();
      final json = {
        'id': 1,
        'valor': 100.0,
        'data': now.toIso8601String(),
        'categoria': 'Teste',
        'membro_associado': testMember.toJson(),
        'observacoes': 'Teste',
        'user_id': 1,
        'criado_em': now.toIso8601String(),
        'atualizado_em': now.toIso8601String(),
        'excluido_em': now.toIso8601String(), // Campo de exclusão
      };

      // Act
      final transaction = Transaction.fromJson(json);

      // Assert
      expect(transaction.deletedAt, isNotNull);
      expect(transaction.deletedAt!.toIso8601String(), equals(now.toIso8601String()));
      
      print('✅ Campo excluido_em está sendo lido corretamente no fromJson');
      print('Data de exclusão lida: ${transaction.deletedAt}');
    });

    test('Deve verificar se transação sem exclusão não tem deletedAt', () {
      // Arrange
      final now = DateTime.now();
      final transaction = Transaction(
        id: 1,
        value: 100.0,
        date: now,
        category: 'Teste',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: now,
        updatedAt: now,
        // deletedAt não definido
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['excluido_em'], isNull);
      expect(transaction.deletedAt, isNull);
      
      print('✅ Transação não excluída não tem campo excluido_em');
    });

    test('Deve simular o processo de exclusão (copyWith)', () {
      // Arrange - Transação original
      final now = DateTime.now();
      final originalTransaction = Transaction(
        id: 1,
        value: 100.0,
        date: now,
        category: 'Teste',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: now,
        updatedAt: now,
      );

      // Act - Simular exclusão (como feito no TransactionProvider)
      final deletionTime = DateTime.now();
      final deletedTransaction = originalTransaction.copyWith(
        deletedAt: deletionTime,
        updatedAt: deletionTime,
      );

      // Assert
      expect(originalTransaction.deletedAt, isNull);
      expect(deletedTransaction.deletedAt, isNotNull);
      expect(deletedTransaction.deletedAt, equals(deletionTime));
      
      final json = deletedTransaction.toJson();
      expect(json['excluido_em'], isNotNull);
      expect(json['excluido_em'], equals(deletionTime.toIso8601String()));
      
      print('✅ Processo de exclusão (copyWith) funciona corretamente');
      print('Data de exclusão: ${deletedTransaction.deletedAt}');
      print('Campo no JSON: ${json['excluido_em']}');
    });
  });
}
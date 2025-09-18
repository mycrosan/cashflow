import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_caixa_familiar/models/transaction.dart';
import 'package:fluxo_caixa_familiar/models/recurring_transaction.dart';
import 'package:fluxo_caixa_familiar/models/member.dart';

void main() {
  group('Soft Delete Tests', () {
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

    test('Transaction deve incluir campo excluido_em no toJson quando deletedAt está preenchido', () {
      // Arrange
      final now = DateTime.now();
      final transaction = Transaction(
        id: 1,
        value: 100.0,
        date: now,
        category: 'Alimentação',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: now,
        updatedAt: now,
        deletedAt: now, // Simulando exclusão
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['excluido_em'], isNotNull);
      expect(json['excluido_em'], equals(now.toIso8601String()));
    });

    test('Transaction deve ter excluido_em null no toJson quando não foi excluída', () {
      // Arrange
      final now = DateTime.now();
      final transaction = Transaction(
        id: 1,
        value: 100.0,
        date: now,
        category: 'Alimentação',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: now,
        updatedAt: now,
        // deletedAt não preenchido
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['excluido_em'], isNull);
    });

    test('RecurringTransaction deve incluir campo excluido_em no toJson quando deletedAt está preenchido', () {
      // Arrange
      final now = DateTime.now();
      final recurringTransaction = RecurringTransaction(
        id: 1,
        frequency: 'monthly',
        category: 'Alimentação',
        value: 100.0,
        associatedMember: testMember,
        startDate: now,
        userId: 1,
        createdAt: now,
        updatedAt: now,
        deletedAt: now, // Simulando exclusão
      );

      // Act
      final json = recurringTransaction.toJson();

      // Assert
      expect(json['excluido_em'], isNotNull);
      expect(json['excluido_em'], equals(now.toIso8601String()));
    });

    test('RecurringTransaction deve ter excluido_em null no toJson quando não foi excluída', () {
      // Arrange
      final now = DateTime.now();
      final recurringTransaction = RecurringTransaction(
        id: 1,
        frequency: 'monthly',
        category: 'Alimentação',
        value: 100.0,
        associatedMember: testMember,
        startDate: now,
        userId: 1,
        createdAt: now,
        updatedAt: now,
        // deletedAt não preenchido
      );

      // Act
      final json = recurringTransaction.toJson();

      // Assert
      expect(json['excluido_em'], isNull);
    });

    test('Transaction fromJson deve preencher deletedAt quando excluido_em está presente', () {
      // Arrange
      final now = DateTime.now();
      final json = {
        'id': 1,
        'valor': 100.0,
        'data': now.toIso8601String(),
        'categoria': 'Alimentação',
        'responsavel_id': 1,
        'usuario_id': 1,
        'criado_em': now.toIso8601String(),
        'atualizado_em': now.toIso8601String(),
        'excluido_em': now.toIso8601String(),
      };

      // Act
      final transaction = Transaction.fromJson(json);

      // Assert
      expect(transaction.deletedAt, isNotNull);
      expect(transaction.deletedAt, equals(now));
    });

    test('RecurringTransaction fromJson deve preencher deletedAt quando excluido_em está presente', () {
      // Arrange
      final now = DateTime.now();
      final json = {
        'id': 1,
        'frequencia': 'monthly',
        'categoria': 'Alimentação',
        'valor': 100.0,
        'responsavel_id': 1,
        'data_inicio': now.toIso8601String(),
        'usuario_id': 1,
        'criado_em': now.toIso8601String(),
        'atualizado_em': now.toIso8601String(),
        'excluido_em': now.toIso8601String(),
      };

      // Act
      final recurringTransaction = RecurringTransaction.fromJson(json);

      // Assert
      expect(recurringTransaction.deletedAt, isNotNull);
      expect(recurringTransaction.deletedAt, equals(now));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:fluxo_caixa_familiar/models/transaction.dart' as models;
import 'package:fluxo_caixa_familiar/models/member.dart';

void main() {
  group('Transaction Model Tests', () {
    late Member testMember;
    late DateTime testDate;

    setUp(() {
      testMember = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      testDate = DateTime(2024, 1, 15);
    });

    test('should create transaction with required fields', () {
      // Arrange & Act
      final transaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transaction.value, equals(100.0));
      expect(transaction.date, equals(testDate));
      expect(transaction.category, equals('Salário'));
      expect(transaction.associatedMember, equals(testMember));
      expect(transaction.userId, equals(1));
      expect(transaction.isPaid, equals(false));
      expect(transaction.syncStatus, equals('synced'));
    });

    test('should create income transaction correctly', () {
      // Arrange & Act
      final transaction = models.Transaction(
        value: 2500.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transaction.isIncome, isTrue);
      expect(transaction.isExpense, isFalse);
      expect(transaction.absoluteValue, equals(2500.0));
      expect(transaction.displayColor, equals(Colors.green));
      expect(transaction.displayIcon, equals(Icons.trending_up));
    });

    test('should create expense transaction correctly', () {
      // Arrange & Act
      final transaction = models.Transaction(
        value: -150.0,
        date: testDate,
        category: 'Supermercado',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transaction.isIncome, isFalse);
      expect(transaction.isExpense, isTrue);
      expect(transaction.absoluteValue, equals(150.0));
      expect(transaction.displayColor, equals(Colors.red));
      expect(transaction.displayIcon, equals(Icons.trending_down));
    });

    test('should format currency correctly for income', () {
      // Arrange
      final transaction = models.Transaction(
        value: 1000.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final formattedValue = transaction.formattedValue;

      // Assert
      expect(formattedValue, contains('+'));
      expect(formattedValue, contains('R\$'));
      expect(formattedValue, contains('1.000,00'));
    });

    test('should format currency correctly for expense', () {
      // Arrange
      final transaction = models.Transaction(
        value: -500.0,
        date: testDate,
        category: 'Conta de Luz',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final formattedValue = transaction.formattedValue;

      // Assert
      expect(formattedValue, contains('-'));
      expect(formattedValue, contains('R\$'));
      expect(formattedValue, contains('500,00'));
    });

    test('should format date correctly', () {
      // Arrange
      final transaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Teste',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final formattedDate = transaction.formattedDate;

      // Assert
      expect(formattedDate, equals('15/01/2024'));
    });

    test('should display today correctly', () {
      // Arrange
      final today = DateTime.now();
      final transaction = models.Transaction(
        value: 100.0,
        date: today,
        category: 'Teste',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final displayDate = transaction.displayDate;

      // Assert
      expect(displayDate, equals('Hoje'));
    });

    test('should display yesterday correctly', () {
      // Arrange
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final transaction = models.Transaction(
        value: 100.0,
        date: yesterday,
        category: 'Teste',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final displayDate = transaction.displayDate;

      // Assert
      expect(displayDate, equals('Ontem'));
    });

    test('should handle payment status correctly', () {
      // Arrange
      final transaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Teste',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: true,
        paidDate: testDate,
      );

      // Act
      final paymentStatus = transaction.paymentStatus;

      // Assert
      expect(paymentStatus, contains('Pago'));
      expect(paymentStatus, contains('15/01/2024'));
    });

    test('should handle unpaid status correctly', () {
      // Arrange
      final transaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Teste',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isPaid: false,
      );

      // Act
      final paymentStatus = transaction.paymentStatus;

      // Assert
      expect(paymentStatus, equals('Pendente'));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'valor': 100.0,
        'data': '2024-01-15T00:00:00.000Z',
        'categoria': 'Salário',
        'responsavel': {
          'id': 1,
          'nome': 'João Silva',
          'relacao': 'Pai',
          'usuario_id': 1,
          'criado_em': '2024-01-01T00:00:00.000Z',
          'atualizado_em': '2024-01-01T00:00:00.000Z',
        },
        'observacoes': 'Teste',
        'pago': 1,
        'data_pagamento': '2024-01-15T00:00:00.000Z',
        'usuario_id': 1,
        'criado_em': '2024-01-01T00:00:00.000Z',
        'atualizado_em': '2024-01-01T00:00:00.000Z',
      };

      // Act
      final transaction = models.Transaction.fromJson(json);

      // Assert
      expect(transaction.id, equals(1));
      expect(transaction.value, equals(100.0));
      expect(transaction.category, equals('Salário'));
      expect(transaction.notes, equals('Teste'));
      expect(transaction.isPaid, isTrue);
      expect(transaction.userId, equals(1));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final transaction = models.Transaction(
        id: 1,
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        notes: 'Teste',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final json = transaction.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['valor'], equals(100.0));
      expect(json['categoria'], equals('Salário'));
      expect(json['observacoes'], equals('Teste'));
      expect(json['pago'], equals(0));
      expect(json['usuario_id'], equals(1));
    });

    test('should copy with new values correctly', () {
      // Arrange
      final originalTransaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final copiedTransaction = originalTransaction.copyWith(
        value: 200.0,
        category: 'Bonus',
        isPaid: true,
      );

      // Assert
      expect(copiedTransaction.value, equals(200.0));
      expect(copiedTransaction.category, equals('Bonus'));
      expect(copiedTransaction.isPaid, isTrue);
      expect(copiedTransaction.date, equals(testDate));
      expect(copiedTransaction.associatedMember, equals(testMember));
    });

    test('should handle equality correctly', () {
      // Arrange
      final transaction1 = models.Transaction(
        id: 1,
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transaction2 = models.Transaction(
        id: 1,
        value: 200.0, // Different value
        date: testDate,
        category: 'Bonus', // Different category
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transaction3 = models.Transaction(
        id: 2, // Different ID
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transaction1 == transaction2, isTrue); // Same ID and userId
      expect(transaction1 == transaction3, isFalse); // Different ID
    });

    test('should handle recurring transaction correctly', () {
      // Arrange
      final transaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        recurringTransactionId: 5,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transaction.isRecurring, isTrue);
      expect(transaction.recurringTransactionId, equals(5));
    });

    test('should handle receipt image correctly', () {
      // Arrange
      final transactionWithReceipt = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        receiptImage: 'path/to/image.jpg',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final transactionWithoutReceipt = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(transactionWithReceipt.hasReceipt, isTrue);
      expect(transactionWithoutReceipt.hasReceipt, isFalse);
    });

    test('should handle sync status correctly', () {
      // Arrange
      final syncedTransaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        syncStatus: 'synced',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final pendingTransaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        syncStatus: 'pending',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final conflictTransaction = models.Transaction(
        value: 100.0,
        date: testDate,
        category: 'Salário',
        associatedMember: testMember,
        syncStatus: 'conflict',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Assert
      expect(syncedTransaction.isSynced, isTrue);
      expect(pendingTransaction.isPending, isTrue);
      expect(conflictTransaction.hasConflict, isTrue);
    });
  });
}

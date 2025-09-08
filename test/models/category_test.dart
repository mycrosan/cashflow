import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/category.dart';

void main() {
  group('Category Model Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
    });

    test('should create income category correctly', () {
      // Arrange & Act
      final category = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        icon: 'work',
        color: '#4CAF50',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(category.id, equals(1));
      expect(category.name, equals('Salário'));
      expect(category.type, equals('income'));
      expect(category.icon, equals('work'));
      expect(category.color, equals('#4CAF50'));
      expect(category.userId, equals(1));
      expect(category.isIncome, isTrue);
      expect(category.isExpense, isFalse);
    });

    test('should create expense category correctly', () {
      // Arrange & Act
      final category = Category(
        id: 2,
        name: 'Supermercado',
        type: 'expense',
        icon: 'shopping_cart',
        color: '#F44336',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(category.id, equals(2));
      expect(category.name, equals('Supermercado'));
      expect(category.type, equals('expense'));
      expect(category.icon, equals('shopping_cart'));
      expect(category.color, equals('#F44336'));
      expect(category.userId, equals(1));
      expect(category.isIncome, isFalse);
      expect(category.isExpense, isTrue);
    });

    test('should create category without icon and color', () {
      // Arrange & Act
      final category = Category(
        id: 3,
        name: 'Outros',
        type: 'expense',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(category.icon, isNull);
      expect(category.color, isNull);
      expect(category.isExpense, isTrue);
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'Salário',
        'tipo': 'income',
        'icone': 'work',
        'cor': '#4CAF50',
        'usuario_id': 1,
        'criado_em': '2024-01-15T00:00:00.000Z',
        'atualizado_em': '2024-01-15T00:00:00.000Z',
      };

      // Act
      final category = Category.fromJson(json);

      // Assert
      expect(category.id, equals(1));
      expect(category.name, equals('Salário'));
      expect(category.type, equals('income'));
      expect(category.icon, equals('work'));
      expect(category.color, equals('#4CAF50'));
      expect(category.userId, equals(1));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final category = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        icon: 'work',
        color: '#4CAF50',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final json = category.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['nome'], equals('Salário'));
      expect(json['tipo'], equals('income'));
      expect(json['icone'], equals('work'));
      expect(json['cor'], equals('#4CAF50'));
      expect(json['usuario_id'], equals(1));
      expect(json['criado_em'], equals(testDate.toIso8601String()));
      expect(json['atualizado_em'], equals(testDate.toIso8601String()));
    });

    test('should copy with new values correctly', () {
      // Arrange
      final originalCategory = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final copiedCategory = originalCategory.copyWith(
        name: 'Salário + Bonus',
        icon: 'work',
        color: '#2E7D32',
      );

      // Assert
      expect(copiedCategory.name, equals('Salário + Bonus'));
      expect(copiedCategory.icon, equals('work'));
      expect(copiedCategory.color, equals('#2E7D32'));
      expect(copiedCategory.id, equals(1));
      expect(copiedCategory.type, equals('income'));
    });

    test('should handle equality correctly', () {
      // Arrange
      final category1 = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final category2 = Category(
        id: 1,
        name: 'Supermercado', // Different name
        type: 'expense', // Different type
        userId: 2, // Different userId
        createdAt: testDate,
        updatedAt: testDate,
      );

      final category3 = Category(
        id: 2, // Different ID
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(category1 == category2, isTrue); // Same ID
      expect(category1 == category3, isFalse); // Different ID
    });

    test('should handle toString correctly', () {
      // Arrange
      final category = Category(
        id: 1,
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final stringRepresentation = category.toString();

      // Assert
      expect(stringRepresentation, contains('Category'));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('name: Salário'));
      expect(stringRepresentation, contains('type: income'));
    });

    test('should parse color correctly', () {
      // Arrange
      final categoryWithColor = Category(
        name: 'Teste',
        type: 'income',
        color: '#4CAF50',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final categoryWithoutColor = Category(
        name: 'Teste',
        type: 'expense',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final categoryWithInvalidColor = Category(
        name: 'Teste',
        type: 'income',
        color: 'invalid_color',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final color1 = categoryWithColor.displayColor;
      final color2 = categoryWithoutColor.displayColor;
      final color3 = categoryWithInvalidColor.displayColor;

      // Assert
      expect(color1, isA<Color>());
      expect(color2, equals(Colors.red)); // Default for expense
      expect(color3, equals(Colors.green)); // Default for income when color parsing fails
    });

    test('should return default icons correctly', () {
      // Arrange
      final incomeCategory = Category(
        name: 'Salário',
        type: 'income',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final expenseCategory = Category(
        name: 'Supermercado',
        type: 'expense',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final incomeIcon = incomeCategory.displayIcon;
      final expenseIcon = expenseCategory.displayIcon;

      // Assert
      expect(incomeIcon, equals(Icons.trending_up));
      expect(expenseIcon, equals(Icons.trending_down));
    });

    test('should handle null values in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'Salário',
        'tipo': 'income',
        'icone': null,
        'cor': null,
        'usuario_id': null,
        'criado_em': '2024-01-15T00:00:00.000Z',
        'atualizado_em': '2024-01-15T00:00:00.000Z',
      };

      // Act
      final category = Category.fromJson(json);

      // Assert
      expect(category.id, equals(1));
      expect(category.name, equals('Salário'));
      expect(category.type, equals('income'));
      expect(category.icon, isNull);
      expect(category.color, isNull);
      expect(category.userId, equals(0)); // Default value
    });
  });
}


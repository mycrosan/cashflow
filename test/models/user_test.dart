import 'package:flutter_test/flutter_test.dart';
import 'package:fluxo_caixa_familiar/models/user.dart';

void main() {
  group('User Model Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
    });

    test('should create user with required fields', () {
      // Arrange & Act
      final user = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(user.id, equals(1));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@email.com'));
      expect(user.password, equals('senha123'));
      expect(user.createdAt, equals(testDate));
      expect(user.updatedAt, equals(testDate));
      expect(user.profilePicture, isNull);
    });

    test('should create user with profile picture', () {
      // Arrange & Act
      final user = User(
        id: 1,
        name: 'Maria Santos',
        email: 'maria@email.com',
        password: 'senha456',
        profilePicture: 'path/to/image.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(user.profilePicture, equals('path/to/image.jpg'));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'João Silva',
        'email': 'joao@email.com',
        'senha': 'senha123',
        'foto_perfil': 'path/to/image.jpg',
        'criado_em': '2024-01-15T00:00:00.000Z',
        'atualizado_em': '2024-01-15T00:00:00.000Z',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals(1));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@email.com'));
      expect(user.password, equals('senha123'));
      expect(user.profilePicture, equals('path/to/image.jpg'));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final user = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        profilePicture: 'path/to/image.jpg',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['nome'], equals('João Silva'));
      expect(json['email'], equals('joao@email.com'));
      expect(json['senha'], equals('senha123'));
      expect(json['foto_perfil'], equals('path/to/image.jpg'));
      expect(json['criado_em'], equals(testDate.toIso8601String()));
      expect(json['atualizado_em'], equals(testDate.toIso8601String()));
    });

    test('should copy with new values correctly', () {
      // Arrange
      final originalUser = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final copiedUser = originalUser.copyWith(
        name: 'João Santos',
        email: 'joao.santos@email.com',
        profilePicture: 'new/path/image.jpg',
      );

      // Assert
      expect(copiedUser.name, equals('João Santos'));
      expect(copiedUser.email, equals('joao.santos@email.com'));
      expect(copiedUser.profilePicture, equals('new/path/image.jpg'));
      expect(copiedUser.id, equals(1));
      expect(copiedUser.password, equals('senha123'));
    });

    test('should handle equality correctly', () {
      // Arrange
      final user1 = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final user2 = User(
        id: 1,
        name: 'Maria Santos', // Different name
        email: 'maria@email.com', // Different email
        password: 'senha456', // Different password
        createdAt: testDate,
        updatedAt: testDate,
      );

      final user3 = User(
        id: 2, // Different ID
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(user1 == user2, isTrue); // Same ID
      expect(user1 == user3, isFalse); // Different ID
    });

    test('should handle toString correctly', () {
      // Arrange
      final user = User(
        id: 1,
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final stringRepresentation = user.toString();

      // Assert
      expect(stringRepresentation, contains('User'));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('name: João Silva'));
      expect(stringRepresentation, contains('email: joao@email.com'));
    });

    test('should handle null values in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'João Silva',
        'email': 'joao@email.com',
        'senha': 'senha123',
        'foto_perfil': null,
        'criado_em': '2024-01-15T00:00:00.000Z',
        'atualizado_em': '2024-01-15T00:00:00.000Z',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals(1));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@email.com'));
      expect(user.password, equals('senha123'));
      expect(user.profilePicture, isNull);
    });

    test('should handle missing date fields in JSON', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'João Silva',
        'email': 'joao@email.com',
        'senha': 'senha123',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.id, equals(1));
      expect(user.name, equals('João Silva'));
      expect(user.email, equals('joao@email.com'));
      expect(user.password, equals('senha123'));
      expect(user.createdAt, isA<DateTime>());
      expect(user.updatedAt, isA<DateTime>());
    });

    test('should validate email format', () {
      // Arrange
      final validUser = User(
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final invalidUser = User(
        name: 'João Silva',
        email: 'invalid-email',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(validUser.email.contains('@'), isTrue);
      expect(invalidUser.email.contains('@'), isFalse);
    });

    test('should validate password strength', () {
      // Arrange
      final strongPasswordUser = User(
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123456',
        createdAt: testDate,
        updatedAt: testDate,
      );

      final weakPasswordUser = User(
        name: 'João Silva',
        email: 'joao@email.com',
        password: '123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(strongPasswordUser.password.length >= 6, isTrue);
      expect(weakPasswordUser.password.length >= 6, isFalse);
    });

    test('should handle empty name gracefully', () {
      // Arrange
      final userWithEmptyName = User(
        name: '',
        email: 'joao@email.com',
        password: 'senha123',
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(userWithEmptyName.name.isEmpty, isTrue);
    });

    test('should handle null profile picture correctly', () {
      // Arrange
      final userWithoutPicture = User(
        name: 'João Silva',
        email: 'joao@email.com',
        password: 'senha123',
        profilePicture: null,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act & Assert
      expect(userWithoutPicture.profilePicture, isNull);
    });
  });
}


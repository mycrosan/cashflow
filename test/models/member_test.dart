import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../lib/models/member.dart';

void main() {
  group('Member Model Tests', () {
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 15);
    });

    test('should create member with required fields', () {
      // Arrange & Act
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(member.id, equals(1));
      expect(member.name, equals('João Silva'));
      expect(member.relation, equals('Pai'));
      expect(member.userId, equals(1));
      expect(member.createdAt, equals(testDate));
      expect(member.updatedAt, equals(testDate));
      expect(member.profilePicture, isNull);
    });

    test('should create member with profile picture', () {
      // Arrange & Act
      final member = Member(
        id: 1,
        name: 'Maria Santos',
        relation: 'Mãe',
        profilePicture: 'path/to/image.jpg',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(member.profilePicture, equals('path/to/image.jpg'));
      expect(member.hasProfilePicture, isTrue);
    });

    test('should generate initials correctly', () {
      // Arrange & Act
      final member1 = Member(
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final member2 = Member(
        name: 'Maria',
        relation: 'Mãe',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final member3 = Member(
        name: '',
        relation: 'Filho',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(member1.initials, equals('J'));
      expect(member2.initials, equals('M'));
      expect(member3.initials, equals('?'));
    });

    test('should create from JSON correctly', () {
      // Arrange
      final json = {
        'id': 1,
        'nome': 'João Silva',
        'relacao': 'Pai',
        'foto_perfil': 'path/to/image.jpg',
        'usuario_id': 1,
        'criado_em': '2024-01-15T00:00:00.000Z',
        'atualizado_em': '2024-01-15T00:00:00.000Z',
      };

      // Act
      final member = Member.fromJson(json);

      // Assert
      expect(member.id, equals(1));
      expect(member.name, equals('João Silva'));
      expect(member.relation, equals('Pai'));
      expect(member.profilePicture, equals('path/to/image.jpg'));
      expect(member.userId, equals(1));
    });

    test('should convert to JSON correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        profilePicture: 'path/to/image.jpg',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final json = member.toJson();

      // Assert
      expect(json['id'], equals(1));
      expect(json['nome'], equals('João Silva'));
      expect(json['relacao'], equals('Pai'));
      expect(json['foto_perfil'], equals('path/to/image.jpg'));
      expect(json['usuario_id'], equals(1));
      expect(json['criado_em'], equals(testDate.toIso8601String()));
      expect(json['atualizado_em'], equals(testDate.toIso8601String()));
    });

    test('should copy with new values correctly', () {
      // Arrange
      final originalMember = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final copiedMember = originalMember.copyWith(
        name: 'João Santos',
        relation: 'Avô',
        profilePicture: 'new/path/image.jpg',
      );

      // Assert
      expect(copiedMember.name, equals('João Santos'));
      expect(copiedMember.relation, equals('Avô'));
      expect(copiedMember.profilePicture, equals('new/path/image.jpg'));
      expect(copiedMember.id, equals(1));
      expect(copiedMember.userId, equals(1));
    });

    test('should handle equality correctly', () {
      // Arrange
      final member1 = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final member2 = Member(
        id: 1,
        name: 'Maria Santos', // Different name
        relation: 'Mãe', // Different relation
        userId: 2, // Different userId
        createdAt: testDate,
        updatedAt: testDate,
      );

      final member3 = Member(
        id: 2, // Different ID
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(member1 == member2, isTrue); // Same ID
      expect(member1 == member3, isFalse); // Different ID
    });

    test('should handle toString correctly', () {
      // Arrange
      final member = Member(
        id: 1,
        name: 'João Silva',
        relation: 'Pai',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Act
      final stringRepresentation = member.toString();

      // Assert
      expect(stringRepresentation, contains('Member'));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('name: João Silva'));
      expect(stringRepresentation, contains('relation: Pai'));
    });

    test('should handle profile picture correctly', () {
      // Arrange
      final memberWithPicture = Member(
        name: 'João Silva',
        relation: 'Pai',
        profilePicture: 'path/to/image.jpg',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final memberWithoutPicture = Member(
        name: 'Maria Santos',
        relation: 'Mãe',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      final memberWithEmptyPicture = Member(
        name: 'Pedro Costa',
        relation: 'Filho',
        profilePicture: '',
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(memberWithPicture.hasProfilePicture, isTrue);
      expect(memberWithoutPicture.hasProfilePicture, isFalse);
      expect(memberWithEmptyPicture.hasProfilePicture, isFalse);
    });

    test('should handle null profile picture correctly', () {
      // Arrange
      final member = Member(
        name: 'João Silva',
        relation: 'Pai',
        profilePicture: null,
        userId: 1,
        createdAt: testDate,
        updatedAt: testDate,
      );

      // Assert
      expect(member.profilePicture, isNull);
      expect(member.hasProfilePicture, isFalse);
    });
  });
}


import 'package:flutter/material.dart';
import 'member.dart';

class RecurringTransaction {
  final int? id;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final String category;
  final double value;
  final Member associatedMember;
  final DateTime startDate;
  final DateTime? endDate;
  final int? maxOccurrences;
  final int isActive;
  final String? notes;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  RecurringTransaction({
    this.id,
    required this.frequency,
    required this.category,
    required this.value,
    required this.associatedMember,
    required this.startDate,
    this.endDate,
    this.maxOccurrences,
    this.isActive = 1,
    this.notes,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory RecurringTransaction.fromJson(Map<String, dynamic> json) {
    return RecurringTransaction(
      id: json['id'] as int?,
      frequency: json['frequencia'] as String,
      category: json['categoria'] as String,
      value: (json['valor'] ?? 0.0).toDouble(),
      associatedMember: json['responsavel'] != null 
        ? Member.fromJson(json['responsavel'])
        : Member(
            id: json['responsavel_id'] ?? 0,
            name: 'Responsável',
            relation: 'Familiar',
            userId: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
      startDate: json['data_inicio'] is String 
        ? DateTime.parse(json['data_inicio'])
        : DateTime.now(),
      endDate: json['data_fim'] != null 
        ? DateTime.parse(json['data_fim'])
        : null,
      maxOccurrences: json['max_ocorrencias'] as int?,
      isActive: json['ativo'] as int? ?? 1,
      notes: json['observacoes'] as String?,
      userId: json['usuario_id'] ?? 0,
      createdAt: json['criado_em'] is String 
        ? DateTime.parse(json['criado_em'])
        : DateTime.now(),
      updatedAt: json['atualizado_em'] is String 
        ? DateTime.parse(json['atualizado_em'])
        : DateTime.now(),
      deletedAt: json['excluido_em'] != null 
        ? DateTime.parse(json['excluido_em'])
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frequencia': frequency,
      'categoria': category,
      'valor': value,
      'responsavel_id': associatedMember.id,
      'data_inicio': startDate.toIso8601String(),
      'data_fim': endDate?.toIso8601String(),
      'max_ocorrencias': maxOccurrences,
      'ativo': isActive,
      'observacoes': notes,
      'usuario_id': userId,
      'criado_em': createdAt.toIso8601String(),
      'atualizado_em': updatedAt.toIso8601String(),
      'excluido_em': deletedAt?.toIso8601String(),
    };
  }

  RecurringTransaction copyWith({
    int? id,
    String? frequency,
    String? category,
    double? value,
    Member? associatedMember,
    DateTime? startDate,
    DateTime? endDate,
    int? maxOccurrences,
    int? isActive,
    String? notes,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return RecurringTransaction(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      category: category ?? this.category,
      value: value ?? this.value,
      associatedMember: associatedMember ?? this.associatedMember,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      maxOccurrences: maxOccurrences ?? this.maxOccurrences,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RecurringTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'RecurringTransaction(id: $id, frequency: $frequency, value: $value)';
  }

  // Getters úteis
  String get frequencyLabel {
    switch (frequency) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'yearly':
        return 'Anual';
      default:
        return frequency;
    }
  }

  bool get isIncome => value > 0;
  bool get isExpense => value < 0;
  bool get isDeleted => deletedAt != null;
  bool get isActiveRecord => deletedAt == null;
  
  Color get displayColor {
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }

  // Calcular próxima ocorrência
  DateTime getNextOccurrence() {
    final now = DateTime.now();
    if (isActive != 1 || (endDate != null && now.isAfter(endDate!))) {
      return now;
    }

    DateTime next = startDate;
    while (next.isBefore(now)) {
      switch (frequency) {
        case 'daily':
          next = next.add(const Duration(days: 1));
          break;
        case 'weekly':
          next = next.add(const Duration(days: 7));
          break;
        case 'monthly':
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case 'yearly':
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }

    return next;
  }

  // Verificar se deve notificar
  bool shouldNotify() {
    final nextOccurrence = getNextOccurrence();
    final now = DateTime.now();
    final difference = nextOccurrence.difference(now).inDays;
    
    // Notificar 1 dia antes
    return difference <= 1 && difference >= 0;
  }
}

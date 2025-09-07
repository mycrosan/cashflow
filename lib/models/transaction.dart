import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'member.dart';

class Transaction {
  final int? id;
  final double value;
  final DateTime date;
  final String category;
  final Member associatedMember;
  final String? notes;
  final String? receiptImage;
  final int? recurringTransactionId;
  final String syncStatus; // 'synced', 'pending', 'conflict'
  final bool isPaid;
  final DateTime? paidDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    this.id,
    required this.value,
    required this.date,
    required this.category,
    required this.associatedMember,
    this.notes,
    this.receiptImage,
    this.recurringTransactionId,
    this.syncStatus = 'synced',
    this.isPaid = false,
    this.paidDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as int?,
      value: (json['valor'] ?? 0.0).toDouble(),
      date: json['data'] is String 
        ? DateTime.parse(json['data'])
        : DateTime.now(),
      category: json['categoria'] ?? '',
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
      notes: json['observacoes'],
      receiptImage: json['imagem_recibo'],
      recurringTransactionId: json['recorrencia_id'],
      syncStatus: json['status_sincronizacao'] ?? 'synced',
      isPaid: json['pago'] == 1 || json['pago'] == true,
      paidDate: json['data_pagamento'] != null 
        ? DateTime.parse(json['data_pagamento'])
        : null,
      createdAt: json['criado_em'] is String 
        ? DateTime.parse(json['criado_em'])
        : DateTime.now(),
      updatedAt: json['atualizado_em'] is String 
        ? DateTime.parse(json['atualizado_em'])
        : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valor': value,
      'data': date.toIso8601String(),
      'categoria': category,
      'responsavel_id': associatedMember.id,
      'observacoes': notes,
      'imagem_recibo': receiptImage,
      'recorrencia_id': recurringTransactionId,
      'status_sincronizacao': syncStatus,
      'pago': isPaid ? 1 : 0,
      'data_pagamento': paidDate?.toIso8601String(),
      'criado_em': createdAt.toIso8601String(),
      'atualizado_em': updatedAt.toIso8601String(),
    };
  }

  /// Converte para formato Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'value': value,
      'date': date,
      'category': category,
      'memberId': associatedMember.id,
      'memberName': associatedMember.name,
      'notes': notes,
      'receiptImage': receiptImage,
      'recurringTransactionId': recurringTransactionId,
      'syncStatus': syncStatus,
      'isPaid': isPaid,
      'paidDate': paidDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Cria Transaction a partir de documento Firestore
  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: data['id'] as int?,
      value: (data['value'] ?? 0.0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? '',
      associatedMember: Member(
        id: data['memberId'] ?? 0,
        name: data['memberName'] ?? 'Responsável',
        relation: 'Familiar',
        userId: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      notes: data['notes'],
      receiptImage: data['receiptImage'],
      recurringTransactionId: data['recurringTransactionId'],
      syncStatus: data['syncStatus'] ?? 'synced',
      isPaid: data['isPaid'] ?? false,
      paidDate: data['paidDate'] != null 
        ? (data['paidDate'] as Timestamp).toDate()
        : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Transaction copyWith({
    int? id,
    double? value,
    DateTime? date,
    String? category,
    Member? associatedMember,
    String? notes,
    String? receiptImage,
    int? recurringTransactionId,
    String? syncStatus,
    bool? isPaid,
    DateTime? paidDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      value: value ?? this.value,
      date: date ?? this.date,
      category: category ?? this.category,
      associatedMember: associatedMember ?? this.associatedMember,
      notes: notes ?? this.notes,
      receiptImage: receiptImage ?? this.receiptImage,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      syncStatus: syncStatus ?? this.syncStatus,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Transaction(id: $id, value: $value, category: $category)';
  }

  // Getters úteis
  bool get isIncome => value > 0;
  bool get isExpense => value < 0;
  double get absoluteValue => value.abs();
  
  String get formattedValue {
    final formatter = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: 'R\$ ',
      decimalDigits: 2,
    );
    final prefix = isIncome ? '+' : '-';
    return '$prefix${formatter.format(absoluteValue)}';
  }

  String get formattedDate {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String get displayDate {
    final hoje = DateTime.now();
    final ontem = hoje.subtract(Duration(days: 1));
    
    if (date.year == hoje.year && date.month == hoje.month && date.day == hoje.day) {
      return 'Hoje';
    } else if (date.year == ontem.year && date.month == ontem.month && date.day == ontem.day) {
      return 'Ontem';
    } else if (date.year == hoje.year) {
      return DateFormat('dd/MM').format(date);
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  bool get hasReceipt => receiptImage != null && receiptImage!.isNotEmpty;
  bool get isSynced => syncStatus == 'synced';
  bool get isPending => syncStatus == 'pending';
  bool get hasConflict => syncStatus == 'conflict';
  bool get isRecurring => recurringTransactionId != null;
  bool get isUnpaid => !isPaid;
  
  String get paidDateFormatted {
    if (paidDate == null) return '';
    return DateFormat('dd/MM/yyyy').format(paidDate!);
  }
  
  String get paymentStatus {
    if (isPaid) {
      return paidDate != null ? 'Pago em ${paidDateFormatted}' : 'Pago';
    }
    return 'Pendente';
  }

  Color get displayColor {
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }
}

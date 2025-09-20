import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Disabled for build fix

class Category {
  final int? id;
  final String name;
  final String type; // 'income' ou 'expense'
  final String? icon;
  final String? color;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['nome'] as String,
      type: json['tipo'] as String,
      icon: json['icone'] as String?,
      color: json['cor'] as String?,
      userId: json['usuario_id'] ?? 0,
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
      'nome': name,
      'tipo': type,
      'icone': icon,
      'cor': color,
      'usuario_id': userId,
      'criado_em': createdAt.toIso8601String(),
      'atualizado_em': updatedAt.toIso8601String(),
    };
  }

  /// Firebase methods disabled to fix build issues
  // Map<String, dynamic> toFirestoreMap() {
  //   return {
  //     'id': id,
  //     'name': name,
  //     'type': type,
  //     'icon': icon,
  //     'color': color,
  //     'userId': userId,
  //     'createdAt': createdAt,
  //     'updatedAt': updatedAt,
  //   };
  // }

  // factory Category.fromFirestore(DocumentSnapshot doc) {
  //   final data = doc.data() as Map<String, dynamic>;
  //   return Category(
  //     id: data['id'] as int?,
  //     name: data['name'] ?? '',
  //     type: data['type'] ?? 'expense',
  //     icon: data['icon'],
  //     color: data['color'],
  //     userId: data['userId'] ?? 0,
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  //   );
  // }

  Category copyWith({
    int? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Category(id: $id, name: $name, type: $type)';
  }

  // Getters úteis
  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  
  Color get displayColor {
    if (color != null && color!.isNotEmpty) {
      try {
        return Color(int.parse(color!.replaceAll('#', '0xFF')));
      } catch (e) {
        // Se falhar, usar cor padrão
      }
    }
    return isIncome ? Colors.green : Colors.red;
  }

  IconData get displayIcon {
    if (icon != null && icon!.isNotEmpty) {
      // Aqui você pode mapear strings para IconData
      // Por enquanto, retornamos ícones padrão
    }
    return isIncome ? Icons.trending_up : Icons.trending_down;
  }
}

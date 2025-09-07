import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final int? id;
  final String name;
  final String relation;
  final String? profilePicture;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Member({
    this.id,
    required this.name,
    required this.relation,
    this.profilePicture,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      id: json['id'] as int?,
      name: json['nome'] as String,
      relation: json['relacao'] as String,
      profilePicture: json['foto_perfil'] as String?,
      userId: json['usuario_id'] as int,
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
      'relacao': relation,
      'foto_perfil': profilePicture,
      'usuario_id': userId,
      'criado_em': createdAt.toIso8601String(),
      'atualizado_em': updatedAt.toIso8601String(),
    };
  }

  /// Converte para formato Firestore
  Map<String, dynamic> toFirestoreMap() {
    return {
      'id': id,
      'name': name,
      'relation': relation,
      'profilePicture': profilePicture,
      'userId': userId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Cria Member a partir de documento Firestore
  factory Member.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Member(
      id: data['id'] as int?,
      name: data['name'] ?? '',
      relation: data['relation'] ?? '',
      profilePicture: data['profilePicture'],
      userId: data['userId'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Member copyWith({
    int? id,
    String? name,
    String? relation,
    String? profilePicture,
    int? userId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Member(
      id: id ?? this.id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      profilePicture: profilePicture ?? this.profilePicture,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Member && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Member(id: $id, name: $name, relation: $relation)';
  }

  // Getters úteis
  bool get hasProfilePicture => profilePicture != null && profilePicture!.isNotEmpty;
  String get initials => name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
}


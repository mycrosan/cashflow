import 'package:flutter/foundation.dart';

/// Modelo de dados para representar um cupom fiscal
class Receipt {
  final String? id;
  final String establishmentName;
  final String? establishmentCnpj;
  final String? establishmentAddress;
  final DateTime transactionDate;
  final double totalAmount;
  final List<ReceiptItem> items;
  final String? paymentMethod;
  final String? receiptNumber;
  final String? fiscalKey;
  final String rawText;
  final String imagePath;
  final ReceiptProcessingStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Receipt({
    this.id,
    required this.establishmentName,
    this.establishmentCnpj,
    this.establishmentAddress,
    required this.transactionDate,
    required this.totalAmount,
    required this.items,
    this.paymentMethod,
    this.receiptNumber,
    this.fiscalKey,
    required this.rawText,
    required this.imagePath,
    this.status = ReceiptProcessingStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Cria uma instância a partir de um Map JSON
  factory Receipt.fromJson(Map<String, dynamic> json) {
    return Receipt(
      id: json['id'] as String?,
      establishmentName: json['establishment_name'] as String? ?? '',
      establishmentCnpj: json['establishment_cnpj'] as String?,
      establishmentAddress: json['establishment_address'] as String?,
      transactionDate: json['transaction_date'] is String
          ? DateTime.parse(json['transaction_date'])
          : DateTime.now(),
      totalAmount: (json['total_amount'] ?? 0.0).toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ReceiptItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      paymentMethod: json['payment_method'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      fiscalKey: json['fiscal_key'] as String?,
      rawText: json['raw_text'] as String? ?? '',
      imagePath: json['image_path'] as String? ?? '',
      status: ReceiptProcessingStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ReceiptProcessingStatus.pending,
      ),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] is String
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  /// Converte para Map JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'establishment_name': establishmentName,
      'establishment_cnpj': establishmentCnpj,
      'establishment_address': establishmentAddress,
      'transaction_date': transactionDate.toIso8601String(),
      'total_amount': totalAmount,
      'items': items.map((item) => item.toJson()).toList(),
      'payment_method': paymentMethod,
      'receipt_number': receiptNumber,
      'fiscal_key': fiscalKey,
      'raw_text': rawText,
      'image_path': imagePath,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Cria uma cópia com campos atualizados
  Receipt copyWith({
    String? id,
    String? establishmentName,
    String? establishmentCnpj,
    String? establishmentAddress,
    DateTime? transactionDate,
    double? totalAmount,
    List<ReceiptItem>? items,
    String? paymentMethod,
    String? receiptNumber,
    String? fiscalKey,
    String? rawText,
    String? imagePath,
    ReceiptProcessingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Receipt(
      id: id ?? this.id,
      establishmentName: establishmentName ?? this.establishmentName,
      establishmentCnpj: establishmentCnpj ?? this.establishmentCnpj,
      establishmentAddress: establishmentAddress ?? this.establishmentAddress,
      transactionDate: transactionDate ?? this.transactionDate,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      fiscalKey: fiscalKey ?? this.fiscalKey,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Receipt &&
        other.id == id &&
        other.establishmentName == establishmentName &&
        other.establishmentCnpj == establishmentCnpj &&
        other.establishmentAddress == establishmentAddress &&
        other.transactionDate == transactionDate &&
        other.totalAmount == totalAmount &&
        listEquals(other.items, items) &&
        other.paymentMethod == paymentMethod &&
        other.receiptNumber == receiptNumber &&
        other.fiscalKey == fiscalKey &&
        other.rawText == rawText &&
        other.imagePath == imagePath &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      establishmentName,
      establishmentCnpj,
      establishmentAddress,
      transactionDate,
      totalAmount,
      items,
      paymentMethod,
      receiptNumber,
      fiscalKey,
      rawText,
      imagePath,
      status,
    );
  }

  @override
  String toString() {
    return 'Receipt(id: $id, establishmentName: $establishmentName, '
        'totalAmount: $totalAmount, transactionDate: $transactionDate, '
        'status: $status)';
  }
}

/// Modelo para representar um item do cupom fiscal
class ReceiptItem {
  final String name;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final String? code;
  final String? unit;

  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.code,
    this.unit,
  });

  /// Cria uma instância a partir de um Map JSON
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'] as String? ?? '',
      quantity: (json['quantity'] ?? 1.0).toDouble(),
      unitPrice: (json['unit_price'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
      code: json['code'] as String?,
      unit: json['unit'] as String?,
    );
  }

  /// Converte para Map JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'total_price': totalPrice,
      'code': code,
      'unit': unit,
    };
  }

  /// Cria uma cópia com campos atualizados
  ReceiptItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? totalPrice,
    String? code,
    String? unit,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      totalPrice: totalPrice ?? this.totalPrice,
      code: code ?? this.code,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReceiptItem &&
        other.name == name &&
        other.quantity == quantity &&
        other.unitPrice == unitPrice &&
        other.totalPrice == totalPrice &&
        other.code == code &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(name, quantity, unitPrice, totalPrice, code, unit);
  }

  @override
  String toString() {
    return 'ReceiptItem(name: $name, quantity: $quantity, '
        'unitPrice: $unitPrice, totalPrice: $totalPrice)';
  }
}

/// Status de processamento do cupom fiscal
enum ReceiptProcessingStatus {
  pending('Pendente'),
  processing('Processando'),
  completed('Concluído'),
  error('Erro'),
  manualReview('Revisão Manual');

  const ReceiptProcessingStatus(this.displayName);

  final String displayName;

  /// Retorna true se o status indica que o processamento foi bem-sucedido
  bool get isCompleted => this == ReceiptProcessingStatus.completed;

  /// Retorna true se o status indica que há um erro
  bool get hasError => this == ReceiptProcessingStatus.error;

  /// Retorna true se o status indica que está em processamento
  bool get isProcessing => this == ReceiptProcessingStatus.processing;

  /// Retorna true se o status requer intervenção manual
  bool get requiresManualReview => this == ReceiptProcessingStatus.manualReview;
}
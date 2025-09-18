import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/receipt.dart';

/// Resultado do parsing de cupom fiscal
class ReceiptParsingResult {
  final Receipt? receipt;
  final bool isSuccessful;
  final String? errorMessage;
  final double confidence;
  final List<String> warnings;

  const ReceiptParsingResult({
    this.receipt,
    required this.isSuccessful,
    this.errorMessage,
    this.confidence = 0.0,
    this.warnings = const [],
  });

  /// Cria um resultado de sucesso
  factory ReceiptParsingResult.success({
    required Receipt receipt,
    double confidence = 1.0,
    List<String> warnings = const [],
  }) {
    return ReceiptParsingResult(
      receipt: receipt,
      isSuccessful: true,
      confidence: confidence,
      warnings: warnings,
    );
  }

  /// Cria um resultado de erro
  factory ReceiptParsingResult.error(String errorMessage) {
    return ReceiptParsingResult(
      isSuccessful: false,
      errorMessage: errorMessage,
    );
  }
}

/// Serviço responsável por interpretar texto extraído de cupons fiscais
class ReceiptParserService {
  static final ReceiptParserService _instance = ReceiptParserService._internal();
  factory ReceiptParserService() => _instance;
  ReceiptParserService._internal();

  /// Padrões regex para identificar diferentes elementos do cupom
  static final Map<String, RegExp> _patterns = {
    // CNPJ: 00.000.000/0000-00
    'cnpj': RegExp(r'\d{2}\.?\d{3}\.?\d{3}\/?\d{4}-?\d{2}'),
    
    // Valores monetários: R$ 0,00 ou 0,00
    'money': RegExp(r'R?\$?\s*(\d{1,3}(?:\.\d{3})*),(\d{2})'),
    
    // Data: dd/mm/aaaa ou dd-mm-aaaa
    'date': RegExp(r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})'),
    
    // Hora: hh:mm:ss ou hh:mm
    'time': RegExp(r'(\d{1,2}):(\d{2})(?::(\d{2}))?'),
    
    // Chave fiscal: 44 dígitos
    'fiscalKey': RegExp(r'\d{44}'),
    
    // Número do cupom
    'receiptNumber': RegExp(r'(?:cupom|nfce|ecf)[\s\#\:]*(\d+)', caseSensitive: false),
    
    // Itens com quantidade e valor
    'item': RegExp(r'(\d+(?:,\d+)?)\s*([A-Z]{2,3})\s*(.+?)\s*(\d+,\d{2})', caseSensitive: false),
  };

  /// Faz o parsing do texto extraído do cupom
  Future<ReceiptParsingResult> parseReceiptText({
    required String rawText,
    required String imagePath,
  }) async {
    try {
      debugPrint('ReceiptParser: Iniciando parsing do texto');
      
      if (rawText.trim().isEmpty) {
        return ReceiptParsingResult.error('Texto vazio para parsing');
      }

      final lines = rawText.split('\n').map((line) => line.trim()).toList();
      final warnings = <String>[];
      
      // Extrai informações básicas
      final establishmentName = _extractEstablishmentName(lines);
      final cnpj = _extractCnpj(rawText);
      final address = _extractAddress(lines);
      final dateTime = _extractDateTime(rawText);
      final totalAmount = _extractTotalAmount(rawText);
      final items = _extractItems(lines);
      final paymentMethod = _extractPaymentMethod(rawText);
      final receiptNumber = _extractReceiptNumber(rawText);
      final fiscalKey = _extractFiscalKey(rawText);

      // Validações
      if (establishmentName.isEmpty) {
        warnings.add('Nome do estabelecimento não identificado');
      }
      
      if (totalAmount <= 0) {
        warnings.add('Valor total não identificado ou inválido');
      }
      
      if (items.isEmpty) {
        warnings.add('Nenhum item identificado no cupom');
      }

      // Calcula confiança baseada nos dados extraídos
      final confidence = _calculateParsingConfidence(
        establishmentName: establishmentName,
        cnpj: cnpj,
        totalAmount: totalAmount,
        items: items,
        dateTime: dateTime,
      );

      final now = DateTime.now();
      final receipt = Receipt(
        establishmentName: establishmentName.isNotEmpty 
            ? establishmentName 
            : 'Estabelecimento não identificado',
        establishmentCnpj: cnpj,
        establishmentAddress: address,
        transactionDate: dateTime ?? now,
        totalAmount: totalAmount,
        items: items,
        paymentMethod: paymentMethod,
        receiptNumber: receiptNumber,
        fiscalKey: fiscalKey,
        rawText: rawText,
        imagePath: imagePath,
        status: confidence > 0.7 
            ? ReceiptProcessingStatus.completed 
            : ReceiptProcessingStatus.manualReview,
        createdAt: now,
        updatedAt: now,
      );

      debugPrint('ReceiptParser: Parsing concluído com confiança: ${(confidence * 100).toStringAsFixed(1)}%');

      return ReceiptParsingResult.success(
        receipt: receipt,
        confidence: confidence,
        warnings: warnings,
      );

    } catch (e) {
      debugPrint('ReceiptParser: Erro durante parsing - $e');
      return ReceiptParsingResult.error('Erro ao interpretar cupom: $e');
    }
  }

  /// Extrai o nome do estabelecimento (geralmente nas primeiras linhas)
  String _extractEstablishmentName(List<String> lines) {
    for (int i = 0; i < min(5, lines.length); i++) {
      final line = lines[i].trim();
      if (line.length > 3 && 
          !_patterns['cnpj']!.hasMatch(line) &&
          !_patterns['money']!.hasMatch(line) &&
          !line.toLowerCase().contains('cupom') &&
          !line.toLowerCase().contains('fiscal')) {
        return line;
      }
    }
    return '';
  }

  /// Extrai CNPJ do texto
  String? _extractCnpj(String text) {
    final match = _patterns['cnpj']!.firstMatch(text);
    return match?.group(0);
  }

  /// Extrai endereço (linhas após o nome, antes do CNPJ)
  String? _extractAddress(List<String> lines) {
    String address = '';
    bool foundName = false;
    
    for (final line in lines) {
      if (!foundName && line.length > 3) {
        foundName = true;
        continue;
      }
      
      if (foundName && 
          !_patterns['cnpj']!.hasMatch(line) &&
          !line.toLowerCase().contains('cupom') &&
          line.length > 5) {
        address += (address.isEmpty ? '' : ', ') + line;
      }
      
      if (_patterns['cnpj']!.hasMatch(line)) break;
    }
    
    return address.isNotEmpty ? address : null;
  }

  /// Extrai data e hora da transação
  DateTime? _extractDateTime(String text) {
    final dateMatch = _patterns['date']!.firstMatch(text);
    final timeMatch = _patterns['time']!.firstMatch(text);
    
    if (dateMatch != null) {
      try {
        final day = int.parse(dateMatch.group(1)!);
        final month = int.parse(dateMatch.group(2)!);
        final year = int.parse(dateMatch.group(3)!);
        
        // Ajusta ano se for de 2 dígitos
        final fullYear = year < 100 ? 2000 + year : year;
        
        int hour = 0, minute = 0, second = 0;
        
        if (timeMatch != null) {
          hour = int.parse(timeMatch.group(1)!);
          minute = int.parse(timeMatch.group(2)!);
          if (timeMatch.group(3) != null) {
            second = int.parse(timeMatch.group(3)!);
          }
        }
        
        return DateTime(fullYear, month, day, hour, minute, second);
      } catch (e) {
        debugPrint('ReceiptParser: Erro ao parsear data - $e');
      }
    }
    
    return null;
  }

  /// Extrai valor total da compra
  double _extractTotalAmount(String text) {
    final lines = text.split('\n');
    double maxValue = 0.0;
    
    // Procura por linhas que contenham "total" e um valor
    for (final line in lines) {
      if (line.toLowerCase().contains('total')) {
        final matches = _patterns['money']!.allMatches(line);
        for (final match in matches) {
          try {
            final integerPart = match.group(1)!.replaceAll('.', '');
            final decimalPart = match.group(2)!;
            final value = double.parse('$integerPart.$decimalPart');
            if (value > maxValue) {
              maxValue = value;
            }
          } catch (e) {
            debugPrint('ReceiptParser: Erro ao parsear valor - $e');
          }
        }
      }
    }
    
    // Se não encontrou total específico, pega o maior valor encontrado
    if (maxValue == 0.0) {
      final allMatches = _patterns['money']!.allMatches(text);
      for (final match in allMatches) {
        try {
          final integerPart = match.group(1)!.replaceAll('.', '');
          final decimalPart = match.group(2)!;
          final value = double.parse('$integerPart.$decimalPart');
          if (value > maxValue) {
            maxValue = value;
          }
        } catch (e) {
          debugPrint('ReceiptParser: Erro ao parsear valor - $e');
        }
      }
    }
    
    return maxValue;
  }

  /// Extrai itens do cupom
  List<ReceiptItem> _extractItems(List<String> lines) {
    final items = <ReceiptItem>[];
    
    for (final line in lines) {
      // Tenta identificar padrões de itens
      final match = _patterns['item']!.firstMatch(line);
      if (match != null) {
        try {
          final quantity = double.parse(match.group(1)!.replaceAll(',', '.'));
          final unit = match.group(2)!;
          final name = match.group(3)!.trim();
          final totalPrice = double.parse(match.group(4)!.replaceAll(',', '.'));
          final unitPrice = totalPrice / quantity;
          
          items.add(ReceiptItem(
            name: name,
            quantity: quantity,
            unitPrice: unitPrice,
            totalPrice: totalPrice,
            unit: unit,
          ));
        } catch (e) {
          debugPrint('ReceiptParser: Erro ao parsear item - $e');
        }
      }
    }
    
    return items;
  }

  /// Extrai método de pagamento
  String? _extractPaymentMethod(String text) {
    final lowerText = text.toLowerCase();
    
    if (lowerText.contains('dinheiro')) return 'Dinheiro';
    if (lowerText.contains('débito')) return 'Cartão de Débito';
    if (lowerText.contains('crédito')) return 'Cartão de Crédito';
    if (lowerText.contains('pix')) return 'PIX';
    if (lowerText.contains('cartão')) return 'Cartão';
    
    return null;
  }

  /// Extrai número do cupom
  String? _extractReceiptNumber(String text) {
    final match = _patterns['receiptNumber']!.firstMatch(text);
    return match?.group(1);
  }

  /// Extrai chave fiscal
  String? _extractFiscalKey(String text) {
    final match = _patterns['fiscalKey']!.firstMatch(text);
    return match?.group(0);
  }

  /// Calcula confiança do parsing baseado nos dados extraídos
  double _calculateParsingConfidence({
    required String establishmentName,
    required String? cnpj,
    required double totalAmount,
    required List<ReceiptItem> items,
    required DateTime? dateTime,
  }) {
    double confidence = 0.0;
    
    // Nome do estabelecimento (20%)
    if (establishmentName.isNotEmpty) confidence += 0.2;
    
    // CNPJ (15%)
    if (cnpj != null && cnpj.isNotEmpty) confidence += 0.15;
    
    // Valor total (25%)
    if (totalAmount > 0) confidence += 0.25;
    
    // Data/hora (15%)
    if (dateTime != null) confidence += 0.15;
    
    // Itens (25%)
    if (items.isNotEmpty) {
      confidence += 0.25 * (items.length / (items.length + 5)).clamp(0.0, 1.0);
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  /// Valida se o texto parece ser de um cupom fiscal
  bool isValidReceiptText(String text) {
    final lowerText = text.toLowerCase();
    final keywords = ['cupom', 'fiscal', 'total', 'cnpj', 'nfce'];
    final foundKeywords = keywords.where((k) => lowerText.contains(k)).length;
    
    return foundKeywords >= 2 && _patterns['money']!.hasMatch(text);
  }

  /// Obtém estatísticas do parsing
  Map<String, dynamic> getParsingStats(String text) {
    return {
      'textLength': text.length,
      'lineCount': text.split('\n').length,
      'moneyMatches': _patterns['money']!.allMatches(text).length,
      'dateMatches': _patterns['date']!.allMatches(text).length,
      'cnpjFound': _patterns['cnpj']!.hasMatch(text),
      'fiscalKeyFound': _patterns['fiscalKey']!.hasMatch(text),
      'looksLikeReceipt': isValidReceiptText(text),
    };
  }
}
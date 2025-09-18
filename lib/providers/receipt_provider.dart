import 'package:flutter/foundation.dart';
import 'dart:async';

import '../models/receipt.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../services/ocr_service.dart';
import '../services/receipt_parser_service.dart';
import 'transaction_provider.dart';

/// Provider responsável por gerenciar cupons fiscais
class ReceiptProvider extends ChangeNotifier {
  final OcrService _ocrService = OcrService();
  final ReceiptParserService _parserService = ReceiptParserService();
  
  TransactionProvider? _transactionProvider;
  
  List<Receipt> _receipts = [];
  bool _isProcessing = false;
  String? _error;
  double _processingProgress = 0.0;

  // Getters
  List<Receipt> get receipts => _receipts;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  double get processingProgress => _processingProgress;

  /// Define o provider de transações para integração
  void setTransactionProvider(TransactionProvider transactionProvider) {
    _transactionProvider = transactionProvider;
  }

  /// Processa um cupom fiscal a partir de uma imagem
  Future<Receipt?> processReceiptFromImage(String imagePath) async {
    try {
      _setProcessing(true);
      _clearError();
      _setProgress(0.0);

      // Etapa 1: Inicializar OCR (10%)
      if (!_ocrService.isInitialized) {
        await _ocrService.initialize();
      }
      _setProgress(0.1);

      // Etapa 2: Extrair texto com OCR (50%)
      debugPrint('ReceiptProvider: Extraindo texto da imagem...');
      final ocrResult = await _ocrService.extractTextWithPreprocessing(imagePath);
      
      if (!ocrResult.isSuccessful) {
        throw Exception(ocrResult.errorMessage ?? 'Erro no OCR');
      }
      _setProgress(0.5);

      // Etapa 3: Fazer parsing dos dados (80%)
      debugPrint('ReceiptProvider: Fazendo parsing dos dados...');
      final parsingResult = await _parserService.parseReceiptText(
        rawText: ocrResult.extractedText,
        imagePath: imagePath,
      );

      if (!parsingResult.isSuccessful) {
        throw Exception(parsingResult.errorMessage ?? 'Erro no parsing');
      }
      _setProgress(0.8);

      // Etapa 4: Salvar cupom (90%)
      final receipt = parsingResult.receipt!;
      await _addReceipt(receipt);
      _setProgress(0.9);

      // Etapa 5: Finalizar (100%)
      _setProgress(1.0);
      
      debugPrint('ReceiptProvider: Cupom processado com sucesso');
      return receipt;

    } catch (e) {
      debugPrint('ReceiptProvider: Erro ao processar cupom - $e');
      _setError('Erro ao processar cupom: $e');
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Converte um cupom fiscal em transação
  Future<Transaction?> convertReceiptToTransaction({
    required Receipt receipt,
    required String selectedCategory,
    required Member selectedMember,
    required int userId,
    String? notes,
  }) async {
    try {
      if (_transactionProvider == null) {
        throw Exception('Provider de transações não configurado');
      }

      final now = DateTime.now();

      // Cria a transação baseada no cupom
      final transaction = Transaction(
        value: -receipt.totalAmount, // Negativo pois é uma despesa
        date: receipt.transactionDate,
        category: selectedCategory,
        notes: notes ?? 
            'Compra em ${receipt.establishmentName}${receipt.items.isNotEmpty ? ' - ${receipt.items.length} itens' : ''}',
        associatedMember: selectedMember,
        receiptImage: receipt.imagePath, // Vincula à imagem do cupom
        userId: userId,
        createdAt: now,
        updatedAt: now,
      );

      // Adiciona a transação usando o provider existente
      await _transactionProvider!.addTransaction(transaction);

      // Atualiza o status do cupom
      final updatedReceipt = receipt.copyWith(
        status: ReceiptProcessingStatus.completed,
        updatedAt: DateTime.now(),
      );
      
      await _updateReceipt(updatedReceipt);

      debugPrint('ReceiptProvider: Transação criada com sucesso');
      return transaction;

    } catch (e) {
      debugPrint('ReceiptProvider: Erro ao converter cupom em transação - $e');
      _setError('Erro ao criar transação: $e');
      return null;
    }
  }

  /// Adiciona um cupom à lista
  Future<void> _addReceipt(Receipt receipt) async {
    _receipts.add(receipt);
    _sortReceipts();
    notifyListeners();
  }

  /// Atualiza um cupom existente
  Future<void> _updateReceipt(Receipt receipt) async {
    final index = _receipts.indexWhere((r) => r.id == receipt.id);
    if (index != -1) {
      _receipts[index] = receipt;
      notifyListeners();
    }
  }

  /// Remove um cupom
  Future<void> removeReceipt(String receiptId) async {
    try {
      _receipts.removeWhere((r) => r.id == receiptId);
      notifyListeners();
      debugPrint('ReceiptProvider: Cupom removido');
    } catch (e) {
      debugPrint('ReceiptProvider: Erro ao remover cupom - $e');
      _setError('Erro ao remover cupom: $e');
    }
  }

  /// Ordena cupons por data (mais recente primeiro)
  void _sortReceipts() {
    _receipts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Obtém cupons por status
  List<Receipt> getReceiptsByStatus(ReceiptProcessingStatus status) {
    return _receipts.where((r) => r.status == status).toList();
  }

  /// Obtém cupons pendentes de revisão
  List<Receipt> get pendingReviewReceipts {
    return getReceiptsByStatus(ReceiptProcessingStatus.manualReview);
  }

  /// Obtém cupons processados com sucesso
  List<Receipt> get completedReceipts {
    return getReceiptsByStatus(ReceiptProcessingStatus.completed);
  }

  /// Obtém cupoms com erro
  List<Receipt> get errorReceipts {
    return getReceiptsByStatus(ReceiptProcessingStatus.error);
  }

  /// Obtém estatísticas dos cupons
  Map<String, dynamic> getReceiptStats() {
    final total = _receipts.length;
    final completed = completedReceipts.length;
    final pending = pendingReviewReceipts.length;
    final errors = errorReceipts.length;
    
    final totalAmount = _receipts.fold<double>(
      0.0, 
      (sum, receipt) => sum + receipt.totalAmount,
    );

    return {
      'total': total,
      'completed': completed,
      'pending': pending,
      'errors': errors,
      'totalAmount': totalAmount,
      'successRate': total > 0 ? (completed / total * 100).toStringAsFixed(1) : '0.0',
    };
  }

  /// Reprocessa um cupom com erro
  Future<Receipt?> reprocessReceipt(Receipt receipt) async {
    try {
      _setProcessing(true);
      _clearError();

      // Tenta processar novamente
      final result = await processReceiptFromImage(receipt.imagePath);
      
      if (result != null) {
        // Remove o cupom antigo e adiciona o novo
        await removeReceipt(receipt.id!);
        return result;
      }
      
      return null;
    } catch (e) {
      debugPrint('ReceiptProvider: Erro ao reprocessar cupom - $e');
      _setError('Erro ao reprocessar cupom: $e');
      return null;
    } finally {
      _setProcessing(false);
    }
  }

  /// Valida se uma imagem pode ser processada
  Future<bool> validateImage(String imagePath) async {
    try {
      return await _ocrService.hasReadableText(imagePath);
    } catch (e) {
      debugPrint('ReceiptProvider: Erro ao validar imagem - $e');
      return false;
    }
  }

  /// Obtém capacidades do OCR
  Map<String, dynamic> getOcrCapabilities() {
    return _ocrService.getCapabilities();
  }

  /// Limpa todos os cupons
  void clearReceipts() {
    _receipts.clear();
    notifyListeners();
  }

  /// Define estado de processamento
  void _setProcessing(bool processing) {
    _isProcessing = processing;
    if (!processing) {
      _processingProgress = 0.0;
    }
    notifyListeners();
  }

  /// Define progresso do processamento
  void _setProgress(double progress) {
    _processingProgress = progress.clamp(0.0, 1.0);
    notifyListeners();
  }

  /// Define erro
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Limpa erro
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }
}
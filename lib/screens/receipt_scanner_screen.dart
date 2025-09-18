import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import '../models/receipt.dart';
import '../models/member.dart';
import '../providers/receipt_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/member_provider.dart';
import '../widgets/receipt_processing_widget.dart';
import '../widgets/receipt_preview_widget.dart';

/// Tela para capturar e processar cupons fiscais
class ReceiptScannerScreen extends StatefulWidget {
  /// Se true, retorna os dados do cupom em vez de criar transação diretamente
  final bool returnDataOnly;
  
  const ReceiptScannerScreen({
    super.key,
    this.returnDataOnly = false,
  });

  @override
  State<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends State<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  
  Receipt? _currentReceipt;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _setupProviders();
  }

  /// Configura a integração entre providers
  void _setupProviders() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final receiptProvider = context.read<ReceiptProvider>();
      final transactionProvider = context.read<TransactionProvider>();
      receiptProvider.setTransactionProvider(transactionProvider);
    });
  }

  /// Captura imagem da câmera
  Future<void> _captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showError('Erro ao capturar imagem: $e');
    }
  }

  /// Seleciona imagem da galeria
  Future<void> _selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );
      
      if (image != null) {
        await _processImage(image.path);
      }
    } catch (e) {
      _showError('Erro ao selecionar imagem: $e');
    }
  }

  /// Processa a imagem selecionada
  Future<void> _processImage(String imagePath) async {
    final receiptProvider = context.read<ReceiptProvider>();
    
    // Valida se a imagem pode ser processada
    final isValid = await receiptProvider.validateImage(imagePath);
    if (!isValid) {
      _showError('A imagem não contém texto legível. Tente uma foto mais nítida.');
      return;
    }

    // Processa o cupom
    final receipt = await receiptProvider.processReceiptFromImage(imagePath);
    
    if (receipt != null) {
      setState(() {
        _currentReceipt = receipt;
        _errorMessage = null;
      });
    } else {
      _showError(receiptProvider.error ?? 'Erro desconhecido ao processar cupom');
    }
  }

  /// Confirma e cria transação a partir do cupom
  Future<void> _confirmAndCreateTransaction({
    required Receipt receipt,
    required String category,
    required Member member,
    String? notes,
  }) async {
    final receiptProvider = context.read<ReceiptProvider>();
    
    // TODO: Obter userId do contexto de autenticação
    const int userId = 1; // Placeholder - deve vir do contexto de auth
    
    final transaction = await receiptProvider.convertReceiptToTransaction(
      receipt: receipt,
      selectedCategory: category,
      selectedMember: member,
      userId: userId,
      notes: notes,
    );

    if (transaction != null) {
      // Sucesso - volta para tela anterior
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transação criada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      _showError(receiptProvider.error ?? 'Erro ao criar transação');
    }
  }

  /// Exibe erro
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Limpa o estado atual
  void _clearState() {
    setState(() {
      _currentReceipt = null;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Cupom Fiscal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_currentReceipt != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearState,
              tooltip: 'Limpar',
            ),
        ],
      ),
      body: Consumer<ReceiptProvider>(
        builder: (context, receiptProvider, child) {
          // Estado de processamento
           if (receiptProvider.isProcessing) {
             return ReceiptProcessingWidget(
               progress: receiptProvider.processingProgress,
             );
           }

           // Estado com cupom processado
           if (_currentReceipt != null) {
             return ReceiptPreviewWidget(
               receipt: _currentReceipt!,
               onConfirm: () {
                 if (widget.returnDataOnly) {
                   // Retorna os dados do cupom para a tela anterior
                   Navigator.of(context).pop(_currentReceipt);
                 } else {
                   // TODO: Implementar seleção de categoria e membro
                   _showError('Seleção de categoria e membro ainda não implementada');
                 }
               },
               onEdit: () {
                 // TODO: Implementar edição manual
                 _showError('Edição manual ainda não implementada');
               },
             );
           }

          // Estado inicial - seleção de imagem
          return _buildImageSelectionView();
        },
      ),
    );
  }

  /// Constrói a view de seleção de imagem
  Widget _buildImageSelectionView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone principal
          Icon(
            Icons.receipt_long,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
          ),
          const SizedBox(height: 32),
          
          // Título
          Text(
            'Escaneie seu Cupom Fiscal',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Descrição
          Text(
            'Tire uma foto ou selecione uma imagem do cupom fiscal para criar automaticamente uma transação.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          
          // Botões de ação
          Column(
            children: [
              // Botão da câmera
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _captureFromCamera,
                  icon: const Icon(Icons.camera_alt, size: 24),
                  label: const Text(
                    'Tirar Foto',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Botão da galeria
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: _selectFromGallery,
                  icon: const Icon(Icons.photo_library, size: 24),
                  label: const Text(
                    'Selecionar da Galeria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Mensagem de erro
          if (_errorMessage != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 32),
          
          // Dicas
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Dicas para melhor resultado:',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Certifique-se de que o cupom esteja bem iluminado\n'
                  '• Mantenha a câmera estável e focada\n'
                  '• Evite reflexos e sombras no papel\n'
                  '• Capture todo o cupom na imagem',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Espaçamento seguro na parte inferior
          SizedBox(height: MediaQuery.of(context).padding.bottom + 24),
        ],
      ),
    );
  }
}
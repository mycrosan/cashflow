import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado do processamento OCR
class OcrResult {
  final String extractedText;
  final bool isSuccessful;
  final String? errorMessage;
  final double confidence;
  final List<TextBlock> textBlocks;

  const OcrResult({
    required this.extractedText,
    required this.isSuccessful,
    this.errorMessage,
    this.confidence = 0.0,
    this.textBlocks = const [],
  });

  /// Cria um resultado de sucesso
  factory OcrResult.success({
    required String text,
    double confidence = 1.0,
    List<TextBlock> textBlocks = const [],
  }) {
    return OcrResult(
      extractedText: text,
      isSuccessful: true,
      confidence: confidence,
      textBlocks: textBlocks,
    );
  }

  /// Cria um resultado de erro
  factory OcrResult.error(String errorMessage) {
    return OcrResult(
      extractedText: '',
      isSuccessful: false,
      errorMessage: errorMessage,
    );
  }
}

/// Serviço responsável por extrair texto de imagens usando OCR
class OcrService {
  static final OcrService _instance = OcrService._internal();
  factory OcrService() => _instance;
  OcrService._internal();

  late final TextRecognizer _textRecognizer;
  bool _isInitialized = false;

  /// Inicializa o serviço OCR
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      _textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      _isInitialized = true;

      debugPrint('OcrService: Serviço inicializado com sucesso');
    } catch (e) {
      debugPrint('OcrService: Erro ao inicializar - $e');
      rethrow;
    }
  }

  /// Extrai texto de uma imagem
  Future<OcrResult> extractTextFromImage(String imagePath) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      if (recognizedText.text.isEmpty) {
        return OcrResult.error('Nenhum texto foi encontrado na imagem');
      }

      // Calcula confiança baseada na quantidade de texto reconhecido
      final confidence = _calculateConfidence(recognizedText);

      debugPrint('OcrService: Texto extraído com sucesso');
      debugPrint('OcrService: Confiança: ${(confidence * 100).toStringAsFixed(1)}%');

      return OcrResult.success(
        text: recognizedText.text,
        confidence: confidence,
        textBlocks: recognizedText.blocks,
      );
    } catch (e) {
      debugPrint('OcrService: Erro ao extrair texto - $e');
      return OcrResult.error('Erro ao processar imagem: $e');
    }
  }

  /// Extrai texto de múltiplas imagens
  Future<List<OcrResult>> extractTextFromMultipleImages(
    List<String> imagePaths,
  ) async {
    final results = <OcrResult>[];

    for (final imagePath in imagePaths) {
      final result = await extractTextFromImage(imagePath);
      results.add(result);
    }

    return results;
  }

  /// Verifica se uma imagem contém texto legível
  Future<bool> hasReadableText(String imagePath) async {
    try {
      final result = await extractTextFromImage(imagePath);
      return result.isSuccessful && 
             result.extractedText.trim().isNotEmpty &&
             result.confidence > 0.3;
    } catch (e) {
      debugPrint('OcrService: Erro ao verificar legibilidade - $e');
      return false;
    }
  }

  /// Extrai texto com pré-processamento da imagem
  Future<OcrResult> extractTextWithPreprocessing(String imagePath) async {
    try {
      // Verifica se o arquivo existe
      final file = File(imagePath);
      if (!await file.exists()) {
        return OcrResult.error('Arquivo de imagem não encontrado');
      }

      // Verifica o tamanho do arquivo
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) { // 10MB
        return OcrResult.error('Arquivo muito grande (máximo 10MB)');
      }

      // Extrai o texto
      final result = await extractTextFromImage(imagePath);

      // Se a confiança for baixa, tenta novamente com configurações diferentes
      if (result.isSuccessful && result.confidence < 0.5) {
        debugPrint('OcrService: Confiança baixa, tentando novamente...');
        // Aqui poderia implementar pré-processamento adicional
        // como ajuste de contraste, rotação, etc.
      }

      return result;
    } catch (e) {
      debugPrint('OcrService: Erro no pré-processamento - $e');
      return OcrResult.error('Erro no pré-processamento: $e');
    }
  }

  /// Calcula a confiança baseada na qualidade do texto reconhecido
  double _calculateConfidence(RecognizedText recognizedText) {
    if (recognizedText.blocks.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    int elementCount = 0;

    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // Considera elementos com texto válido
          if (element.text.trim().isNotEmpty) {
            // Pontuação baseada em características do texto
            double elementConfidence = 1.0;

            // Reduz confiança para textos muito curtos
            if (element.text.length < 3) {
              elementConfidence *= 0.7;
            }

            // Aumenta confiança para textos com números (comum em cupons)
            if (RegExp(r'\d').hasMatch(element.text)) {
              elementConfidence *= 1.2;
            }

            // Reduz confiança para textos com muitos caracteres especiais
            final specialCharCount = RegExp(r'[^\w\s]').allMatches(element.text).length;
            if (specialCharCount > element.text.length * 0.3) {
              elementConfidence *= 0.8;
            }

            totalConfidence += elementConfidence.clamp(0.0, 1.0);
            elementCount++;
          }
        }
      }
    }

    if (elementCount == 0) return 0.0;

    final averageConfidence = totalConfidence / elementCount;
    return averageConfidence.clamp(0.0, 1.0);
  }

  /// Libera recursos do serviço
  Future<void> dispose() async {
    try {
      if (_isInitialized) {
        await _textRecognizer.close();
        _isInitialized = false;
        debugPrint('OcrService: Recursos liberados');
      }
    } catch (e) {
      debugPrint('OcrService: Erro ao liberar recursos - $e');
    }
  }

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  /// Obtém informações sobre as capacidades do OCR
  Map<String, dynamic> getCapabilities() {
    return {
      'supportedScripts': ['latin'],
      'maxFileSize': '10MB',
      'supportedFormats': ['jpg', 'jpeg', 'png', 'bmp'],
      'isInitialized': _isInitialized,
    };
  }
}

/// Extensão para facilitar o uso do OcrService
extension OcrServiceExtension on OcrService {
  /// Método de conveniência para extrair texto rapidamente
  Future<String> quickExtractText(String imagePath) async {
    final result = await extractTextFromImage(imagePath);
    return result.isSuccessful ? result.extractedText : '';
  }

  /// Verifica se o texto extraído parece ser de um cupom fiscal
  bool looksLikeReceipt(String text) {
    final receiptKeywords = [
      'cupom',
      'fiscal',
      'cnpj',
      'total',
      'subtotal',
      'desconto',
      'pagamento',
      'dinheiro',
      'cartão',
      'débito',
      'crédito',
      'pix',
      'troco',
      'item',
      'qtd',
      'valor',
      'unid',
    ];

    final lowerText = text.toLowerCase();
    final foundKeywords = receiptKeywords
        .where((keyword) => lowerText.contains(keyword))
        .length;

    // Considera cupom fiscal se encontrar pelo menos 3 palavras-chave
    return foundKeywords >= 3;
  }
}
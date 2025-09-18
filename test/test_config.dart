/// Configuração centralizada para testes do projeto CashFlow
/// 
/// Este arquivo contém configurações, mocks e utilitários comuns
/// para facilitar a criação e manutenção de testes.

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

/// Configurações globais para testes
class TestConfig {
  /// Timeout padrão para testes assíncronos
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Configurações de mock para OCR
  static const Map<String, dynamic> mockOcrCapabilities = {
    'supportedLanguages': ['pt', 'en'],
    'maxImageSize': 10485760, // 10MB
    'supportedFormats': ['jpg', 'jpeg', 'png'],
    'confidence': 0.85,
  };
  
  /// Texto de exemplo de cupom fiscal para testes
  static const String sampleReceiptText = '''
SUPERMERCADO EXEMPLO LTDA
CNPJ: 12.345.678/0001-90
RUA DAS FLORES, 123 - CENTRO
CIDADE EXEMPLO - SP

CUPOM FISCAL

001 ARROZ INTEGRAL 1KG      R\$ 8,50
002 FEIJAO PRETO 1KG        R\$ 7,25  
003 OLEO DE SOJA 900ML      R\$ 6,75

SUBTOTAL                    R\$ 22,50
DESCONTO                    R\$ 1,00
TOTAL                       R\$ 21,50

DINHEIRO                    R\$ 25,00
TROCO                       R\$ 3,50

DATA: 15/01/2024
HORA: 14:30:25
OPERADOR: JOAO
''';

  /// Dados de exemplo para testes
  static const Map<String, dynamic> sampleReceiptData = {
    'establishmentName': 'SUPERMERCADO EXEMPLO LTDA',
    'cnpj': '12.345.678/0001-90',
    'totalAmount': 21.50,
    'items': [
      {'name': 'ARROZ INTEGRAL 1KG', 'price': 8.50, 'quantity': 1},
      {'name': 'FEIJAO PRETO 1KG', 'price': 7.25, 'quantity': 1},
      {'name': 'OLEO DE SOJA 900ML', 'price': 6.75, 'quantity': 1},
    ],
  };
  
  /// Configurações de teste para diferentes cenários
  static const Map<String, Map<String, dynamic>> testScenarios = {
    'cupom_valido': {
      'description': 'Cupom fiscal válido com todos os dados',
      'expectedSuccess': true,
      'expectedConfidence': 0.95,
    },
    'cupom_incompleto': {
      'description': 'Cupom com dados faltando',
      'expectedSuccess': false,
      'expectedConfidence': 0.3,
    },
    'imagem_ilegivel': {
      'description': 'Imagem com qualidade ruim',
      'expectedSuccess': false,
      'expectedConfidence': 0.1,
    },
  };
}

/// Utilitários para criação de dados de teste
class TestDataFactory {
  /// Cria um cupom fiscal de exemplo
  static Map<String, dynamic> createSampleReceipt({
    String? establishmentName,
    String? cnpj,
    double? totalAmount,
    DateTime? date,
    List<Map<String, dynamic>>? items,
  }) {
    return {
      'id': 'test_receipt_${DateTime.now().millisecondsSinceEpoch}',
      'establishmentName': establishmentName ?? 'Loja Teste LTDA',
      'cnpj': cnpj ?? '12.345.678/0001-90',
      'totalAmount': totalAmount ?? 100.0,
      'date': date ?? DateTime.now(),
      'items': items ?? [
        {'name': 'Produto Teste', 'price': 50.0, 'quantity': 2},
      ],
    };
  }
  
  /// Cria dados de membro para testes
  static Map<String, dynamic> createSampleMember({
    int? id,
    String? name,
    int? userId,
  }) {
    return {
      'id': id ?? 1,
      'name': name ?? 'Membro Teste',
      'userId': userId ?? 1,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
  
  /// Cria dados de transação para testes
  static Map<String, dynamic> createSampleTransaction({
    double? value,
    DateTime? date,
    String? notes,
  }) {
    return {
      'id': 'test_transaction_${DateTime.now().millisecondsSinceEpoch}',
      'value': value ?? 100.0,
      'date': date ?? DateTime.now(),
      'notes': notes ?? 'Transação de teste',
      'category': 'Alimentação',
      'userId': 1,
      'createdAt': DateTime.now(),
      'updatedAt': DateTime.now(),
    };
  }
}

/// Matchers customizados para testes
class CustomMatchers {
  /// Verifica se um valor está dentro de uma faixa de confiança
  static Matcher isWithinConfidenceRange(double min, double max) {
    return inInclusiveRange(min, max);
  }
  
  /// Verifica se uma string contém um CNPJ válido
  static Matcher containsValidCnpj() {
    return matches(r'\d{2}\.\d{3}\.\d{3}\/\d{4}-\d{2}');
  }
  
  /// Verifica se um valor monetário é válido
  static Matcher isValidMonetaryValue() {
    return allOf([
      isA<double>(),
      greaterThan(0.0),
      lessThan(999999.99),
    ]);
  }
}

/// Configurações específicas para testes de integração
class IntegrationTestConfig {
  /// Timeout para testes de integração (mais longo)
  static const Duration integrationTimeout = Duration(minutes: 2);
  
  /// Configurações de ambiente para testes
  static const Map<String, String> testEnvironment = {
    'FLUTTER_TEST': 'true',
    'TEST_MODE': 'integration',
  };
  
  /// Caminhos de arquivos de teste
  static const Map<String, String> testAssets = {
    'sample_receipt_image': 'test/assets/sample_receipt.jpg',
    'invalid_image': 'test/assets/invalid_image.txt',
    'large_image': 'test/assets/large_receipt.jpg',
  };
}

/// Configurações para testes de performance
class PerformanceTestConfig {
  /// Limites de performance aceitáveis
  static const Map<String, Duration> performanceLimits = {
    'ocr_processing': Duration(seconds: 10),
    'receipt_parsing': Duration(seconds: 2),
    'transaction_creation': Duration(seconds: 1),
  };
  
  /// Configurações de carga para testes de stress
  static const Map<String, int> loadTestConfig = {
    'concurrent_processes': 5,
    'max_receipts_batch': 10,
    'memory_limit_mb': 512,
  };
}

/// Utilitários para setup e teardown de testes
class TestUtils {
  /// Configura ambiente de teste
  static void setupTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }
  
  /// Limpa dados de teste
  static void cleanupTestData() {
    // Implementar limpeza de dados temporários
  }
  
  /// Verifica se o ambiente de teste está configurado corretamente
  static bool isTestEnvironmentReady() {
    return TestWidgetsFlutterBinding.instance != null;
  }
}
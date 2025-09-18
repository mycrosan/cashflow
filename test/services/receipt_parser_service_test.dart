import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../lib/services/receipt_parser_service.dart';
import '../../lib/models/receipt.dart';

void main() {
  group('ReceiptParserService Tests', () {
    late ReceiptParserService parserService;

    setUp(() {
      parserService = ReceiptParserService();
    });

    group('Parsing de Cupom Fiscal', () {
      test('deve parsear cupom fiscal válido com sucesso', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        
        CUPOM FISCAL
        
        PRODUTO A                 R\$ 10,50
        PRODUTO B                 R\$ 25,30
        PRODUTO C                 R\$ 8,75
        
        SUBTOTAL                  R\$ 44,55
        DESCONTO                  R\$ 2,00
        TOTAL                     R\$ 42,55
        
        DATA: 15/01/2024
        HORA: 14:30:25
        ''';

        // Act
        final result = parserService.parseReceipt(receiptText);

        // Assert
        expect(result.isSuccessful, isTrue);
        expect(result.receipt, isNotNull);
        expect(result.receipt!.establishmentName, equals('SUPERMERCADO EXEMPLO LTDA'));
        expect(result.receipt!.cnpj, equals('12.345.678/0001-90'));
        expect(result.receipt!.totalAmount, equals(42.55));
        expect(result.receipt!.items, hasLength(3));
        expect(result.receipt!.date, isNotNull);
      });

      test('deve extrair itens corretamente', () {
        // Arrange
        const receiptText = '''
        PRODUTO A                 R\$ 10,50
        PRODUTO B                 R\$ 25,30
        PRODUTO C                 R\$ 8,75
        ''';

        // Act
        final items = parserService.extractItems(receiptText);

        // Assert
        expect(items, hasLength(3));
        expect(items[0].name, equals('PRODUTO A'));
        expect(items[0].price, equals(10.50));
        expect(items[1].name, equals('PRODUTO B'));
        expect(items[1].price, equals(25.30));
        expect(items[2].name, equals('PRODUTO C'));
        expect(items[2].price, equals(8.75));
      });

      test('deve extrair valor total corretamente', () {
        // Arrange
        const receiptText = '''
        SUBTOTAL                  R\$ 44,55
        DESCONTO                  R\$ 2,00
        TOTAL                     R\$ 42,55
        ''';

        // Act
        final total = parserService.extractTotal(receiptText);

        // Assert
        expect(total, equals(42.55));
      });

      test('deve extrair data corretamente', () {
        // Arrange
        const receiptText = '''
        DATA: 15/01/2024
        HORA: 14:30:25
        ''';

        // Act
        final date = parserService.extractDate(receiptText);

        // Assert
        expect(date, isNotNull);
        expect(date!.day, equals(15));
        expect(date.month, equals(1));
        expect(date.year, equals(2024));
      });

      test('deve extrair CNPJ corretamente', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        ''';

        // Act
        final cnpj = parserService.extractCnpj(receiptText);

        // Assert
        expect(cnpj, equals('12.345.678/0001-90'));
      });

      test('deve extrair nome do estabelecimento corretamente', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        ''';

        // Act
        final name = parserService.extractEstablishmentName(receiptText);

        // Assert
        expect(name, equals('SUPERMERCADO EXEMPLO LTDA'));
      });
    });

    group('Validação de Formato', () {
      test('deve validar cupom fiscal válido', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        TOTAL                     R\$ 42,55
        DATA: 15/01/2024
        ''';

        // Act
        final isValid = parserService.isValidReceipt(receiptText);

        // Assert
        expect(isValid, isTrue);
      });

      test('deve rejeitar texto sem CNPJ', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        TOTAL                     R\$ 42,55
        DATA: 15/01/2024
        ''';

        // Act
        final isValid = parserService.isValidReceipt(receiptText);

        // Assert
        expect(isValid, isFalse);
      });

      test('deve rejeitar texto sem total', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        DATA: 15/01/2024
        ''';

        // Act
        final isValid = parserService.isValidReceipt(receiptText);

        // Assert
        expect(isValid, isFalse);
      });

      test('deve rejeitar texto vazio', () {
        // Arrange
        const receiptText = '';

        // Act
        final isValid = parserService.isValidReceipt(receiptText);

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Tratamento de Erros', () {
      test('deve retornar erro para texto inválido', () {
        // Arrange
        const receiptText = 'Texto inválido sem formato de cupom';

        // Act
        final result = parserService.parseReceipt(receiptText);

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(result.receipt, isNull);
        expect(result.errorMessage, isNotNull);
        expect(result.errorMessage, contains('formato'));
      });

      test('deve retornar erro para texto vazio', () {
        // Arrange
        const receiptText = '';

        // Act
        final result = parserService.parseReceipt(receiptText);

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(result.receipt, isNull);
        expect(result.errorMessage, contains('vazio'));
      });
    });

    group('Normalização de Dados', () {
      test('deve normalizar valores monetários', () {
        // Arrange
        const values = [
          'R\$ 10,50',
          'R\$25,30',
          '8,75',
          'R\$ 1.234,56',
        ];

        // Act & Assert
        expect(parserService.normalizeMonetaryValue(values[0]), equals(10.50));
        expect(parserService.normalizeMonetaryValue(values[1]), equals(25.30));
        expect(parserService.normalizeMonetaryValue(values[2]), equals(8.75));
        expect(parserService.normalizeMonetaryValue(values[3]), equals(1234.56));
      });

      test('deve normalizar CNPJ', () {
        // Arrange
        const cnpjValues = [
          '12.345.678/0001-90',
          '12345678000190',
          'CNPJ: 12.345.678/0001-90',
        ];

        // Act & Assert
        expect(parserService.normalizeCnpj(cnpjValues[0]), equals('12.345.678/0001-90'));
        expect(parserService.normalizeCnpj(cnpjValues[1]), equals('12.345.678/0001-90'));
        expect(parserService.normalizeCnpj(cnpjValues[2]), equals('12.345.678/0001-90'));
      });

      test('deve limpar nome do estabelecimento', () {
        // Arrange
        const names = [
          '  SUPERMERCADO EXEMPLO LTDA  ',
          'SUPERMERCADO EXEMPLO LTDA - MATRIZ',
          'SUPERMERCADO\nEXEMPLO LTDA',
        ];

        // Act & Assert
        expect(parserService.cleanEstablishmentName(names[0]), equals('SUPERMERCADO EXEMPLO LTDA'));
        expect(parserService.cleanEstablishmentName(names[1]), equals('SUPERMERCADO EXEMPLO LTDA'));
        expect(parserService.cleanEstablishmentName(names[2]), equals('SUPERMERCADO EXEMPLO LTDA'));
      });
    });

    group('Confiança do Parsing', () {
      test('deve calcular confiança alta para cupom completo', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO LTDA
        CNPJ: 12.345.678/0001-90
        
        PRODUTO A                 R\$ 10,50
        PRODUTO B                 R\$ 25,30
        
        TOTAL                     R\$ 35,80
        DATA: 15/01/2024
        HORA: 14:30:25
        ''';

        // Act
        final confidence = parserService.calculateParsingConfidence(receiptText);

        // Assert
        expect(confidence, greaterThan(0.8));
      });

      test('deve calcular confiança baixa para cupom incompleto', () {
        // Arrange
        const receiptText = '''
        SUPERMERCADO EXEMPLO
        PRODUTO A                 R\$ 10,50
        ''';

        // Act
        final confidence = parserService.calculateParsingConfidence(receiptText);

        // Assert
        expect(confidence, lessThan(0.5));
      });
    });
  });

  group('ReceiptParsingResult Tests', () {
    test('deve criar resultado de sucesso', () {
      // Arrange
      final receipt = Receipt(
        id: '1',
        establishmentName: 'Teste',
        cnpj: '12.345.678/0001-90',
        totalAmount: 100.0,
        date: DateTime.now(),
        items: [],
      );

      // Act
      final result = ReceiptParsingResult(
        isSuccessful: true,
        receipt: receipt,
        confidence: 0.95,
      );

      // Assert
      expect(result.isSuccessful, isTrue);
      expect(result.receipt, equals(receipt));
      expect(result.confidence, equals(0.95));
      expect(result.errorMessage, isNull);
    });

    test('deve criar resultado de erro', () {
      // Act
      const result = ReceiptParsingResult(
        isSuccessful: false,
        confidence: 0.0,
        errorMessage: 'Erro no parsing',
      );

      // Assert
      expect(result.isSuccessful, isFalse);
      expect(result.receipt, isNull);
      expect(result.confidence, equals(0.0));
      expect(result.errorMessage, equals('Erro no parsing'));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../lib/providers/receipt_provider.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/providers/member_provider.dart';
import '../../lib/models/receipt.dart';
import '../../lib/models/transaction.dart';
import '../../lib/models/member.dart';

void main() {
  group('Teste de Integração - Cupom Fiscal', () {
    late ReceiptProvider receiptProvider;
    late TransactionProvider transactionProvider;
    late MemberProvider memberProvider;

    setUp(() {
      // Configuração básica para testes
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Inicializa providers
      transactionProvider = TransactionProvider();
      memberProvider = MemberProvider();
      receiptProvider = ReceiptProvider();
    });

    tearDown(() {
      receiptProvider.dispose();
      transactionProvider.dispose();
      memberProvider.dispose();
    });

    group('Fluxo Completo de Processamento', () {
      testWidgets('deve processar cupom fiscal e criar transação', (WidgetTester tester) async {
        // Arrange - Simula dados de um cupom fiscal
        final mockReceipt = Receipt(
          id: 'test_receipt_1',
          establishmentName: 'Supermercado Teste LTDA',
          cnpj: '12.345.678/0001-90',
          totalAmount: 125.75,
          date: DateTime(2024, 1, 15, 14, 30),
          items: [
            ReceiptItem(
              name: 'Arroz Integral 1kg',
              price: 8.50,
              quantity: 2,
            ),
            ReceiptItem(
              name: 'Feijão Preto 1kg',
              price: 7.25,
              quantity: 1,
            ),
            ReceiptItem(
              name: 'Óleo de Soja 900ml',
              price: 6.75,
              quantity: 3,
            ),
          ],
        );

        // Simula membro disponível
        final mockMember = Member(
          id: 1,
          name: 'João Silva',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act - Simula o processamento
        receiptProvider.setLastProcessedReceipt(mockReceipt);
        
        // Verifica se o cupom foi processado
        expect(receiptProvider.lastProcessedReceipt, isNotNull);
        expect(receiptProvider.lastProcessedReceipt!.establishmentName, 
               equals('Supermercado Teste LTDA'));
        expect(receiptProvider.lastProcessedReceipt!.totalAmount, equals(125.75));
        expect(receiptProvider.lastProcessedReceipt!.items, hasLength(3));

        // Verifica conversão para transação
        final transaction = receiptProvider.convertReceiptToTransaction(
          mockReceipt,
          member: mockMember,
        );

        expect(transaction.value, equals(125.75));
        expect(transaction.date, equals(DateTime(2024, 1, 15, 14, 30)));
        expect(transaction.associatedMember, equals(mockMember));
        expect(transaction.notes, contains('Supermercado Teste LTDA'));
        expect(transaction.notes, contains('12.345.678/0001-90'));
      });

      testWidgets('deve validar dados obrigatórios do cupom', (WidgetTester tester) async {
        // Arrange - Cupom com dados incompletos
        final incompleteReceipt = Receipt(
          id: 'incomplete_receipt',
          establishmentName: '',
          cnpj: '',
          totalAmount: 0.0,
          date: DateTime.now(),
          items: [],
        );

        // Act & Assert
        expect(receiptProvider.isValidReceipt(incompleteReceipt), isFalse);
        
        // Cupom válido
        final validReceipt = Receipt(
          id: 'valid_receipt',
          establishmentName: 'Loja Teste',
          cnpj: '12.345.678/0001-90',
          totalAmount: 50.0,
          date: DateTime.now(),
          items: [
            ReceiptItem(name: 'Produto', price: 50.0),
          ],
        );

        expect(receiptProvider.isValidReceipt(validReceipt), isTrue);
      });

      testWidgets('deve calcular estatísticas de processamento', (WidgetTester tester) async {
        // Arrange
        expect(receiptProvider.totalProcessed, equals(0));
        expect(receiptProvider.successfulProcessed, equals(0));
        expect(receiptProvider.failedProcessed, equals(0));
        expect(receiptProvider.successRate, equals(0.0));

        // Act - Simula processamentos
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementFailed();

        // Assert
        expect(receiptProvider.totalProcessed, equals(3));
        expect(receiptProvider.successfulProcessed, equals(2));
        expect(receiptProvider.failedProcessed, equals(1));
        expect(receiptProvider.successRate, closeTo(0.667, 0.001)); // 66.7%
      });

      testWidgets('deve gerenciar estado de processamento', (WidgetTester tester) async {
        // Estado inicial
        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.processingProgress, equals(0.0));

        // Simula início do processamento
        receiptProvider.setProcessing(true);
        receiptProvider.updateProgress(0.5);

        expect(receiptProvider.isProcessing, isTrue);
        expect(receiptProvider.processingProgress, equals(0.5));

        // Simula fim do processamento
        receiptProvider.setProcessing(false);
        receiptProvider.updateProgress(1.0);

        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.processingProgress, equals(1.0));
      });
    });

    group('Validação de Dados', () {
      test('deve validar formato de CNPJ', () {
        // CNPJs válidos
        expect(receiptProvider.isValidCnpj('12.345.678/0001-90'), isTrue);
        expect(receiptProvider.isValidCnpj('12345678000190'), isTrue);

        // CNPJs inválidos
        expect(receiptProvider.isValidCnpj(''), isFalse);
        expect(receiptProvider.isValidCnpj('123.456.789/0001-90'), isFalse);
        expect(receiptProvider.isValidCnpj('12.345.678/0001-99'), isFalse);
      });

      test('deve validar valores monetários', () {
        // Valores válidos
        expect(receiptProvider.isValidAmount(10.50), isTrue);
        expect(receiptProvider.isValidAmount(0.01), isTrue);
        expect(receiptProvider.isValidAmount(9999.99), isTrue);

        // Valores inválidos
        expect(receiptProvider.isValidAmount(0.0), isFalse);
        expect(receiptProvider.isValidAmount(-10.0), isFalse);
      });

      test('deve validar itens do cupom', () {
        // Item válido
        final validItem = ReceiptItem(
          name: 'Produto Teste',
          price: 15.50,
          quantity: 2,
        );
        expect(receiptProvider.isValidItem(validItem), isTrue);

        // Item inválido - sem nome
        final invalidItem1 = ReceiptItem(
          name: '',
          price: 15.50,
          quantity: 1,
        );
        expect(receiptProvider.isValidItem(invalidItem1), isFalse);

        // Item inválido - preço zero
        final invalidItem2 = ReceiptItem(
          name: 'Produto',
          price: 0.0,
          quantity: 1,
        );
        expect(receiptProvider.isValidItem(invalidItem2), isFalse);
      });
    });

    group('Tratamento de Erros', () {
      testWidgets('deve tratar erro de processamento', (WidgetTester tester) async {
        // Simula erro no processamento
        receiptProvider.setProcessingError('Erro ao processar imagem');

        expect(receiptProvider.hasError, isTrue);
        expect(receiptProvider.errorMessage, equals('Erro ao processar imagem'));

        // Limpa erro
        receiptProvider.clearError();

        expect(receiptProvider.hasError, isFalse);
        expect(receiptProvider.errorMessage, isNull);
      });

      testWidgets('deve recuperar de erro e continuar processamento', (WidgetTester tester) async {
        // Simula erro
        receiptProvider.setProcessingError('Erro temporário');
        receiptProvider.incrementFailed();

        expect(receiptProvider.failedProcessed, equals(1));

        // Recupera e processa com sucesso
        receiptProvider.clearError();
        receiptProvider.incrementSuccessful();

        expect(receiptProvider.hasError, isFalse);
        expect(receiptProvider.successfulProcessed, equals(1));
        expect(receiptProvider.totalProcessed, equals(2));
      });
    });

    group('Performance e Recursos', () {
      testWidgets('deve limpar recursos adequadamente', (WidgetTester tester) async {
        // Adiciona dados
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementFailed();

        expect(receiptProvider.totalProcessed, greaterThan(0));

        // Limpa histórico
        receiptProvider.clearHistory();

        expect(receiptProvider.totalProcessed, equals(0));
        expect(receiptProvider.successfulProcessed, equals(0));
        expect(receiptProvider.failedProcessed, equals(0));
        expect(receiptProvider.processedReceipts, isEmpty);
      });

      testWidgets('deve cancelar processamento em andamento', (WidgetTester tester) async {
        // Inicia processamento
        receiptProvider.setProcessing(true);
        receiptProvider.updateProgress(0.3);

        expect(receiptProvider.isProcessing, isTrue);

        // Cancela processamento
        receiptProvider.cancelProcessing();

        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.processingProgress, equals(0.0));
      });
    });
  });
}
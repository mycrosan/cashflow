import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import '../../lib/providers/receipt_provider.dart';
import '../../lib/providers/transaction_provider.dart';
import '../../lib/providers/member_provider.dart';
import '../../lib/models/receipt.dart';
import '../../lib/models/transaction.dart';
import '../../lib/models/member.dart';

// Gera mocks automaticamente
@GenerateMocks([TransactionProvider, MemberProvider])
class MockTransactionProvider extends Mock implements TransactionProvider {}
class MockMemberProvider extends Mock implements MemberProvider {}

void main() {
  group('ReceiptProvider Tests', () {
    late ReceiptProvider receiptProvider;
    late MockTransactionProvider mockTransactionProvider;
    late MockMemberProvider mockMemberProvider;

    setUp(() {
      mockTransactionProvider = MockTransactionProvider();
      mockMemberProvider = MockMemberProvider();
      receiptProvider = ReceiptProvider(
        transactionProvider: mockTransactionProvider,
        memberProvider: mockMemberProvider,
      );
    });

    tearDown(() {
      receiptProvider.dispose();
    });

    group('Estado Inicial', () {
      test('deve inicializar com estado correto', () {
        // Assert
        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.processingProgress, equals(0.0));
        expect(receiptProvider.lastProcessedReceipt, isNull);
        expect(receiptProvider.processedReceipts, isEmpty);
        expect(receiptProvider.totalProcessed, equals(0));
        expect(receiptProvider.successfulProcessed, equals(0));
        expect(receiptProvider.failedProcessed, equals(0));
      });
    });

    group('Processamento de Imagem', () {
      test('deve processar imagem com sucesso', () async {
        // Arrange
        const imagePath = '/path/to/receipt.jpg';
        final mockMember = Member(
          id: 1,
          name: 'Membro Teste',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberProvider.members).thenReturn([mockMember]);

        // Act
        final result = await receiptProvider.processReceiptImage(imagePath);

        // Assert
        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.processingProgress, equals(1.0));
        expect(receiptProvider.totalProcessed, equals(1));
        
        // Verifica se o provider foi notificado
        verify(receiptProvider.notifyListeners()).called(greaterThan(0));
      });

      test('deve atualizar progresso durante processamento', () async {
        // Arrange
        const imagePath = '/path/to/receipt.jpg';
        final progressUpdates = <double>[];

        // Escuta mudanças no progresso
        receiptProvider.addListener(() {
          progressUpdates.add(receiptProvider.processingProgress);
        });

        // Act
        await receiptProvider.processReceiptImage(imagePath);

        // Assert
        expect(progressUpdates, isNotEmpty);
        expect(progressUpdates.last, equals(1.0));
      });

      test('deve tratar erro no processamento', () async {
        // Arrange
        const imagePath = '/path/to/invalid.jpg';

        // Act
        final result = await receiptProvider.processReceiptImage(imagePath);

        // Assert
        expect(result.isSuccessful, isFalse);
        expect(receiptProvider.isProcessing, isFalse);
        expect(receiptProvider.failedProcessed, equals(1));
      });
    });

    group('Conversão para Transação', () {
      test('deve converter cupom para transação corretamente', () {
        // Arrange
        final receipt = Receipt(
          id: '1',
          establishmentName: 'Supermercado Teste',
          cnpj: '12.345.678/0001-90',
          totalAmount: 150.75,
          date: DateTime(2024, 1, 15),
          items: [
            ReceiptItem(name: 'Produto A', price: 50.25),
            ReceiptItem(name: 'Produto B', price: 100.50),
          ],
        );

        final mockMember = Member(
          id: 1,
          name: 'Membro Teste',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberProvider.members).thenReturn([mockMember]);

        // Act
        final transaction = receiptProvider.convertReceiptToTransaction(receipt);

        // Assert
        expect(transaction.value, equals(150.75));
        expect(transaction.date, equals(DateTime(2024, 1, 15)));
        expect(transaction.notes, contains('Supermercado Teste'));
        expect(transaction.notes, contains('12.345.678/0001-90'));
        expect(transaction.associatedMember, equals(mockMember));
      });

      test('deve usar primeiro membro quando disponível', () {
        // Arrange
        final receipt = Receipt(
          id: '1',
          establishmentName: 'Teste',
          cnpj: '12.345.678/0001-90',
          totalAmount: 100.0,
          date: DateTime.now(),
          items: [],
        );

        final mockMembers = [
          Member(id: 1, name: 'Membro 1', userId: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()),
          Member(id: 2, name: 'Membro 2', userId: 1, createdAt: DateTime.now(), updatedAt: DateTime.now()),
        ];

        when(mockMemberProvider.members).thenReturn(mockMembers);

        // Act
        final transaction = receiptProvider.convertReceiptToTransaction(receipt);

        // Assert
        expect(transaction.associatedMember, equals(mockMembers.first));
      });
    });

    group('Adição de Transação', () {
      test('deve adicionar transação com sucesso', () async {
        // Arrange
        final receipt = Receipt(
          id: '1',
          establishmentName: 'Teste',
          cnpj: '12.345.678/0001-90',
          totalAmount: 100.0,
          date: DateTime.now(),
          items: [],
        );

        final mockMember = Member(
          id: 1,
          name: 'Membro Teste',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberProvider.members).thenReturn([mockMember]);
        when(mockTransactionProvider.addTransaction(any)).thenAnswer((_) async => true);

        // Act
        final success = await receiptProvider.addTransactionFromReceipt(receipt);

        // Assert
        expect(success, isTrue);
        verify(mockTransactionProvider.addTransaction(any)).called(1);
      });

      test('deve tratar erro na adição de transação', () async {
        // Arrange
        final receipt = Receipt(
          id: '1',
          establishmentName: 'Teste',
          cnpj: '12.345.678/0001-90',
          totalAmount: 100.0,
          date: DateTime.now(),
          items: [],
        );

        final mockMember = Member(
          id: 1,
          name: 'Membro Teste',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberProvider.members).thenReturn([mockMember]);
        when(mockTransactionProvider.addTransaction(any)).thenThrow(Exception('Erro no banco'));

        // Act
        final success = await receiptProvider.addTransactionFromReceipt(receipt);

        // Assert
        expect(success, isFalse);
      });
    });

    group('Múltiplas Imagens', () {
      test('deve processar múltiplas imagens', () async {
        // Arrange
        const imagePaths = [
          '/path/to/receipt1.jpg',
          '/path/to/receipt2.jpg',
          '/path/to/receipt3.jpg',
        ];

        final mockMember = Member(
          id: 1,
          name: 'Membro Teste',
          userId: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockMemberProvider.members).thenReturn([mockMember]);

        // Act
        final results = await receiptProvider.processMultipleImages(imagePaths);

        // Assert
        expect(results, hasLength(3));
        expect(receiptProvider.totalProcessed, equals(3));
      });

      test('deve cancelar processamento em lote', () async {
        // Arrange
        const imagePaths = [
          '/path/to/receipt1.jpg',
          '/path/to/receipt2.jpg',
          '/path/to/receipt3.jpg',
        ];

        // Act
        final future = receiptProvider.processMultipleImages(imagePaths);
        receiptProvider.cancelProcessing();
        final results = await future;

        // Assert
        expect(receiptProvider.isProcessing, isFalse);
      });
    });

    group('Estatísticas', () {
      test('deve calcular taxa de sucesso corretamente', () {
        // Arrange
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementFailed();

        // Act
        final successRate = receiptProvider.successRate;

        // Assert
        expect(successRate, equals(2.0 / 3.0)); // 66.67%
      });

      test('deve retornar zero para taxa de sucesso sem processamentos', () {
        // Act
        final successRate = receiptProvider.successRate;

        // Assert
        expect(successRate, equals(0.0));
      });
    });

    group('Limpeza de Dados', () {
      test('deve limpar histórico de processamento', () {
        // Arrange
        receiptProvider.incrementSuccessful();
        receiptProvider.incrementFailed();

        // Act
        receiptProvider.clearHistory();

        // Assert
        expect(receiptProvider.processedReceipts, isEmpty);
        expect(receiptProvider.totalProcessed, equals(0));
        expect(receiptProvider.successfulProcessed, equals(0));
        expect(receiptProvider.failedProcessed, equals(0));
      });
    });

    group('Validação', () {
      test('deve validar caminho de imagem', () {
        // Act & Assert
        expect(receiptProvider.isValidImagePath('/path/to/image.jpg'), isTrue);
        expect(receiptProvider.isValidImagePath('/path/to/image.png'), isTrue);
        expect(receiptProvider.isValidImagePath('/path/to/image.jpeg'), isTrue);
        expect(receiptProvider.isValidImagePath('/path/to/image.gif'), isFalse);
        expect(receiptProvider.isValidImagePath(''), isFalse);
      });

      test('deve validar lista de caminhos', () {
        // Arrange
        const validPaths = ['/path/to/image1.jpg', '/path/to/image2.png'];
        const invalidPaths = ['/path/to/image1.gif', ''];

        // Act & Assert
        expect(receiptProvider.areValidImagePaths(validPaths), isTrue);
        expect(receiptProvider.areValidImagePaths(invalidPaths), isFalse);
        expect(receiptProvider.areValidImagePaths([]), isFalse);
      });
    });

    group('Gerenciamento de Recursos', () {
      test('deve liberar recursos corretamente', () {
        // Act
        receiptProvider.dispose();

        // Assert
        // Verifica se não há vazamentos de memória ou listeners ativos
        expect(() => receiptProvider.notifyListeners(), returnsNormally);
      });
    });
  });

  group('ReceiptProcessingResult Tests', () {
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
      final result = ReceiptProcessingResult(
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
      const result = ReceiptProcessingResult(
        isSuccessful: false,
        confidence: 0.0,
        errorMessage: 'Erro no processamento',
      );

      // Assert
      expect(result.isSuccessful, isFalse);
      expect(result.receipt, isNull);
      expect(result.confidence, equals(0.0));
      expect(result.errorMessage, equals('Erro no processamento'));
    });
  });
}
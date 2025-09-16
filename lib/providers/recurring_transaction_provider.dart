import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';

class RecurringTransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  AuthProvider? _authProvider;
  List<RecurringTransaction> _recurringTransactions = [];
  bool _isLoading = false;
  String? _error;

  List<RecurringTransaction> get recurringTransactions => _recurringTransactions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Definir AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }
  
  // Obter ID do usuário logado
  int? get _currentUserId => _authProvider?.currentUser?.id;

  // Carregar todas as transações recorrentes
  Future<void> loadRecurringTransactions() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _recurringTransactions = await _databaseService.getRecurringTransactions(userId: _currentUserId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao carregar transações recorrentes: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Adicionar nova transação recorrente
  Future<bool> addRecurringTransaction({
    required String frequency,
    required String category,
    required double value,
    required int associatedMemberId,
    required DateTime startDate,
    DateTime? endDate,
    int? maxOccurrences,
    String? notes,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final now = DateTime.now();
      final recurringTransaction = RecurringTransaction(
        frequency: frequency,
        category: category,
        value: value,
        associatedMember: Member(
          id: associatedMemberId,
          name: 'Membro',
          relation: 'Familiar',
          userId: 1,
          createdAt: now,
          updatedAt: now,
        ),
        startDate: startDate,
        endDate: endDate,
        maxOccurrences: maxOccurrences,
        isActive: 1,
        notes: notes,
        userId: 1, // TODO: Pegar do usuário logado
        createdAt: now,
        updatedAt: now,
      );

      final recurringTransactionId = await _databaseService.insertRecurringTransaction(recurringTransaction);
      if (recurringTransactionId > 0) {
        final newRecurringTransaction = recurringTransaction.copyWith(id: recurringTransactionId);
        _recurringTransactions.add(newRecurringTransaction);
        _recurringTransactions.sort((a, b) => a.startDate.compareTo(b.startDate));
        
        // Gerar transações futuras automaticamente para os próximos 12 meses
        await _generateFutureTransactions(newRecurringTransaction);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao adicionar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao adicionar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Gerar transações futuras automaticamente para uma recorrência
  Future<void> _generateFutureTransactions(RecurringTransaction recurringTransaction) async {
    try {
      print('=== RECURRING PROVIDER: Gerando transações futuras para recorrência ${recurringTransaction.id} ===');
      
      final now = DateTime.now();
      final currentMonth = DateTime(now.year, now.month, 1);
      
      // Gerar transações para os próximos 12 meses
      for (int i = 0; i < 12; i++) {
        final targetMonth = DateTime(currentMonth.year, currentMonth.month + i, 1);
        
        // Verificar se a recorrência se aplica a este mês
        final endOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);
        if (recurringTransaction.startDate.isAfter(endOfMonth) || 
            (recurringTransaction.endDate != null && recurringTransaction.endDate!.isBefore(targetMonth))) {
          continue;
        }
        
        final dates = _getRecurringDatesForMonth(
          recurringTransaction,
          targetMonth,
          endOfMonth,
        );
        
        for (final date in dates) {
          // Verificar se já existe no banco
          final exists = await checkRecurringTransactionExists(
            recurringTransactionId: recurringTransaction.id!,
            date: date,
          );
          
          if (!exists) {
            final transaction = Transaction(
              value: recurringTransaction.value,
              date: date,
              category: recurringTransaction.category,
              associatedMember: recurringTransaction.associatedMember,
              notes: recurringTransaction.notes ?? 'Transação recorrente',
              recurringTransactionId: recurringTransaction.id,
              userId: recurringTransaction.userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            // Inserir no banco de dados
            final transactionId = await _databaseService.insertTransaction(transaction);
            if (transactionId > 0) {
              print('Transação futura criada: ${transaction.category} - ${date.day}/${date.month}/${date.year}');
              
              // Log para sincronização
              await _databaseService.logSyncAction('lancamentos', transactionId, 'create');
            }
          }
        }
      }
      
      print('=== RECURRING PROVIDER: Transações futuras geradas com sucesso ===');
      
    } catch (e) {
      print('Erro ao gerar transações futuras: $e');
    }
  }

  // Atualizar transação recorrente
  Future<bool> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    try {
      print('=== RECURRING PROVIDER: Iniciando atualização de transação recorrente ID: ${recurringTransaction.id} ===');
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      final updatedRecurringTransaction = recurringTransaction.copyWith(updatedAt: DateTime.now());
      print('=== RECURRING PROVIDER: Transação atualizada preparada: ${updatedRecurringTransaction.toJson()} ===');
      
      final result = await _databaseService.updateRecurringTransaction(updatedRecurringTransaction);
      print('=== RECURRING PROVIDER: Resultado da atualização no banco: $result ===');
      
      if (result > 0) {
        final index = _recurringTransactions.indexWhere((rt) => rt.id == recurringTransaction.id);
        print('=== RECURRING PROVIDER: Índice encontrado na lista: $index ===');
        
        if (index != -1) {
          _recurringTransactions[index] = updatedRecurringTransaction;
          _recurringTransactions.sort((a, b) => a.startDate.compareTo(b.startDate));
          print('=== RECURRING PROVIDER: Transação atualizada na lista local ===');
        } else {
          print('=== RECURRING PROVIDER: AVISO: Transação não encontrada na lista local ===');
        }
        
        _isLoading = false;
        notifyListeners();
        print('=== RECURRING PROVIDER: Atualização concluída com sucesso ===');
        return true;
      } else {
        _error = 'Erro ao atualizar transação recorrente - nenhuma linha foi afetada';
        _isLoading = false;
        notifyListeners();
        print('=== RECURRING PROVIDER: ERRO: Nenhuma linha foi afetada na atualização ===');
        return false;
      }
    } catch (e) {
      _error = 'Erro ao atualizar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      print('=== RECURRING PROVIDER: ERRO na atualização: $e ===');
      return false;
    }
  }

  // Deletar transação recorrente
  Future<bool> deleteRecurringTransaction(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Deletando recorrência $id ===');
      
      // Primeiro, remover todas as transações órfãs desta recorrência
      await _removeOrphanedTransactions(id);
      
      // Depois, deletar a recorrência do banco
      final result = await _databaseService.deleteRecurringTransaction(id);
      if (result > 0) {
        _recurringTransactions.removeWhere((rt) => rt.id == id);
        print('=== RECURRING PROVIDER: Recorrência $id deletada com sucesso ===');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao deletar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar transação recorrente: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remover todas as transações órfãs de uma recorrência específica
  Future<void> _removeOrphanedTransactions(int recurringTransactionId) async {
    try {
      print('=== RECURRING PROVIDER: Removendo transações órfãs da recorrência $recurringTransactionId ===');
      
      // Buscar todas as transações que referenciam esta recorrência
      // Vamos buscar em um período amplo para garantir que pegamos todas
      final now = DateTime.now();
      final startDate = DateTime(now.year - 1, 1, 1); // 1 ano atrás
      final endDate = DateTime(now.year + 2, 12, 31); // 2 anos no futuro
      
      final allTransactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Filtrar transações que pertencem a esta recorrência
      final orphanedTransactions = allTransactions.where(
        (transaction) => transaction.recurringTransactionId == recurringTransactionId
      ).toList();
      
      print('=== RECURRING PROVIDER: ${orphanedTransactions.length} transações órfãs encontradas ===');
      
      // Remover cada transação órfã
      for (final transaction in orphanedTransactions) {
        if (transaction.id != null) {
          try {
            await _databaseService.deleteTransaction(transaction.id!);
            print('Transação órfã removida: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}');
          } catch (e) {
            print('Erro ao remover transação órfã ${transaction.id}: $e');
          }
        }
      }
      
      print('=== RECURRING PROVIDER: Remoção de transações órfãs concluída ===');
      
    } catch (e) {
      print('Erro ao remover transações órfãs: $e');
    }
  }

  // Ativar/desativar transação recorrente
  Future<bool> toggleRecurringTransaction(int id, int isActive) async {
    try {
      final recurringTransaction = _recurringTransactions.firstWhere((rt) => rt.id == id);
      final updatedRecurringTransaction = recurringTransaction.copyWith(
        isActive: isActive,
        updatedAt: DateTime.now(),
      );

      return await updateRecurringTransaction(updatedRecurringTransaction);
    } catch (e) {
      _error = 'Erro ao alterar status da transação recorrente: $e';
      notifyListeners();
      return false;
    }
  }

  // === NOVOS MÉTODOS PARA EVITAR DUPLICAÇÃO ===

  // Verificar se uma transação recorrente já existe no banco para uma data específica
  Future<bool> checkRecurringTransactionExists({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    try {
      final existingTransactions = await _databaseService.getTransactions(
        startDate: DateTime(date.year, date.month, date.day),
        endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      );
      
      return existingTransactions.any((transaction) => 
        transaction.recurringTransactionId == recurringTransactionId
      );
    } catch (e) {
      print('Erro ao verificar existência de transação recorrente: $e');
      return false;
    }
  }

  // Gerar transações recorrentes apenas para o mês especificado, evitando duplicações
  Future<List<Transaction>> generateRecurringTransactionsForMonth({
    required DateTime month,
  }) async {
    final transactions = <Transaction>[];
    
    try {
      print('=== RECURRING PROVIDER: Gerando transações para ${month.month}/${month.year} ===');
      
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      
      for (final recurringTransaction in _recurringTransactions) {
        if (recurringTransaction.isActive != 1) {
          print('Recorrência ${recurringTransaction.id} está inativa, pulando...');
          continue;
        }
        
        // Verificar se a recorrência se aplica ao mês
        if (recurringTransaction.startDate.isAfter(endOfMonth) || 
            (recurringTransaction.endDate != null && recurringTransaction.endDate!.isBefore(startOfMonth))) {
          print('Recorrência ${recurringTransaction.id} não se aplica ao mês ${month.month}/${month.year}');
          continue;
        }
        
        final dates = _getRecurringDatesForMonth(
          recurringTransaction,
          startOfMonth,
          endOfMonth,
        );
        
        print('Recorrência ${recurringTransaction.id}: ${dates.length} datas calculadas');
        
        for (final date in dates) {
          // Verificar se já existe no banco
          final exists = await checkRecurringTransactionExists(
            recurringTransactionId: recurringTransaction.id!,
            date: date,
          );
          
          if (!exists) {
            final transaction = Transaction(
              value: recurringTransaction.value,
              date: date,
              category: recurringTransaction.category,
              associatedMember: recurringTransaction.associatedMember,
              notes: recurringTransaction.notes ?? 'Transação recorrente',
              recurringTransactionId: recurringTransaction.id,
              userId: recurringTransaction.userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            transactions.add(transaction);
            print('Nova transação recorrente criada para ${date.day}/${date.month}/${date.year}');
          } else {
            print('Transação recorrente já existe para ${date.day}/${date.month}/${date.year}');
          }
        }
      }
      
      print('=== RECURRING PROVIDER: ${transactions.length} transações únicas geradas ===');
      
    } catch (e) {
      print('Erro ao gerar transações recorrentes: $e');
      _error = 'Erro ao gerar transações recorrentes: $e';
      notifyListeners();
    }
    
    return transactions;
  }

  // Calcular datas recorrentes apenas para um mês específico
  List<DateTime> _getRecurringDatesForMonth(
    RecurringTransaction recurringTransaction,
    DateTime startOfMonth,
    DateTime endOfMonth,
  ) {
    final dates = <DateTime>[];
    DateTime currentDate = recurringTransaction.startDate;
    int occurrences = 0;
    
    // Ajustar data inicial se necessário
    if (currentDate.isBefore(startOfMonth)) {
      currentDate = _getNextOccurrenceAfter(currentDate, startOfMonth, recurringTransaction.frequency);
    }
    
    while (currentDate.isBefore(endOfMonth.add(Duration(days: 1))) && 
           (recurringTransaction.maxOccurrences == null || occurrences < (recurringTransaction.maxOccurrences ?? 0)) &&
           (recurringTransaction.endDate == null || currentDate.isBefore(recurringTransaction.endDate!))) {
      
      if (currentDate.isAfter(startOfMonth.subtract(Duration(days: 1))) && 
          currentDate.isBefore(endOfMonth.add(Duration(days: 1)))) {
        dates.add(currentDate);
        print('Data calculada: ${currentDate.day}/${currentDate.month}/${currentDate.year}');
      }
      
      occurrences++;
      currentDate = _getNextOccurrence(currentDate, recurringTransaction.frequency);
    }
    
    return dates;
  }

  // Obter próxima ocorrência baseada na frequência
  DateTime _getNextOccurrence(DateTime currentDate, String frequency) {
    switch (frequency) {
      case 'daily':
        return currentDate.add(Duration(days: 1));
      case 'weekly':
        return currentDate.add(Duration(days: 7));
      case 'monthly':
        return DateTime(
          currentDate.year,
          currentDate.month + 1,
          currentDate.day,
        );
      case 'yearly':
        return DateTime(
          currentDate.year + 1,
          currentDate.month,
          currentDate.day,
        );
      default:
        return currentDate.add(Duration(days: 1));
    }
  }

  // Obter próxima ocorrência após uma data específica
  DateTime _getNextOccurrenceAfter(DateTime startDate, DateTime afterDate, String frequency) {
    DateTime currentDate = startDate;
    
    while (currentDate.isBefore(afterDate)) {
      currentDate = _getNextOccurrence(currentDate, frequency);
    }
    
    return currentDate;
  }

  // === MÉTODOS LEGACY (mantidos para compatibilidade) ===

  // Gerar transações baseadas nas recorrentes (método legacy)
  Future<List<Transaction>> generateTransactionsFromRecurring({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final transactions = <Transaction>[];
    
    for (final recurringTransaction in _recurringTransactions) {
      if (recurringTransaction.isActive != 1) continue;
      
      final dates = _getRecurringDates(
        recurringTransaction.startDate,
        endDate,
        recurringTransaction.frequency,
        recurringTransaction.maxOccurrences,
        recurringTransaction.endDate,
      );

      for (final date in dates) {
        if (date.isAfter(startDate.subtract(const Duration(days: 1)))) {
          final transaction = Transaction(
            value: recurringTransaction.value,
            date: date,
            category: recurringTransaction.category,
            associatedMember: recurringTransaction.associatedMember,
            notes: recurringTransaction.notes ?? 'Transação recorrente',
            recurringTransactionId: recurringTransaction.id,
            userId: recurringTransaction.userId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          transactions.add(transaction);
        }
      }
    }

    return transactions;
  }

  // Calcular datas recorrentes (método legacy)
  List<DateTime> _getRecurringDates(
    DateTime startDate,
    DateTime endDate,
    String frequency,
    int? maxOccurrences,
    DateTime? endDateLimit,
  ) {
    final dates = <DateTime>[];
    DateTime currentDate = startDate;
    int occurrences = 0;

    while (currentDate.isBefore(endDate) && 
           (maxOccurrences == null || occurrences < maxOccurrences) &&
           (endDateLimit == null || currentDate.isBefore(endDateLimit))) {
      
      dates.add(currentDate);
      occurrences++;

      switch (frequency) {
        case 'daily':
          currentDate = currentDate.add(const Duration(days: 1));
          break;
        case 'weekly':
          currentDate = currentDate.add(const Duration(days: 7));
          break;
        case 'monthly':
          currentDate = DateTime(
            currentDate.year,
            currentDate.month + 1,
            currentDate.day,
          );
          break;
        case 'yearly':
          currentDate = DateTime(
            currentDate.year + 1,
            currentDate.month,
            currentDate.day,
          );
          break;
      }
    }

    return dates;
  }

  // Buscar transações recorrentes por frequência
  List<RecurringTransaction> getRecurringTransactionsByFrequency(String frequency) {
    return _recurringTransactions.where((rt) => rt.frequency == frequency).toList();
  }

  // Buscar transações recorrentes ativas
  List<RecurringTransaction> get activeRecurringTransactions => 
      _recurringTransactions.where((rt) => rt.isActive == 1).toList();

  // Buscar transações recorrentes por membro
  List<RecurringTransaction> getRecurringTransactionsByMember(int memberId) {
    return _recurringTransactions.where((rt) => rt.associatedMember.id == memberId).toList();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

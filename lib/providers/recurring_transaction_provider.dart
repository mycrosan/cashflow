import 'package:flutter/material.dart';
import '../models/recurring_transaction.dart';
import '../models/transaction.dart';
import '../models/member.dart';
import '../services/database_service.dart';
import 'auth_provider.dart';
import 'transaction_provider.dart';

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
      print('=== RECURRING PROVIDER: Limite máximo de ocorrências: ${recurringTransaction.maxOccurrences} ===');
      
      final now = DateTime.now();
      
      // Contador global de ocorrências
      int totalOccurrences = 0;
      DateTime currentDate = recurringTransaction.startDate;
      
      // Gerar transações respeitando o limite máximo de ocorrências
      while (totalOccurrences < (recurringTransaction.maxOccurrences ?? 999) && 
             (recurringTransaction.endDate == null || currentDate.isBefore(recurringTransaction.endDate!)) &&
             currentDate.isBefore(DateTime(now.year + 1, now.month, now.day))) { // Limite de 1 ano no futuro
        
        // Verificar se já existe no banco
        final exists = await checkRecurringTransactionExists(
          recurringTransactionId: recurringTransaction.id!,
          date: currentDate,
        );
        
        if (!exists) {
          final transaction = Transaction(
            value: recurringTransaction.value,
            date: currentDate,
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
            print('Transação futura criada: ${transaction.category} - ${currentDate.day}/${currentDate.month}/${currentDate.year}');
            
            // Log para sincronização
            await _databaseService.logSyncAction('lancamentos', transactionId, 'create');
          }
        }
        
        // Incrementar contador de ocorrências
        totalOccurrences++;
        
        // Calcular próxima data baseada na frequência
        currentDate = _getNextOccurrence(currentDate, recurringTransaction.frequency);
      }
      
      print('=== RECURRING PROVIDER: ${totalOccurrences} transações futuras geradas com sucesso ===');
      
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

  // Soft delete de transação recorrente
  Future<bool> deleteRecurringTransaction(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Excluindo recorrência $id (soft delete) ===');
      
      // Buscar a transação recorrente atual
      final recurringIndex = _recurringTransactions.indexWhere((rt) => rt.id == id);
      if (recurringIndex == -1) {
        _error = 'Transação recorrente não encontrada';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
      final recurringTransaction = _recurringTransactions[recurringIndex];
      
      // Criar uma cópia com deletedAt preenchido
      final deletedRecurring = recurringTransaction.copyWith(
        deletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      // Atualizar no banco de dados
      final result = await _databaseService.updateRecurringTransaction(deletedRecurring);
      if (result > 0) {
        // Remover da lista local (para não aparecer na interface)
        _recurringTransactions.removeAt(recurringIndex);
        
        // Marcar todas as transações futuras desta recorrência como excluídas
        await _softDeleteFutureTransactions(id);
        
        print('=== RECURRING PROVIDER: Recorrência $id excluída com sucesso ===');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao excluir transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Erro ao excluir transação recorrente: $e';
      notifyListeners();
      print('=== RECURRING PROVIDER: ERRO na exclusão: $e ===');
      return false;
    }
  }

  // Deletar apenas a transação atual e futuras (mantém a recorrência e transações passadas)
  Future<bool> deleteCurrentAndFutureTransactions(int recurringTransactionId, DateTime currentTransactionDate) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Deletando transação atual e futuras da recorrência $recurringTransactionId ===');
      
      // Remover apenas transações atuais e futuras
      await _removeCurrentAndFutureTransactions(recurringTransactionId, currentTransactionDate);
      
      // Verificar se a recorrência ficou órfã após a remoção (considerando contexto temporal)
      await _checkAndRemoveOrphanedRecurring(recurringTransactionId, currentMonth: DateTime(currentTransactionDate.year, currentTransactionDate.month, 1));
      
      print('=== RECURRING PROVIDER: Transações atuais e futuras deletadas com sucesso ===');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Erro ao deletar transações atuais e futuras: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Deletar apenas uma transação específica (mantém a recorrência ativa)
  Future<bool> deleteSingleRecurringTransaction(int transactionId, {TransactionProvider? transactionProvider}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Deletando transação específica $transactionId ===');
      
      // Primeiro, obter informações da transação para limpar o cache correto
      final transactionToDelete = await _databaseService.getTransactions();
      final targetTransaction = transactionToDelete.firstWhere(
        (t) => t.id == transactionId,
        orElse: () => throw Exception('Transação não encontrada'),
      );
      
      // Guardar o ID da recorrência para verificar se ficou órfã
      final recurringId = targetTransaction.recurringTransactionId;
      
      // Usar o método correto do TransactionProvider que faz soft delete
      bool result = false;
      if (transactionProvider != null) {
        result = await transactionProvider.deleteTransaction(transactionId);
      } else {
        // Fallback: fazer soft delete diretamente
        final updateResult = await _databaseService.deleteTransaction(transactionId);
        result = updateResult > 0;
      }
      
      if (result) {
        print('=== RECURRING PROVIDER: Transação específica $transactionId excluída com sucesso (soft delete) ===');
        
        // Verificar se a recorrência ficou órfã e removê-la se necessário (considerando contexto temporal)
        if (recurringId != null) {
          await _checkAndRemoveOrphanedRecurring(recurringId, currentMonth: DateTime(targetTransaction.date.year, targetTransaction.date.month, 1));
        }
        
        // CORREÇÃO: Limpar cache do TransactionProvider para o mês da transação excluída
        if (transactionProvider != null) {
          transactionProvider.clearMonthCacheFor(targetTransaction.date);
          print('=== RECURRING PROVIDER: Cache do mês ${targetTransaction.date.month}/${targetTransaction.date.year} limpo ===');
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao deletar transação específica';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Erro ao deletar transação específica: $e';
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

  // Remover apenas a transação atual e futuras de uma recorrência específica
  Future<void> _removeCurrentAndFutureTransactions(int recurringTransactionId, DateTime currentTransactionDate) async {
    try {
      print('=== RECURRING PROVIDER: Removendo transação atual e futuras da recorrência $recurringTransactionId a partir de ${currentTransactionDate.day}/${currentTransactionDate.month}/${currentTransactionDate.year} ===');
      
      // Buscar transações futuras (incluindo a atual)
      final now = DateTime.now();
      final startDate = DateTime(currentTransactionDate.year, currentTransactionDate.month, currentTransactionDate.day);
      final endDate = DateTime(now.year + 2, 12, 31); // 2 anos no futuro
      
      final allTransactions = await _databaseService.getTransactions(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Filtrar transações que pertencem a esta recorrência e são da data atual em diante
      final futureTransactions = allTransactions.where(
        (transaction) => transaction.recurringTransactionId == recurringTransactionId &&
                        (transaction.date.isAtSameMomentAs(currentTransactionDate) ||
                         transaction.date.isAfter(currentTransactionDate))
      ).toList();
      
      print('=== RECURRING PROVIDER: ${futureTransactions.length} transações atuais e futuras encontradas ===');
      
      // Remover cada transação atual e futura
      for (final transaction in futureTransactions) {
        if (transaction.id != null) {
          try {
            await _databaseService.deleteTransaction(transaction.id!);
            print('Transação atual/futura removida: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}');
          } catch (e) {
            print('Erro ao remover transação atual/futura ${transaction.id}: $e');
          }
        }
      }
      
      print('=== RECURRING PROVIDER: Remoção de transações atuais e futuras concluída ===');
      
    } catch (e) {
      print('Erro ao remover transações atuais e futuras: $e');
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

  // Verificar se uma transação recorrente ATIVA já existe no banco para uma data específica
  // Retorna true apenas se existe uma transação não excluída (ativa)
  // Se existe apenas transação excluída, retorna false (permite recriar)
  Future<bool> checkRecurringTransactionExists({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    try {
      // Usar método que verifica apenas transações ativas (não excluídas)
      return await _databaseService.checkRecurringTransactionExistsIncludingDeleted(
        recurringTransactionId: recurringTransactionId,
        date: date,
      );
    } catch (e) {
      print('Erro ao verificar existência de transação recorrente: $e');
      return false;
    }
  }

  // Verificar se existe uma transação recorrente excluída para uma data específica
  Future<bool> hasDeletedRecurringTransactionForDate({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    try {
      return await _databaseService.hasDeletedRecurringTransactionForDate(
        recurringTransactionId: recurringTransactionId,
        date: date,
      );
    } catch (e) {
      print('Erro ao verificar transação recorrente excluída: $e');
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
          // Verificar se já existe uma transação ativa no banco
          final exists = await checkRecurringTransactionExists(
            recurringTransactionId: recurringTransaction.id!,
            date: date,
          );
          
          // Verificar se existe uma transação excluída para esta data
          final hasDeleted = await hasDeletedRecurringTransactionForDate(
            recurringTransactionId: recurringTransaction.id!,
            date: date,
          );
          
          if (!exists && !hasDeleted) {
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
          } else if (exists) {
            print('Transação recorrente já existe (ativa) para ${date.day}/${date.month}/${date.year}');
          } else if (hasDeleted) {
            print('Transação recorrente excluída encontrada para ${date.day}/${date.month}/${date.year} - não criando nova');
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
    int globalOccurrences = 0; // Contador global desde o início da recorrência
    
    // Contar todas as ocorrências desde o início até o mês atual
    DateTime tempDate = recurringTransaction.startDate;
    while (tempDate.isBefore(startOfMonth)) {
      globalOccurrences++;
      tempDate = _getNextOccurrence(tempDate, recurringTransaction.frequency);
      
      // Se já atingiu o limite máximo antes do mês atual, retornar lista vazia
      if (recurringTransaction.maxOccurrences != null && 
          globalOccurrences >= recurringTransaction.maxOccurrences!) {
        print('Limite máximo de ${recurringTransaction.maxOccurrences} ocorrências já atingido antes do mês ${startOfMonth.month}/${startOfMonth.year}');
        return dates;
      }
    }
    
    // Ajustar data inicial se necessário
    if (currentDate.isBefore(startOfMonth)) {
      currentDate = _getNextOccurrenceAfter(currentDate, startOfMonth, recurringTransaction.frequency);
    }
    
    while (currentDate.isBefore(endOfMonth.add(const Duration(days: 1))) && 
           (recurringTransaction.maxOccurrences == null || globalOccurrences < (recurringTransaction.maxOccurrences ?? 0)) &&
           (recurringTransaction.endDate == null || currentDate.isBefore(recurringTransaction.endDate!))) {
      
      if (currentDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) && 
          currentDate.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        dates.add(currentDate);
        print('Data calculada: ${currentDate.day}/${currentDate.month}/${currentDate.year} (ocorrência global #${globalOccurrences + 1})');
      }
      
      globalOccurrences++;
      currentDate = _getNextOccurrence(currentDate, recurringTransaction.frequency);
    }
    
    return dates;
  }

  // Obter próxima ocorrência baseada na frequência
  DateTime _getNextOccurrence(DateTime currentDate, String frequency) {
    switch (frequency) {
      case 'daily':
        return currentDate.add(const Duration(days: 1));
      case 'weekly':
        return currentDate.add(const Duration(days: 7));
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
        return currentDate.add(const Duration(days: 1));
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

  // Verificar e remover recorrência órfã (sem transações associadas) - VERSÃO INTELIGENTE
  Future<void> _checkAndRemoveOrphanedRecurring(int recurringId, {DateTime? currentMonth}) async {
    try {
      print('=== RECURRING PROVIDER: Verificando se recorrência $recurringId ficou órfã (contexto temporal) ===');
      
      // Obter a recorrência para verificar suas datas
      final recurring = _recurringTransactions.firstWhere(
        (rt) => rt.id == recurringId,
        orElse: () => throw Exception('Recorrência não encontrada'),
      );
      
      final now = DateTime.now();
      final currentMonthToCheck = currentMonth ?? DateTime(now.year, now.month, 1);
      
      print('=== RECURRING PROVIDER: Mês atual para verificação: ${currentMonthToCheck.month}/${currentMonthToCheck.year} ===');
      print('=== RECURRING PROVIDER: Recorrência ${recurring.category} - Início: ${recurring.startDate} - Fim: ${recurring.endDate} ===');
      
      // Buscar transações em um período amplo (passado, presente e futuro)
      final searchStartDate = DateTime(recurring.startDate.year, recurring.startDate.month, 1);
      final searchEndDate = recurring.endDate ?? DateTime(now.year + 2, 12, 31);
      
      final allTransactions = await _databaseService.getTransactions(
        startDate: searchStartDate,
        endDate: searchEndDate,
      );
      
      final associatedTransactions = allTransactions.where(
        (t) => t.recurringTransactionId == recurringId
      ).toList();
      
      print('=== RECURRING PROVIDER: Transações encontradas para recorrência $recurringId: ${associatedTransactions.length} ===');
      
      // Analisar transações por período
      final pastTransactions = associatedTransactions.where(
        (t) => t.date.isBefore(currentMonthToCheck)
      ).toList();
      
      final currentAndFutureTransactions = associatedTransactions.where(
        (t) => !t.date.isBefore(currentMonthToCheck)
      ).toList();
      
      print('=== RECURRING PROVIDER: Transações passadas: ${pastTransactions.length}, Atuais/Futuras: ${currentAndFutureTransactions.length} ===');
      
      // REGRA INTELIGENTE: Só remover se não há transações em NENHUM período
      // E se a recorrência não se aplica mais ao futuro
      final shouldRemove = associatedTransactions.isEmpty || (
        currentAndFutureTransactions.isEmpty && 
        (recurring.endDate != null && recurring.endDate!.isBefore(currentMonthToCheck))
      );
      
      if (shouldRemove) {
        print('=== RECURRING PROVIDER: Recorrência $recurringId está realmente órfã, removendo... ===');
        
        final result = await _databaseService.deleteRecurringTransaction(recurringId);
        if (result > 0) {
          // Remover da lista local
          _recurringTransactions.removeWhere((rt) => rt.id == recurringId);
          print('=== RECURRING PROVIDER: Recorrência órfã $recurringId removida com sucesso ===');
          notifyListeners();
        }
      } else {
        print('=== RECURRING PROVIDER: Recorrência $recurringId PRESERVADA - tem histórico ou ainda é válida ===');
        if (pastTransactions.isNotEmpty) {
          print('=== RECURRING PROVIDER: - ${pastTransactions.length} transações no histórico (preservadas) ===');
        }
        if (currentAndFutureTransactions.isNotEmpty) {
          print('=== RECURRING PROVIDER: - ${currentAndFutureTransactions.length} transações atuais/futuras ===');
        }
      }
    } catch (e) {
      print('=== RECURRING PROVIDER: Erro ao verificar recorrência órfã $recurringId: $e ===');
    }
  }

  // Soft delete de transações futuras de uma recorrência
  Future<void> _softDeleteFutureTransactions(int recurringTransactionId) async {
    try {
      print('=== RECURRING PROVIDER: Marcando transações futuras como excluídas para recorrência $recurringTransactionId ===');
      
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // Buscar transações futuras (a partir de hoje)
      final endDate = DateTime(now.year + 2, 12, 31); // 2 anos no futuro
      
      final allTransactions = await _databaseService.getTransactions(
        startDate: today,
        endDate: endDate,
      );
      
      // Filtrar transações que pertencem a esta recorrência e são futuras
      final futureTransactions = allTransactions.where(
        (transaction) => transaction.recurringTransactionId == recurringTransactionId &&
                        transaction.date.isAfter(today.subtract(const Duration(days: 1)))
      ).toList();
      
      print('=== RECURRING PROVIDER: ${futureTransactions.length} transações futuras encontradas ===');
      
      // Marcar cada transação futura como excluída (soft delete)
      for (final transaction in futureTransactions) {
        if (transaction.id != null) {
          try {
            final deletedTransaction = transaction.copyWith(
              deletedAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            
            await _databaseService.updateTransaction(deletedTransaction);
            print('Transação futura marcada como excluída: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}/${transaction.date.year}');
          } catch (e) {
            print('Erro ao marcar transação futura ${transaction.id} como excluída: $e');
          }
        }
      }
      
      print('=== RECURRING PROVIDER: Soft delete de transações futuras concluído ===');
      
    } catch (e) {
      print('Erro ao fazer soft delete de transações futuras: $e');
    }
  }

  // Restaurar transação recorrente excluída
  Future<bool> restoreRecurringTransaction(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Restaurando recorrência $id ===');
      
      // Buscar transações recorrentes excluídas
      final deletedRecurringTransactions = await _databaseService.getDeletedRecurringTransactions(userId: _currentUserId);
      final deletedRecurring = deletedRecurringTransactions.firstWhere(
        (rt) => rt.id == id,
        orElse: () => throw Exception('Transação recorrente excluída não encontrada'),
      );
      
      // Criar uma cópia sem deletedAt
      final restoredRecurring = deletedRecurring.copyWith(
        deletedAt: null,
        updatedAt: DateTime.now(),
      );
      
      // Atualizar no banco de dados
      final result = await _databaseService.updateRecurringTransaction(restoredRecurring);
      if (result > 0) {
        // Adicionar de volta à lista local
        _recurringTransactions.add(restoredRecurring);
        
        print('=== RECURRING PROVIDER: Recorrência $id restaurada com sucesso ===');
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Erro ao restaurar transação recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Erro ao restaurar transação recorrente: $e';
      notifyListeners();
      print('=== RECURRING PROVIDER: ERRO na restauração: $e ===');
      return false;
    }
  }

  // Listar transações recorrentes excluídas
  Future<List<RecurringTransaction>> getDeletedRecurringTransactions() async {
    try {
      return await _databaseService.getDeletedRecurringTransactions(userId: _currentUserId);
    } catch (e) {
      _error = 'Erro ao buscar transações recorrentes excluídas: $e';
      return [];
    }
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // === MÉTODOS PARA EDIÇÃO GRANULAR DE RECORRÊNCIAS ===

  /// Edita apenas uma transação específica de uma recorrência
  /// Cria uma transação independente com os novos dados
  Future<bool> editSingleRecurringTransaction({
    required Transaction originalTransaction,
    required Transaction updatedTransaction,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Editando transação específica ${originalTransaction.id} ===');
      
      // Criar nova transação independente (sem recurringTransactionId)
      final independentTransaction = updatedTransaction.copyWith(
        id: originalTransaction.id,
        recurringTransactionId: null, // Remove a ligação com a recorrência
        updatedAt: DateTime.now(),
      );
      
      // Atualizar a transação no banco
      final result = await _databaseService.updateTransaction(independentTransaction);
      
      if (result > 0) {
        print('=== RECURRING PROVIDER: Transação específica editada com sucesso ===');
        print('Transação agora é independente da recorrência');
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Falha ao atualizar transação no banco de dados';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _error = 'Erro ao editar transação específica: $e';
      _isLoading = false;
      notifyListeners();
      print('Erro ao editar transação específica: $e');
      return false;
    }
  }

  /// Edita uma transação recorrente e todas as futuras
  /// Atualiza a recorrência original e aplica as mudanças às transações futuras
  Future<bool> editThisAndFutureRecurringTransactions({
    required Transaction originalTransaction,
    required Transaction updatedTransaction,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      print('=== RECURRING PROVIDER: Editando transação atual e futuras ===');
      
      if (originalTransaction.recurringTransactionId == null) {
        _error = 'Transação não é recorrente';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Buscar a recorrência original
      final recurringIndex = _recurringTransactions.indexWhere(
        (rt) => rt.id == originalTransaction.recurringTransactionId
      );
      
      if (recurringIndex == -1) {
        _error = 'Recorrência não encontrada';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final originalRecurring = _recurringTransactions[recurringIndex];
      
      // Atualizar a recorrência com os novos dados
      final updatedRecurring = originalRecurring.copyWith(
        category: updatedTransaction.category,
        value: updatedTransaction.value,
        associatedMember: updatedTransaction.associatedMember,
        notes: updatedTransaction.notes,
        updatedAt: DateTime.now(),
      );
      
      // Salvar a recorrência atualizada
      final recurringResult = await _databaseService.updateRecurringTransaction(updatedRecurring);
      
      if (recurringResult > 0) {
        // Atualizar na lista local
        _recurringTransactions[recurringIndex] = updatedRecurring;
        
        // Atualizar a transação atual
        final currentUpdated = updatedTransaction.copyWith(
          id: originalTransaction.id,
          updatedAt: DateTime.now(),
        );
        
        await _databaseService.updateTransaction(currentUpdated);
        
        // Buscar e atualizar todas as transações futuras desta recorrência
        await _updateFutureRecurringTransactions(
          recurringTransactionId: originalTransaction.recurringTransactionId!,
          currentTransactionDate: originalTransaction.date,
          updatedRecurring: updatedRecurring,
        );
        
        print('=== RECURRING PROVIDER: Transação atual e futuras editadas com sucesso ===');
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Falha ao atualizar recorrência no banco de dados';
        _isLoading = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      _error = 'Erro ao editar transação atual e futuras: $e';
      _isLoading = false;
      notifyListeners();
      print('Erro ao editar transação atual e futuras: $e');
      return false;
    }
  }

  /// Atualiza todas as transações futuras de uma recorrência com novos dados
  Future<void> _updateFutureRecurringTransactions({
    required int recurringTransactionId,
    required DateTime currentTransactionDate,
    required RecurringTransaction updatedRecurring,
  }) async {
    try {
      print('=== RECURRING PROVIDER: Atualizando transações futuras da recorrência $recurringTransactionId ===');
      
      final now = DateTime.now();
      final tomorrow = DateTime(currentTransactionDate.year, currentTransactionDate.month, currentTransactionDate.day + 1);
      final endDate = DateTime(now.year + 2, 12, 31); // 2 anos no futuro
      
      // Buscar transações futuras (após a data atual)
      final allTransactions = await _databaseService.getTransactions(
        startDate: tomorrow,
        endDate: endDate,
      );
      
      // Filtrar transações que pertencem a esta recorrência e são futuras
      final futureTransactions = allTransactions.where(
        (transaction) => transaction.recurringTransactionId == recurringTransactionId &&
                        transaction.date.isAfter(currentTransactionDate) &&
                        transaction.deletedAt == null // Não atualizar transações excluídas
      ).toList();
      
      print('=== RECURRING PROVIDER: ${futureTransactions.length} transações futuras encontradas para atualização ===');
      
      // Atualizar cada transação futura
      for (final transaction in futureTransactions) {
        if (transaction.id != null) {
          try {
            final updatedTransaction = transaction.copyWith(
              category: updatedRecurring.category,
              value: updatedRecurring.value,
              associatedMember: updatedRecurring.associatedMember,
              notes: updatedRecurring.notes,
              updatedAt: DateTime.now(),
            );
            
            await _databaseService.updateTransaction(updatedTransaction);
            print('Transação futura atualizada: ${updatedTransaction.category} - ${updatedTransaction.date.day}/${updatedTransaction.date.month}/${updatedTransaction.date.year}');
          } catch (e) {
            print('Erro ao atualizar transação futura ${transaction.id}: $e');
          }
        }
      }
      
      print('=== RECURRING PROVIDER: Atualização de transações futuras concluída ===');
      
    } catch (e) {
      print('Erro ao atualizar transações futuras: $e');
    }
  }
}

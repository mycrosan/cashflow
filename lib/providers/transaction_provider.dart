import 'package:flutter/foundation.dart' hide Category;
import 'dart:async';
import '../models/transaction.dart';
import '../models/member.dart';
import '../models/category.dart';
import '../services/database_service.dart';
import '../services/api_service.dart';
import '../providers/recurring_transaction_provider.dart';
import 'auth_provider.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  AuthProvider? _authProvider;
  
  List<Transaction> _transactions = [];
  List<Member> _members = [];
  List<Category> _categories = [];
  
  bool _isLoading = false;
  String? _error;
  DateTime _selectedMonth = DateTime.now();
  
  // Controle de operações concorrentes
  Completer<void>? _currentOperation;
  bool _isOperationInProgress = false;
  
  // Cache e controle de meses
  DateTime? _currentMonth;
  Map<String, List<Transaction>> _monthCache = {};
  
  // Getters
  List<Transaction> get transactions => _transactions;
  List<Member> get members => _members;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;
  
  // Definir AuthProvider
  void setAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
  }
  
  // Obter ID do usuário logado
  int? get _currentUserId => _authProvider?.currentUser?.id;
  
  // Cálculos financeiros
  double get totalIncome {
    return _transactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.absoluteValue);
  }
  
  double get totalExpenses {
    return _transactions
        .where((t) => t.isExpense)
        .fold(0.0, (sum, t) => sum + t.absoluteValue);
  }
  
  double get balance => totalIncome - totalExpenses;
  
  // Transações do mês selecionado
  List<Transaction> get monthlyTransactions {
    final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    
    return _transactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
             t.date.isBefore(endOfMonth.add(Duration(days: 1)));
    }).toList();
  }
  
  // Transações agrupadas por data
  Map<String, List<Transaction>> get transactionsByDate {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      final dateKey = _formatDateKey(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    
    // Ordenar por data (mais recente primeiro)
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => DateTime.parse(b).compareTo(DateTime.parse(a)));
    
    final sortedMap = <String, List<Transaction>>{};
    for (final key in sortedKeys) {
      sortedMap[key] = grouped[key]!;
    }
    
    return sortedMap;
  }
  
  // Transações agrupadas por categoria
  Map<String, List<Transaction>> get transactionsByCategory {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      if (!grouped.containsKey(transaction.category)) {
        grouped[transaction.category] = [];
      }
      grouped[transaction.category]!.add(transaction);
    }
    
    return grouped;
  }
  
  // Transações agrupadas por membro
  Map<String, List<Transaction>> get transactionsByMember {
    final grouped = <String, List<Transaction>>{};
    
    for (final transaction in monthlyTransactions) {
      final memberName = transaction.associatedMember.name;
      if (!grouped.containsKey(memberName)) {
        grouped[memberName] = [];
      }
      grouped[memberName]!.add(transaction);
    }
    
    return grouped;
  }

  // Controle de operações concorrentes
  Future<void> _cancelCurrentOperation() async {
    if (_isOperationInProgress && _currentOperation != null) {
      print('Cancelando operação anterior...');
      _currentOperation!.complete();
      _currentOperation = null;
      _isOperationInProgress = false;
    }
  }

  Future<void> _waitForCurrentOperation() async {
    if (_isOperationInProgress && _currentOperation != null) {
      print('Aguardando operação anterior...');
      await _currentOperation!.future;
    }
  }

  void _startOperation() {
    _cancelCurrentOperation();
    _currentOperation = Completer<void>();
    _isOperationInProgress = true;
    print('Iniciando nova operação...');
  }

  void _completeOperation() {
    if (_currentOperation != null) {
      _currentOperation!.complete();
      _currentOperation = null;
      _isOperationInProgress = false;
      print('Operação concluída...');
    }
  }

  // === MÉTODOS PRINCIPAIS ===

  // Carregar transações do mês selecionado
  Future<void> loadMonthlyTransactions() async {
    _setLoading(true);
    _clearError();
    
    try {
      final startOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      print('=== TRANSACTION PROVIDER: Carregando transações do banco para ${_selectedMonth.month}/${_selectedMonth.year} ===');
      print('Período: ${startOfMonth.day}/${startOfMonth.month}/${startOfMonth.year} até ${endOfMonth.day}/${endOfMonth.month}/${endOfMonth.year}');
      
      _transactions = await _databaseService.getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
        userId: _currentUserId,
      );
      
      print('Transações carregadas do banco: ${_transactions.length}');
      
      // Log detalhado das transações carregadas
      for (int i = 0; i < _transactions.length && i < 10; i++) {
        final t = _transactions[i];
        print('Transação ${i+1}: ${t.category} - ${t.value} - ${t.date.day}/${t.date.month}/${t.date.year}');
      }
      
      notifyListeners();
    } catch (e) {
      print('Erro ao carregar transações: $e');
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Carregar transações para um mês específico
  Future<void> loadTransactionsForMonth(DateTime month) async {
    try {
      // Cancelar operação anterior se existir
      await _cancelCurrentOperation();
      
      // Iniciar nova operação
      _startOperation();
      
      print('=== TRANSACTION PROVIDER: Carregando transações para ${month.month}/${month.year} ===');
      
      _selectedMonth = month;
      await loadMonthlyTransactions();
      
      print('=== TRANSACTION PROVIDER: Transações carregadas com sucesso ===');
      
    } catch (e) {
      print('=== TRANSACTION PROVIDER: Erro ao carregar transações ===');
      print('Erro: $e');
      _setError('Erro ao carregar transações: $e');
    } finally {
      _completeOperation();
    }
  }

  // === NOVOS MÉTODOS PARA GESTÃO DE RECORRÊNCIAS ===

  // Carregar transações para um mês específico com geração inteligente de recorrências
  Future<void> loadTransactionsForMonthWithRecurring(DateTime month) async {
    try {
      // Cancelar operação anterior se existir
      await _cancelCurrentOperation();
      
      // Iniciar nova operação
      _startOperation();
      
      print('=== TRANSACTION PROVIDER: Carregando transações com recorrências para ${month.month}/${month.year} ===');
      
      _selectedMonth = month;
      _currentMonth = month; // Definir o mês atual para cache
      
      // Limpar cache para garantir dados frescos
      clearMonthCache();
      
      // Carregar transações existentes do mês
      await loadMonthlyTransactions();
      
      // Gerar transações recorrentes únicas para o mês
      await _generateUniqueRecurringTransactions(month);
      
      print('=== TRANSACTION PROVIDER: Transações com recorrências carregadas com sucesso ===');
      
    } catch (e) {
      print('=== TRANSACTION PROVIDER: Erro ao carregar transações com recorrências ===');
      print('Erro: $e');
      _setError('Erro ao carregar transações: $e');
    } finally {
      _completeOperation();
    }
  }

  // Gerar transações recorrentes únicas para um mês específico
  Future<void> _generateUniqueRecurringTransactions(DateTime month) async {
    try {
      // Obter provider de recorrências
      final recurringProvider = RecurringTransactionProvider();
      await recurringProvider.loadRecurringTransactions();
      
      print('=== TRANSACTION PROVIDER: Gerando recorrências únicas para ${month.month}/${month.year} ===');
      
      // Gerar transações recorrentes únicas
      final newRecurringTransactions = await recurringProvider.generateRecurringTransactionsForMonth(
        month: month,
      );
      
      print('=== TRANSACTION PROVIDER: ${newRecurringTransactions.length} novas recorrências geradas ===');
      
      // Adicionar transações únicas ao banco
      int addedCount = 0;
      for (final transaction in newRecurringTransactions) {
        try {
          final id = await _databaseService.insertTransaction(transaction);
          final newTransaction = transaction.copyWith(id: id);
          
          // Log para sincronização
          await _databaseService.logSyncAction('lancamentos', id, 'create');
          
          // Adicionar à lista local
          _transactions.add(newTransaction);
          addedCount++;
          
          print('Transação recorrente adicionada: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}');
        } catch (e) {
          print('Erro ao adicionar transação recorrente: $e');
        }
      }
      
      // Ordenar transações
      _sortTransactions();
      notifyListeners();
      
      print('=== TRANSACTION PROVIDER: $addedCount transações recorrentes adicionadas com sucesso ===');
      
    } catch (e) {
      print('Erro ao gerar transações recorrentes únicas: $e');
    }
  }

  // Verificar se uma transação recorrente já existe para uma data específica
  Future<bool> checkRecurringTransactionExists({
    required int recurringTransactionId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final existingTransactions = await _databaseService.getTransactions(
        startDate: startOfDay,
        endDate: endOfDay,
        userId: _currentUserId,
      );
      
      return existingTransactions.any((transaction) => 
        transaction.recurringTransactionId == recurringTransactionId
      );
    } catch (e) {
      print('Erro ao verificar existência de transação recorrente: $e');
      return false;
    }
  }

  // Remover transações órfãs (recorrências que não existem mais)
  Future<void> removeOrphanedRecurringTransactions() async {
    try {
      print('=== TRANSACTION PROVIDER: Removendo transações órfãs ===');
      
      // Obter provider de recorrências
      final recurringProvider = RecurringTransactionProvider();
      await recurringProvider.loadRecurringTransactions();
      
      // Obter IDs de recorrências ativas
      final activeRecurringIds = recurringProvider.recurringTransactions
          .where((rt) => rt.isActive == 1)
          .map((rt) => rt.id)
          .toSet();
      
      // Encontrar transações com recorrência_id que não existe mais
      final orphanedTransactions = _transactions.where((t) => 
        t.recurringTransactionId != null && 
        !activeRecurringIds.contains(t.recurringTransactionId)
      ).toList();
      
      print('=== TRANSACTION PROVIDER: ${orphanedTransactions.length} transações órfãs encontradas ===');
      
      // Remover transações órfãs
      for (final orphanedTransaction in orphanedTransactions) {
        if (orphanedTransaction.id != null) {
          await deleteTransaction(orphanedTransaction.id!);
          print('Transação órfã removida: ${orphanedTransaction.category} - ${orphanedTransaction.date.day}/${orphanedTransaction.date.month}');
        }
      }
      
    } catch (e) {
      print('Erro ao remover transações órfãs: $e');
    }
  }

  // Obter transações únicas para um mês (removendo duplicatas)
  List<Transaction> getUniqueTransactionsForMonth(DateTime month) {
    print('=== TRANSACTION PROVIDER: Buscando transações únicas para ${month.month}/${month.year} ===');
    print('Total de transações em memória: ${_transactions.length}');
    
    final monthTransactions = _transactions.where((t) {
      // Verificar se a data da transação está dentro do mês
      final transactionDate = t.date;
      final isInMonth = transactionDate.year == month.year && 
                       transactionDate.month == month.month;
      
      print('Transação ${t.category} - ${transactionDate.day}/${transactionDate.month}/${transactionDate.year} - Mês ${month.month}/${month.year} - Incluída: $isInMonth');
      
      return isInMonth;
    }).toList();
    
    print('Transações encontradas para o mês: ${monthTransactions.length}');
    
    // Remover duplicatas baseadas em ID único
    final uniqueTransactions = <Transaction>[];
    final seenIds = <int>{};
    
    for (final transaction in monthTransactions) {
      if (transaction.id != null && !seenIds.contains(transaction.id)) {
        uniqueTransactions.add(transaction);
        seenIds.add(transaction.id!);
      }
    }
    
    print('Transações únicas após remoção de duplicatas: ${uniqueTransactions.length}');
    
    // Ordenar por data (mais recente primeiro)
    uniqueTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    return uniqueTransactions;
  }

  // Filtrar transações removendo duplicatas de recorrências
  List<Transaction> getFilteredTransactionsForMonth(DateTime month) {
    final transactions = getUniqueTransactionsForMonth(month);
    
    print('=== TRANSACTION PROVIDER: Filtrando transações para ${month.month}/${month.year} ===');
    print('Transações antes do filtro: ${transactions.length}');
    
    // Remover duplicatas de recorrências baseadas em data, categoria e valor
    final filteredTransactions = <Transaction>[];
    final seenKeys = <String>{};
    
    for (final transaction in transactions) {
      // Criar chave única para verificação de duplicata
      final key = '${transaction.date.year}-${transaction.date.month}-${transaction.date.day}-${transaction.category}-${transaction.value}-${transaction.associatedMember.id}';
      
      if (!seenKeys.contains(key)) {
        filteredTransactions.add(transaction);
        seenKeys.add(key);
      } else {
        print('Duplicata removida: ${transaction.category} - ${transaction.date.day}/${transaction.date.month}');
      }
    }
    
    print('Transações após filtro: ${filteredTransactions.length}');
    
    return filteredTransactions;
  }

  // Obter transações para um mês específico
  List<Transaction> getTransactionsForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    
    return _transactions.where((t) {
      return t.date.isAfter(startOfMonth.subtract(Duration(days: 1))) &&
             t.date.isBefore(endOfMonth.add(Duration(days: 1)));
    }).toList();
  }

  // Carregar todas as transações
  Future<void> loadAllTransactions() async {
    try {
      // Cancelar operação anterior se existir
      await _cancelCurrentOperation();
      
      // Iniciar nova operação
      _startOperation();
      
      print('=== TRANSACTION PROVIDER: Carregando todas as transações ===');
      
      _setLoading(true);
      _clearError();
      
      _transactions = await _databaseService.getTransactions();
      notifyListeners();
      
      print('=== TRANSACTION PROVIDER: Todas as transações carregadas (${_transactions.length}) ===');
      
    } catch (e) {
      print('=== TRANSACTION PROVIDER: Erro ao carregar todas as transações ===');
      print('Erro: $e');
      _setError('Erro ao carregar transações: $e');
    } finally {
      _setLoading(false);
      _completeOperation();
    }
  }

  // Carregar membros
  Future<void> loadMembers() async {
    try {
      _members = await _databaseService.getMembers();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar membros: $e');
    }
  }

  // Carregar categorias
  Future<void> loadCategories() async {
    try {
      _categories = await _databaseService.getCategories();
      notifyListeners();
    } catch (e) {
      _setError('Erro ao carregar categorias: $e');
    }
  }

  // Adicionar transação
  Future<void> addTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearError();
    
    try {
      final id = await _databaseService.insertTransaction(transaction);
      final newTransaction = transaction.copyWith(id: id);
      
      // Log para sincronização
      await _databaseService.logSyncAction('lancamentos', id, 'create');
      
      // Atualizar lista de forma inteligente
      await updateAfterAddTransaction(newTransaction);
      
    } catch (e) {
      _setError('Erro ao adicionar transação: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Atualizar transação
  Future<bool> updateTransaction(Transaction transaction) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _databaseService.updateTransaction(transaction);
      
      final index = _transactions.indexWhere((t) => t.id == transaction.id);
      if (index != -1) {
        _transactions[index] = transaction;
        _sortTransactions();
      }
      
      // Log para sincronização
      if (transaction.id != null) {
        await _databaseService.logSyncAction('lancamentos', transaction.id!, 'update');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao atualizar transação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Deletar transação
  Future<bool> deleteTransaction(int id) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _databaseService.deleteTransaction(id);
      
      _transactions.removeWhere((t) => t.id == id);
      
      // Log para sincronização
      await _databaseService.logSyncAction('lancamentos', id, 'delete');
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erro ao deletar transação: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Alterar mês selecionado
  void changeMonth(DateTime month) {
    _selectedMonth = month;
    loadMonthlyTransactions();
  }

  // Filtrar transações
  List<Transaction> filterTransactions({
    String? category,
    int? memberId,
    bool? isIncome,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _transactions.where((transaction) {
      if (category != null && transaction.category != category) return false;
      if (memberId != null && transaction.associatedMember.id != memberId) return false;
      if (isIncome != null && transaction.isIncome != isIncome) return false;
      if (startDate != null && transaction.date.isBefore(startDate)) return false;
      if (endDate != null && transaction.date.isAfter(endDate)) return false;
      return true;
    }).toList();
  }

  // Buscar transação por ID
  Transaction? getTransactionById(int id) {
    try {
      return _transactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  // Sincronizar com o servidor
  Future<void> syncWithServer() async {
    _setLoading(true);
    _clearError();
    
    try {
      // Obter ações pendentes
      final pendingActions = await _databaseService.getPendingSyncActions();
      
      if (pendingActions.isEmpty) {
        return; // Nada para sincronizar
      }
      
      // Fazer upload das transações pendentes
      final pendingTransactions = _transactions.where((t) => !t.isSynced).toList();
      
      if (pendingTransactions.isNotEmpty) {
        await ApiService.syncTransactions(pendingTransactions);
        
        // Marcar como sincronizadas
        for (final transaction in pendingTransactions) {
          if (transaction.id != null) {
            await _databaseService.markSyncActionAsSynced(transaction.id!);
          }
        }
      }
      
      // Fazer download de novas transações do servidor
      final serverTransactions = await ApiService.getTransactions();
      
      // Mesclar com transações locais
      for (final serverTransaction in serverTransactions) {
        final localIndex = _transactions.indexWhere((t) => t.id == serverTransaction.id);
        
        if (localIndex == -1) {
          // Nova transação do servidor
          _transactions.add(serverTransaction);
        } else {
          // Atualizar transação existente
          _transactions[localIndex] = serverTransaction;
        }
      }
      
      _sortTransactions();
      notifyListeners();
      
    } catch (e) {
      _setError('Erro na sincronização: $e');
    } finally {
      _setLoading(false);
    }
  }

  // === MÉTODOS AUXILIARES ===

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _sortTransactions() {
    _transactions.sort((a, b) => b.date.compareTo(a.date));
  }

  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Limpar erros
  void clearError() {
    _clearError();
  }

  // === MÉTODOS AUXILIARES MELHORADOS ===

  // Atualizar lista após adicionar transação (melhorado)
  Future<void> updateAfterAddTransaction(Transaction transaction) async {
    try {
      // Verificar se a transação já existe na lista para evitar duplicação
      final existingIndex = _transactions.indexWhere((t) => 
        t.id == transaction.id || 
        (t.recurringTransactionId == transaction.recurringTransactionId &&
         t.date.year == transaction.date.year &&
         t.date.month == transaction.date.month &&
         t.date.day == transaction.date.day)
      );
      
      if (existingIndex == -1) {
        // Se a transação é do mês atual, recarregar transações do mês
        final currentMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
        final transactionMonth = DateTime(transaction.date.year, transaction.date.month, 1);
        
        if (currentMonth.isAtSameMomentAs(transactionMonth)) {
          // Recarregar transações do mês para garantir que a nova transação apareça
          await loadMonthlyTransactions();
        } else {
          // Se não é do mês atual, apenas adicionar à lista geral
          _transactions.add(transaction);
          _sortTransactions();
          notifyListeners();
        }
      } else {
        print('Transação já existe na lista, não adicionando duplicata');
      }
    } catch (e) {
      print('Erro ao atualizar lista após adicionar transação: $e');
    }
  }

  // Refresh dos dados (melhorado)
  Future<void> refresh() async {
    try {
      print('=== TRANSACTION PROVIDER: Iniciando refresh completo ===');
      
      // Usar operações sequenciais para evitar condições de corrida
      await loadMembers();
      await loadCategories();
      
      // Remover transações órfãs antes de recarregar
      await removeOrphanedRecurringTransactions();
      
      // Recarregar transações do mês atual com recorrências
      await loadTransactionsForMonthWithRecurring(_selectedMonth);
      
      print('=== TRANSACTION PROVIDER: Refresh completo concluído ===');
      
    } catch (e) {
      print('Erro no refresh: $e');
      _setError('Erro ao atualizar dados: $e');
    }
  }

  // Inicialização (melhorada)
  Future<void> initialize() async {
    try {
      print('=== TRANSACTION PROVIDER: Iniciando inicialização ===');
      
      // Usar operações sequenciais para evitar condições de corrida
      await loadMembers();
      await loadCategories();
      
      // Remover transações órfãs
      await removeOrphanedRecurringTransactions();
      
      // Carregar transações do mês atual com recorrências
      await loadTransactionsForMonthWithRecurring(_selectedMonth);
      
      print('=== TRANSACTION PROVIDER: Inicialização concluída ===');
      
    } catch (e) {
      print('Erro na inicialização: $e');
      _setError('Erro na inicialização: $e');
    }
  }

  // === MÉTODOS AUXILIARES ===

  String _getMonthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  // Limpar cache de meses
  void clearMonthCache() {
    _monthCache.clear();
    print('=== TRANSACTION PROVIDER: Cache de meses limpo ===');
  }

  // === MÉTODOS DE PAGAMENTO ===

  Future<bool> markTransactionAsPaid(int transactionId, {DateTime? paidDate}) async {
    try {
      print('=== TRANSACTION PROVIDER: Marcando transação $transactionId como paga ===');
      
      final databaseService = DatabaseService();
      final success = await databaseService.markTransactionAsPaid(
        transactionId, 
        paidDate: paidDate,
      );
      
      if (success) {
        // Atualizar a transação na lista local
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          final transaction = _transactions[index];
          final updatedTransaction = transaction.copyWith(
            isPaid: true,
            paidDate: paidDate ?? DateTime.now(),
            updatedAt: DateTime.now(),
          );
          _transactions[index] = updatedTransaction;
          
          // Atualizar cache do mês atual se necessário
          if (_currentMonth != null) {
            final monthKey = _getMonthKey(_currentMonth!);
            if (_monthCache.containsKey(monthKey)) {
              final monthTransactions = _monthCache[monthKey]!;
              final monthIndex = monthTransactions.indexWhere((t) => t.id == transactionId);
              if (monthIndex != -1) {
                monthTransactions[monthIndex] = updatedTransaction;
              }
            }
          }
          
          notifyListeners();
          print('=== TRANSACTION PROVIDER: Transação marcada como paga com sucesso ===');
        }
      }
      
      return success;
    } catch (e) {
      print('Erro ao marcar transação como paga: $e');
      _setError('Erro ao marcar transação como paga: $e');
      return false;
    }
  }

  Future<bool> markTransactionAsUnpaid(int transactionId) async {
    try {
      print('=== TRANSACTION PROVIDER: Marcando transação $transactionId como não paga ===');
      
      final databaseService = DatabaseService();
      final success = await databaseService.markTransactionAsUnpaid(transactionId);
      
      if (success) {
        // Atualizar a transação na lista local
        final index = _transactions.indexWhere((t) => t.id == transactionId);
        if (index != -1) {
          final transaction = _transactions[index];
          final updatedTransaction = transaction.copyWith(
            isPaid: false,
            paidDate: null,
            updatedAt: DateTime.now(),
          );
          _transactions[index] = updatedTransaction;
          
          // Atualizar cache do mês atual se necessário
          if (_currentMonth != null) {
            final monthKey = _getMonthKey(_currentMonth!);
            if (_monthCache.containsKey(monthKey)) {
              final monthTransactions = _monthCache[monthKey]!;
              final monthIndex = monthTransactions.indexWhere((t) => t.id == transactionId);
              if (monthIndex != -1) {
                monthTransactions[monthIndex] = updatedTransaction;
              }
            }
          }
          
          notifyListeners();
          print('=== TRANSACTION PROVIDER: Transação marcada como não paga com sucesso ===');
        }
      }
      
      return success;
    } catch (e) {
      print('Erro ao marcar transação como não paga: $e');
      _setError('Erro ao marcar transação como não paga: $e');
      return false;
    }
  }
}

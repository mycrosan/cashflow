import 'package:flutter/foundation.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';
import '../services/database_service.dart';

/// Classe para correções na lógica entre transações e recorrências
class TransactionRecurringFixes {
  static final DatabaseService _databaseService = DatabaseService();

  /// PROBLEMA 1: Cache inconsistente entre providers
  /// SOLUÇÃO: Método para sincronizar cache entre TransactionProvider e RecurringTransactionProvider
  static Future<void> synchronizeCacheBetweenProviders({
    required DateTime month,
    required Function clearTransactionCache,
    required Function clearRecurringCache,
  }) async {
    try {
      print('=== FIXES: Sincronizando cache entre providers para ${month.month}/${month.year} ===');
      
      // Limpar cache de ambos os providers
      clearTransactionCache(month);
      clearRecurringCache();
      
      print('=== FIXES: Cache sincronizado com sucesso ===');
    } catch (e) {
      print('=== FIXES: Erro ao sincronizar cache: $e ===');
      rethrow;
    }
  }

  /// PROBLEMA 2: Transações órfãs não são removidas adequadamente
  /// SOLUÇÃO: Método melhorado para limpeza de transações órfãs
  static Future<List<int>> cleanupOrphanedTransactions() async {
    try {
      print('=== FIXES: Iniciando limpeza de transações órfãs ===');
      
      // Obter todas as transações com recurringTransactionId
      final allTransactions = await _databaseService.getTransactions();
      final recurringTransactions = allTransactions
          .where((t) => t.recurringTransactionId != null)
          .toList();
      
      if (recurringTransactions.isEmpty) {
        print('=== FIXES: Nenhuma transação recorrente encontrada ===');
        return [];
      }
      
      // Obter todas as recorrências ativas
      final activeRecurringIds = await _getActiveRecurringTransactionIds();
      
      // Identificar transações órfãs
      final orphanedTransactions = recurringTransactions
          .where((t) => !activeRecurringIds.contains(t.recurringTransactionId))
          .toList();
      
      if (orphanedTransactions.isEmpty) {
        print('=== FIXES: Nenhuma transação órfã encontrada ===');
        return [];
      }
      
      print('=== FIXES: Encontradas ${orphanedTransactions.length} transações órfãs ===');
      
      // Remover transações órfãs
      final removedIds = <int>[];
      for (final transaction in orphanedTransactions) {
        if (transaction.id != null) {
          final result = await _databaseService.deleteTransaction(transaction.id!);
          if (result > 0) {
            removedIds.add(transaction.id!);
            print('=== FIXES: Transação órfã ${transaction.id} removida ===');
          }
        }
      }
      
      print('=== FIXES: Limpeza concluída. ${removedIds.length} transações órfãs removidas ===');
      return removedIds;
      
    } catch (e) {
      print('=== FIXES: Erro na limpeza de transações órfãs: $e ===');
      rethrow;
    }
  }

  /// PROBLEMA 3: Duplicação de transações recorrentes
  /// SOLUÇÃO: Método para verificar e remover duplicatas
  static Future<List<int>> removeDuplicateRecurringTransactions(DateTime month) async {
    try {
      print('=== FIXES: Verificando duplicatas para ${month.month}/${month.year} ===');
      
      // Obter transações do mês
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      final monthTransactions = await _databaseService.getTransactions(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );
      final recurringTransactions = monthTransactions
          .where((t) => t.recurringTransactionId != null)
          .toList();
      
      if (recurringTransactions.isEmpty) {
        print('=== FIXES: Nenhuma transação recorrente no mês ===');
        return [];
      }
      
      // Agrupar por recurringTransactionId e data
      final Map<String, List<Transaction>> groupedTransactions = {};
      
      for (final transaction in recurringTransactions) {
        final key = '${transaction.recurringTransactionId}_${transaction.date.day}';
        groupedTransactions.putIfAbsent(key, () => []).add(transaction);
      }
      
      // Identificar duplicatas
      final duplicateIds = <int>[];
      for (final group in groupedTransactions.values) {
        if (group.length > 1) {
          // Manter apenas a primeira transação, remover as demais
          for (int i = 1; i < group.length; i++) {
            if (group[i].id != null) {
              duplicateIds.add(group[i].id!);
            }
          }
        }
      }
      
      if (duplicateIds.isEmpty) {
        print('=== FIXES: Nenhuma duplicata encontrada ===');
        return [];
      }
      
      print('=== FIXES: Encontradas ${duplicateIds.length} duplicatas ===');
      
      // Remover duplicatas
      final removedIds = <int>[];
      for (final id in duplicateIds) {
        final result = await _databaseService.deleteTransaction(id);
        if (result > 0) {
          removedIds.add(id);
          print('=== FIXES: Duplicata $id removida ===');
        }
      }
      
      print('=== FIXES: ${removedIds.length} duplicatas removidas ===');
      return removedIds;
      
    } catch (e) {
      print('=== FIXES: Erro ao remover duplicatas: $e ===');
      rethrow;
    }
  }

  /// PROBLEMA 4: Status de sincronização inconsistente
  /// SOLUÇÃO: Método para corrigir status de sync
  static Future<void> fixSyncStatus() async {
    try {
      print('=== FIXES: Corrigindo status de sincronização ===');
      
      // Obter todas as transações
      final allTransactions = await _databaseService.getTransactions();
      
      int fixedCount = 0;
      for (final transaction in allTransactions) {
        // Se syncStatus é null ou inválido, definir como 'pending'
        if (transaction.syncStatus == null || 
            !['pending', 'synced', 'error'].contains(transaction.syncStatus)) {
          
          final updatedTransaction = transaction.copyWith(
            syncStatus: 'pending',
          );
          
          await _databaseService.updateTransaction(updatedTransaction);
          fixedCount++;
        }
      }
      
      print('=== FIXES: $fixedCount transações com status de sync corrigido ===');
      
    } catch (e) {
      print('=== FIXES: Erro ao corrigir status de sync: $e ===');
      rethrow;
    }
  }

  /// PROBLEMA 5: Recorrências órfãs (sem transações associadas) - VERSÃO INTELIGENTE
  /// SOLUÇÃO: Método para remover recorrências considerando contexto temporal
  static Future<List<int>> removeOrphanedRecurringTransactions({DateTime? currentMonth}) async {
    try {
      final now = DateTime.now();
      final currentMonthToCheck = currentMonth ?? DateTime(now.year, now.month, 1);
      
      print('=== FIXES: Verificando recorrências órfãs (contexto temporal: ${currentMonthToCheck.month}/${currentMonthToCheck.year}) ===');
      
      final removedRecurringIds = <int>[];
      
      // Obter todas as recorrências ativas
      final allRecurringTransactions = await _databaseService.getRecurringTransactions();
      final activeRecurringTransactions = allRecurringTransactions
          .where((r) => r.isActive == 1 && r.id != null)
          .toList();
      
      print('=== FIXES: ${activeRecurringTransactions.length} recorrências ativas encontradas ===');
      
      // Para cada recorrência ativa, verificar se tem transações associadas
      for (final recurring in activeRecurringTransactions) {
        final recurringId = recurring.id!;
        
        print('=== FIXES: Analisando recorrência ${recurring.category} (ID: $recurringId) ===');
        print('=== FIXES: - Início: ${recurring.startDate}, Fim: ${recurring.endDate} ===');
        
        // Buscar transações em um período amplo (passado, presente e futuro)
        final searchStartDate = DateTime(recurring.startDate.year, recurring.startDate.month, 1);
        final searchEndDate = recurring.endDate ?? DateTime(now.year + 2, 12, 31);
        
        final allTransactions = await _databaseService.getTransactions(
          startDate: searchStartDate,
          endDate: searchEndDate,
        );
        
        final associatedTransactions = allTransactions
            .where((t) => t.recurringTransactionId == recurringId)
            .toList();
        
        print('=== FIXES: - ${associatedTransactions.length} transações encontradas ===');
        
        // Analisar transações por período
        final pastTransactions = associatedTransactions.where(
          (t) => t.date.isBefore(currentMonthToCheck)
        ).toList();
        
        final currentAndFutureTransactions = associatedTransactions.where(
          (t) => !t.date.isBefore(currentMonthToCheck)
        ).toList();
        
        print('=== FIXES: - Passadas: ${pastTransactions.length}, Atuais/Futuras: ${currentAndFutureTransactions.length} ===');
        
        // REGRA INTELIGENTE: Só remover se não há transações em NENHUM período
        // E se a recorrência não se aplica mais ao futuro
        final shouldRemove = associatedTransactions.isEmpty || (
          currentAndFutureTransactions.isEmpty && 
          (recurring.endDate != null && recurring.endDate!.isBefore(currentMonthToCheck))
        );
        
        if (shouldRemove) {
          print('=== FIXES: Recorrência órfã encontrada: ${recurring.category} (ID: $recurringId) ===');
          
          // Remover a recorrência órfã
          final result = await _databaseService.deleteRecurringTransaction(recurringId);
          if (result > 0) {
            removedRecurringIds.add(recurringId);
            print('=== FIXES: Recorrência órfã $recurringId removida ===');
          }
        } else {
          print('=== FIXES: Recorrência ${recurring.category} PRESERVADA - tem histórico ou ainda é válida ===');
          if (pastTransactions.isNotEmpty) {
            print('=== FIXES: - ${pastTransactions.length} transações no histórico (preservadas) ===');
          }
          if (currentAndFutureTransactions.isNotEmpty) {
            print('=== FIXES: - ${currentAndFutureTransactions.length} transações atuais/futuras ===');
          }
        }
      }
      
      print('=== FIXES: Limpeza inteligente de recorrências órfãs concluída. ${removedRecurringIds.length} recorrências removidas ===');
      return removedRecurringIds;
      
    } catch (e) {
      print('=== FIXES: Erro na limpeza de recorrências órfãs: $e ===');
      rethrow;
    }
  }

  /// PROBLEMA 6: Relacionamento inconsistente entre tabelas
  /// SOLUÇÃO: Método para validar e corrigir relacionamentos
  static Future<Map<String, dynamic>> validateAndFixRelationships(DateTime month) async {
    try {
      print('=== FIXES: Validando relacionamentos entre tabelas ===');
      
      final results = <String, dynamic>{
        'orphanedTransactions': 0,
        'invalidRecurringIds': 0,
        'fixedRelationships': 0,
        'errors': <String>[],
      };
      
      // 1. Verificar transações com recurringTransactionId inválido
      final allTransactions = await _databaseService.getTransactions();
      final activeRecurringIds = await _getActiveRecurringTransactionIds();
      
      for (final transaction in allTransactions) {
        if (transaction.recurringTransactionId != null) {
          if (!activeRecurringIds.contains(transaction.recurringTransactionId)) {
            // Transação órfã - remover referência
            final updatedTransaction = transaction.copyWith(
              recurringTransactionId: null,
            );
            
            await _databaseService.updateTransaction(updatedTransaction);
            results['fixedRelationships']++;
            print('=== FIXES: Referência órfã removida da transação ${transaction.id} ===');
          }
        }
      }
      
      // 2. Verificar recorrências sem transações associadas
      final allRecurring = await _databaseService.getRecurringTransactions();
      for (final recurring in allRecurring) {
        if (recurring.id != null) {
          final associatedTransactions = allTransactions
              .where((t) => t.recurringTransactionId == recurring.id)
              .toList();
          
          if (associatedTransactions.isEmpty && recurring.isActive == 1) {
            print('=== FIXES: Recorrência ${recurring.id} ativa sem transações associadas ===');
            // Não remover automaticamente, apenas registrar
          }
        }
      }
      
      print('=== FIXES: Validação concluída ===');
      print('Relacionamentos corrigidos: ${results['fixedRelationships']}');
      
      return results;
      
    } catch (e) {
      print('=== FIXES: Erro na validação de relacionamentos: $e ===');
      rethrow;
    }
  }

  /// Método auxiliar para obter IDs de recorrências ativas
  static Future<Set<int>> _getActiveRecurringTransactionIds() async {
    try {
      final recurringTransactions = await _databaseService.getRecurringTransactions();
      return recurringTransactions
          .where((r) => r.isActive == 1 && r.id != null)
          .map((r) => r.id!)
          .toSet();
    } catch (e) {
      print('=== FIXES: Erro ao obter IDs de recorrências ativas: $e ===');
      return <int>{};
    }
  }

  /// Método principal para executar todas as correções
  static Future<Map<String, dynamic>> runAllFixes({
    DateTime? specificMonth,
    required Function clearTransactionCache,
    required Function clearRecurringCache,
  }) async {
    try {
      print('=== FIXES: Iniciando correções completas ===');
      
      final results = <String, dynamic>{
        'orphanedRemoved': <int>[],
        'duplicatesRemoved': <int>[],
        'syncStatusFixed': true,
        'relationshipsValidated': <String, dynamic>{},
        'cacheCleared': true,
        'success': true,
        'errors': <String>[],
      };
      
      try {
        // 1. Limpar transações órfãs
        results['orphanedRemoved'] = await cleanupOrphanedTransactions();
      } catch (e) {
        results['errors'].add('Erro na limpeza de órfãs: $e');
      }
      
      try {
        // 2. Remover duplicatas (se mês específico fornecido)
        if (specificMonth != null) {
          results['duplicatesRemoved'] = await removeDuplicateRecurringTransactions(specificMonth);
        }
      } catch (e) {
        results['errors'].add('Erro na remoção de duplicatas: $e');
      }
      
      try {
        // 3. Corrigir status de sincronização
        await fixSyncStatus();
      } catch (e) {
        results['errors'].add('Erro na correção de sync status: $e');
        results['syncStatusFixed'] = false;
      }
      
      try {
        // 4. Remover recorrências órfãs (sem transações associadas) - com contexto temporal
        results['orphanedRecurringsRemoved'] = await removeOrphanedRecurringTransactions(
          currentMonth: specificMonth ?? DateTime.now(),
        );
      } catch (e) {
        results['errors'].add('Erro na remoção de recorrências órfãs: $e');
      }
      
      try {
        // 5. Validar relacionamentos
        results['relationshipsValidated'] = await validateAndFixRelationships(specificMonth ?? DateTime.now());
      } catch (e) {
        results['errors'].add('Erro na validação de relacionamentos: $e');
      }
      
      try {
        // 5. Sincronizar cache
        if (specificMonth != null) {
          await synchronizeCacheBetweenProviders(
            month: specificMonth,
            clearTransactionCache: clearTransactionCache,
            clearRecurringCache: clearRecurringCache,
          );
        }
      } catch (e) {
        results['errors'].add('Erro na sincronização de cache: $e');
        results['cacheCleared'] = false;
      }
      
      results['success'] = (results['errors'] as List).isEmpty;
      
      print('=== FIXES: Correções concluídas ===');
      print('Órfãs removidas: ${(results['orphanedRemoved'] as List).length}');
      print('Duplicatas removidas: ${(results['duplicatesRemoved'] as List).length}');
      print('Erros: ${(results['errors'] as List).length}');
      
      return results;
      
    } catch (e) {
      print('=== FIXES: Erro geral nas correções: $e ===');
      return {
        'success': false,
        'error': e.toString(),
        'orphanedRemoved': <int>[],
        'duplicatesRemoved': <int>[],
        'syncStatusFixed': false,
        'relationshipsValidated': <String, dynamic>{},
        'cacheCleared': false,
        'errors': [e.toString()],
      };
    }
  }
}
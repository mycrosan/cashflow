import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_service.dart';
import '../models/transaction.dart' as models;
import '../models/member.dart';
import '../models/category.dart' as models;
import '../models/recurring_transaction.dart';

/// Serviço para backup e restore de dados entre SQLite local e Firestore
class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Chaves para SharedPreferences
  static const String _lastBackupKey = 'last_backup_date';
  static const String _backupEnabledKey = 'backup_enabled';

  /// Faz backup de todos os dados locais para o Firestore
  Future<BackupResult> createBackup() async {
    try {
      // Verificar se o usuário está autenticado
      final user = _auth.currentUser;
      if (user == null) {
        return BackupResult(
          success: false,
          message: 'Usuário não autenticado. Faça login primeiro.',
        );
      }

      print('Iniciando backup para usuário: ${user.uid}');

      // Obter dados locais
      final localData = await _getLocalData();
      
      // Criar documento de backup no Firestore
      final backupDoc = await _createBackupDocument(user.uid, localData);
      
      // Salvar data do último backup
      await _saveLastBackupDate();
      
      print('Backup criado com sucesso: ${backupDoc.id}');
      
      return BackupResult(
        success: true,
        message: 'Backup criado com sucesso!',
        backupId: backupDoc.id,
        dataCount: _countDataItems(localData),
      );
    } catch (e) {
      print('Erro ao criar backup: $e');
      return BackupResult(
        success: false,
        message: 'Erro ao criar backup: $e',
      );
    }
  }

  /// Restaura dados do Firestore para o SQLite local
  Future<BackupResult> restoreFromBackup(String backupId) async {
    try {
      // Verificar se o usuário está autenticado
      final user = _auth.currentUser;
      if (user == null) {
        return BackupResult(
          success: false,
          message: 'Usuário não autenticado. Faça login primeiro.',
        );
      }

      print('Iniciando restore do backup: $backupId');

      // Obter dados do backup
      final backupData = await _getBackupData(user.uid, backupId);
      if (backupData == null) {
        return BackupResult(
          success: false,
          message: 'Backup não encontrado.',
        );
      }

      // Limpar dados locais existentes
      await _clearLocalData();
      
      // Restaurar dados
      await _restoreDataToLocal(backupData);
      
      print('Restore concluído com sucesso');
      
      return BackupResult(
        success: true,
        message: 'Dados restaurados com sucesso!',
        dataCount: _countDataItems(backupData),
      );
    } catch (e) {
      print('Erro ao restaurar backup: $e');
      return BackupResult(
        success: false,
        message: 'Erro ao restaurar backup: $e',
      );
    }
  }

  /// Lista todos os backups disponíveis para o usuário
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return BackupInfo(
          id: doc.id,
          createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
          dataCount: data['dataCount'] ?? 0,
          size: data['size'] ?? 0,
        );
      }).toList();
    } catch (e) {
      print('Erro ao listar backups: $e');
      return [];
    }
  }

  /// Obtém dados locais do SQLite
  Future<Map<String, dynamic>> _getLocalData() async {
    final transactions = await _databaseService.getTransactions();
    final members = await _databaseService.getMembers();
    final categories = await _databaseService.getCategories();
    final recurringTransactions = await _databaseService.getAllRecurringTransactions();

    return {
      'transactions': transactions.map((t) => t.toJson()).toList(),
      'members': members.map((m) => m.toJson()).toList(),
      'categories': categories.map((c) => c.toJson()).toList(),
      'recurringTransactions': recurringTransactions.map((r) => r.toJson()).toList(),
    };
  }

  /// Cria documento de backup no Firestore
  Future<DocumentReference> _createBackupDocument(String userId, Map<String, dynamic> data) async {
    final backupData = {
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'data': data,
      'dataCount': _countDataItems(data),
      'size': _calculateDataSize(data),
      'version': '1.0',
    };

    return await _firestore
        .collection('users')
        .doc(userId)
        .collection('backups')
        .add(backupData);
  }

  /// Obtém dados de um backup específico
  Future<Map<String, dynamic>?> _getBackupData(String userId, String backupId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('backups')
          .doc(backupId)
          .get();

      if (!doc.exists) return null;
      
      return doc.data()?['data'] as Map<String, dynamic>?;
    } catch (e) {
      print('Erro ao obter dados do backup: $e');
      return null;
    }
  }

  /// Limpa todos os dados locais
  Future<void> _clearLocalData() async {
    await _databaseService.clearAllData();
  }

  /// Restaura dados para o SQLite local
  Future<void> _restoreDataToLocal(Map<String, dynamic> data) async {
    // Restaurar membros primeiro (devido às foreign keys)
    if (data['members'] != null) {
      for (final memberData in data['members']) {
        final member = Member.fromJson(memberData);
        await _databaseService.insertMember(member);
      }
    }

    // Restaurar categorias
    if (data['categories'] != null) {
      for (final categoryData in data['categories']) {
        final category = models.Category.fromJson(categoryData);
        await _databaseService.insertCategory(category);
      }
    }

    // Restaurar transações
    if (data['transactions'] != null) {
      for (final transactionData in data['transactions']) {
        final transaction = models.Transaction.fromJson(transactionData);
        await _databaseService.insertTransaction(transaction);
      }
    }

    // Restaurar transações recorrentes
    if (data['recurringTransactions'] != null) {
      for (final recurringData in data['recurringTransactions']) {
        final recurring = RecurringTransaction.fromJson(recurringData);
        await _databaseService.insertRecurringTransaction(recurring);
      }
    }
  }

  /// Conta o número de itens nos dados
  int _countDataItems(Map<String, dynamic> data) {
    int count = 0;
    data.forEach((key, value) {
      if (value is List) {
        count += value.length;
      }
    });
    return count;
  }

  /// Calcula o tamanho aproximado dos dados
  int _calculateDataSize(Map<String, dynamic> data) {
    return data.toString().length;
  }

  /// Salva a data do último backup
  Future<void> _saveLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
  }

  /// Obtém a data do último backup
  Future<DateTime?> getLastBackupDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = prefs.getString(_lastBackupKey);
      if (dateString != null) {
        return DateTime.parse(dateString);
      }
      return null;
    } catch (e) {
      print('Erro ao obter data do último backup: $e');
      return null;
    }
  }

  /// Verifica se o backup está habilitado
  Future<bool> isBackupEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_backupEnabledKey) ?? false;
    } catch (e) {
      print('Erro ao verificar status do backup: $e');
      return false;
    }
  }

  /// Habilita ou desabilita o backup automático
  Future<void> setBackupEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_backupEnabledKey, enabled);
    } catch (e) {
      print('Erro ao alterar status do backup: $e');
    }
  }

  /// Remove um backup específico
  Future<bool> deleteBackup(String backupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('backups')
          .doc(backupId)
          .delete();

      return true;
    } catch (e) {
      print('Erro ao deletar backup: $e');
      return false;
    }
  }
}

/// Resultado de uma operação de backup/restore
class BackupResult {
  final bool success;
  final String message;
  final String? backupId;
  final int dataCount;

  BackupResult({
    required this.success,
    required this.message,
    this.backupId,
    this.dataCount = 0,
  });
}

/// Informações sobre um backup
class BackupInfo {
  final String id;
  final DateTime createdAt;
  final int dataCount;
  final int size;

  BackupInfo({
    required this.id,
    required this.createdAt,
    required this.dataCount,
    required this.size,
  });

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

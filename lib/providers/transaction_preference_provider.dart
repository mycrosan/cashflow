import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/transactions/add_transaction_page.dart';
import '../models/category.dart';
import '../models/member.dart';

/// Provider para gerenciar as preferências de transação do usuário
/// Mantém a última escolha de tipo de transação, categoria e membro
class TransactionPreferenceProvider extends ChangeNotifier {
  static const String _lastTransactionTypeKey = 'last_transaction_type';
  static const String _lastCategoryNameKey = 'last_category_name';
  static const String _lastMemberIdKey = 'last_member_id';
  
  TransactionType _lastTransactionType = TransactionType.expense;
  String? _lastCategoryName;
  int? _lastMemberId;
  bool _isLoading = false;

  // Getters
  TransactionType get lastTransactionType => _lastTransactionType;
  String? get lastCategoryName => _lastCategoryName;
  int? get lastMemberId => _lastMemberId;
  bool get isLoading => _isLoading;

  /// Carrega todas as preferências de transação do SharedPreferences
  Future<void> loadAllPreferences() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      
      // Carregar tipo de transação
      final savedType = prefs.getString(_lastTransactionTypeKey);
      if (savedType != null) {
        _lastTransactionType = savedType == 'income' 
            ? TransactionType.income 
            : TransactionType.expense;
      }
      
      // Carregar categoria
      _lastCategoryName = prefs.getString(_lastCategoryNameKey);
      
      // Carregar membro
      final memberId = prefs.getInt(_lastMemberIdKey);
      if (memberId != null) {
        _lastMemberId = memberId;
      }
    } catch (e) {
      debugPrint('Erro ao carregar preferências de transação: $e');
      // Manter valores padrão em caso de erro
      _lastTransactionType = TransactionType.expense;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carrega a última escolha de tipo de transação do SharedPreferences
  Future<void> loadLastTransactionType() async {
    try {
      _isLoading = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final savedType = prefs.getString(_lastTransactionTypeKey);
      
      if (savedType != null) {
        _lastTransactionType = savedType == 'income' 
            ? TransactionType.income 
            : TransactionType.expense;
      }
    } catch (e) {
      debugPrint('Erro ao carregar última escolha de transação: $e');
      // Manter valor padrão em caso de erro
      _lastTransactionType = TransactionType.expense;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Salva a última escolha de tipo de transação no SharedPreferences
  Future<void> saveLastTransactionType(TransactionType type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final typeString = type == TransactionType.income ? 'income' : 'expense';
      
      await prefs.setString(_lastTransactionTypeKey, typeString);
      _lastTransactionType = type;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar última escolha de transação: $e');
    }
  }
  
  /// Salva a última categoria selecionada
  Future<void> saveLastCategory(String categoryName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastCategoryNameKey, categoryName);
      _lastCategoryName = categoryName;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar última categoria: $e');
    }
  }
  
  /// Salva o último membro selecionado
  Future<void> saveLastMember(int memberId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastMemberIdKey, memberId);
      _lastMemberId = memberId;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao salvar último membro: $e');
    }
  }

  /// Atualiza o tipo de transação sem salvar (para uso temporário)
  void updateTransactionType(TransactionType type) {
    if (_lastTransactionType != type) {
      _lastTransactionType = type;
      notifyListeners();
    }
  }

  /// Obtém o tipo de transação oposto ao atual
  TransactionType get oppositeType {
    return _lastTransactionType == TransactionType.income 
        ? TransactionType.expense 
        : TransactionType.income;
  }

  /// Verifica se o tipo atual é receita
  bool get isIncome => _lastTransactionType == TransactionType.income;

  /// Verifica se o tipo atual é despesa
  bool get isExpense => _lastTransactionType == TransactionType.expense;
}
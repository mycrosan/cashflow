import 'package:flutter/material.dart';
import '../models/financial_analysis.dart';
import '../services/financial_analysis_service.dart';
import '../services/database_service.dart';

class FinancialAnalysisProvider extends ChangeNotifier {
  final FinancialAnalysisService _analysisService = FinancialAnalysisService();
  final DatabaseService _databaseService = DatabaseService();

  // Estados de carregamento
  bool _isLoading = false;
  bool _isGeneratingReport = false;
  String? _error;

  // Dados de análise
  List<FinancialTrend> _trends = [];
  List<CategoryAnalysis> _categoryAnalysis = [];
  List<FinancialInsight> _insights = [];
  List<FinancialProjection> _projections = [];
  FinancialIndicators? _indicators;
  AnnualReport? _annualReport;

  // Filtros
  String _selectedPeriod = 'monthly';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  String? _selectedCategory;
  int? _selectedMemberId;
  int _selectedYear = DateTime.now().year;

  // Getters
  bool get isLoading => _isLoading;
  bool get isGeneratingReport => _isGeneratingReport;
  String? get error => _error;
  List<FinancialTrend> get trends => _trends;
  List<CategoryAnalysis> get categoryAnalysis => _categoryAnalysis;
  List<FinancialInsight> get insights => _insights;
  List<FinancialProjection> get projections => _projections;
  FinancialIndicators? get indicators => _indicators;
  AnnualReport? get annualReport => _annualReport;
  String get selectedPeriod => _selectedPeriod;
  DateTime get startDate => _startDate;
  DateTime get endDate => _endDate;
  String? get selectedCategory => _selectedCategory;
  int? get selectedMemberId => _selectedMemberId;
  int get selectedYear => _selectedYear;

  /// Carrega análise financeira completa
  Future<void> loadFinancialAnalysis() async {
    print('=== FINANCIAL ANALYSIS PROVIDER: Iniciando carregamento ===');
    _setLoading(true);
    _clearError();

    try {
      // Carregar dados do banco
      print('Carregando transações do banco...');
      final transactions = await _databaseService.getTransactions(
        startDate: _startDate,
        endDate: _endDate,
        category: _selectedCategory,
        memberId: _selectedMemberId,
      );
      print('Transações carregadas: ${transactions.length}');

      print('Carregando categorias...');
      final categories = await _databaseService.getCategories();
      print('Categorias carregadas: ${categories.length}');

      // Gerar análises
      print('Gerando tendências...');
      _trends = _analysisService.generateTrends(
        transactions,
        _selectedPeriod,
        _startDate,
        _endDate,
      );
      print('Tendências geradas: ${_trends.length}');

      print('Analisando categorias...');
      _categoryAnalysis = _analysisService.analyzeCategories(
        transactions,
        categories,
        _startDate,
        _endDate,
      );
      print('Análise de categorias: ${_categoryAnalysis.length}');

      print('Gerando insights...');
      _insights = _analysisService.generateInsights(
        transactions,
        _trends,
        _categoryAnalysis,
      );
      print('Insights gerados: ${_insights.length}');

      print('Gerando projeções...');
      _projections = _analysisService.generateProjections(_trends, 6);
      print('Projeções geradas: ${_projections.length}');

      print('Calculando indicadores...');
      _indicators = _analysisService.calculateIndicators(_trends, transactions);
      print('Indicadores calculados: ${_indicators != null ? "Sim" : "Não"}');

      print('=== FINANCIAL ANALYSIS PROVIDER: Carregamento concluído ===');
      notifyListeners();
    } catch (e) {
      print('=== FINANCIAL ANALYSIS PROVIDER: Erro ===');
      print('Erro: $e');
      _setError('Erro ao carregar análise financeira: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Gera relatório anual
  Future<void> generateAnnualReport(int year) async {
    _setGeneratingReport(true);
    _clearError();

    try {
      final transactions = await _databaseService.getTransactions(
        startDate: DateTime(year, 1, 1),
        endDate: DateTime(year, 12, 31),
      );

      final categories = await _databaseService.getCategories();

      _annualReport = _analysisService.generateAnnualReport(
        transactions,
        categories,
        year,
      );

      notifyListeners();
    } catch (e) {
      _setError('Erro ao gerar relatório anual: $e');
    } finally {
      _setGeneratingReport(false);
    }
  }

  /// Atualiza filtros e recarrega dados
  Future<void> updateFilters({
    String? period,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? memberId,
  }) async {
    bool needsReload = false;

    if (period != null && period != _selectedPeriod) {
      _selectedPeriod = period;
      needsReload = true;
    }

    if (startDate != null && startDate != _startDate) {
      _startDate = startDate;
      needsReload = true;
    }

    if (endDate != null && endDate != _endDate) {
      _endDate = endDate;
      needsReload = true;
    }

    if (category != _selectedCategory) {
      _selectedCategory = category;
      needsReload = true;
    }

    if (memberId != _selectedMemberId) {
      _selectedMemberId = memberId;
      needsReload = true;
    }

    if (needsReload) {
      await loadFinancialAnalysis();
    }
  }

  /// Atualiza ano selecionado para relatório anual
  void updateSelectedYear(int year) {
    if (_selectedYear != year) {
      _selectedYear = year;
      notifyListeners();
    }
  }

  /// Limpa todos os dados
  void clearData() {
    _trends.clear();
    _categoryAnalysis.clear();
    _insights.clear();
    _projections.clear();
    _indicators = null;
    _annualReport = null;
    notifyListeners();
  }

  /// Obtém tendências para um período específico
  List<FinancialTrend> getTrendsForPeriod(String period) {
    return _trends.where((t) => t.period == period).toList();
  }

  /// Obtém top 5 categorias
  List<CategoryAnalysis> getTopCategories({int limit = 5}) {
    return _categoryAnalysis.take(limit).toList();
  }

  /// Obtém insights por tipo
  List<FinancialInsight> getInsightsByType(InsightType type) {
    return _insights.where((i) => i.type == type).toList();
  }

  /// Obtém projeções com alta confiança
  List<FinancialProjection> getHighConfidenceProjections({double minConfidence = 0.7}) {
    return _projections.where((p) => p.confidence >= minConfidence).toList();
  }

  /// Calcula economia potencial baseada em insights
  double calculatePotentialSavings() {
    double savings = 0.0;
    
    for (final insight in _insights) {
      if (insight.type == InsightType.warning || insight.type == InsightType.alert) {
        savings += insight.impact;
      }
    }
    
    return savings;
  }

  /// Obtém resumo financeiro
  Map<String, double> getFinancialSummary() {
    if (_trends.isEmpty) {
      return {
        'totalIncome': 0.0,
        'totalExpense': 0.0,
        'totalBalance': 0.0,
        'savingsRate': 0.0,
        'averageMonthlyIncome': 0.0,
        'averageMonthlyExpense': 0.0,
      };
    }

    final totalIncome = _trends.fold(0.0, (sum, t) => sum + t.income);
    final totalExpense = _trends.fold(0.0, (sum, t) => sum + t.expense);
    final totalBalance = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (totalBalance / totalIncome) * 100 : 0.0;
    final months = _trends.length;

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'totalBalance': totalBalance,
      'savingsRate': savingsRate,
      'averageMonthlyIncome': totalIncome / months,
      'averageMonthlyExpense': totalExpense / months,
    };
  }

  /// Obtém dados para gráfico de tendências
  Map<String, List<Map<String, dynamic>>> getTrendsChartData() {
    final incomeData = _trends.map((t) => {
      'x': t.date.millisecondsSinceEpoch,
      'y': t.income,
      'label': _formatDateForChart(t.date),
    }).toList();

    final expenseData = _trends.map((t) => {
      'x': t.date.millisecondsSinceEpoch,
      'y': t.expense,
      'label': _formatDateForChart(t.date),
    }).toList();

    final balanceData = _trends.map((t) => {
      'x': t.date.millisecondsSinceEpoch,
      'y': t.balance,
      'label': _formatDateForChart(t.date),
    }).toList();

    return {
      'income': incomeData,
      'expense': expenseData,
      'balance': balanceData,
    };
  }

  /// Obtém dados para gráfico de categorias
  List<Map<String, dynamic>> getCategoryChartData() {
    return _categoryAnalysis.map((c) => {
      'category': c.category,
      'amount': c.amount,
      'percentage': c.percentage,
      'color': c.color.value,
      'icon': c.icon.codePoint,
    }).toList();
  }

  /// Obtém dados para gráfico de projeções
  Map<String, List<Map<String, dynamic>>> getProjectionsChartData() {
    final historicalData = _trends.map((t) => {
      'x': t.date.millisecondsSinceEpoch,
      'y': t.balance,
      'label': _formatDateForChart(t.date),
      'type': 'historical',
    }).toList();

    final projectionData = _projections.map((p) => {
      'x': p.date.millisecondsSinceEpoch,
      'y': p.projectedBalance,
      'label': _formatDateForChart(p.date),
      'type': 'projection',
      'confidence': p.confidence,
    }).toList();

    return {
      'historical': historicalData,
      'projection': projectionData,
    };
  }

  /// Formata data para exibição em gráficos
  String _formatDateForChart(DateTime date) {
    switch (_selectedPeriod) {
      case 'daily':
        return '${date.day}/${date.month}';
      case 'weekly':
        return 'Sem ${date.day}';
      case 'monthly':
        return '${date.month}/${date.year}';
      case 'yearly':
        return '${date.year}';
      default:
        return '${date.day}/${date.month}';
    }
  }

  /// Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setGeneratingReport(bool generating) {
    _isGeneratingReport = generating;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}

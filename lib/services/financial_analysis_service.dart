import 'dart:math';
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/financial_analysis.dart';

class FinancialAnalysisService {
  static final FinancialAnalysisService _instance = FinancialAnalysisService._internal();
  factory FinancialAnalysisService() => _instance;
  FinancialAnalysisService._internal();

  /// Gera tendências financeiras para diferentes períodos
  List<FinancialTrend> generateTrends(
    List<Transaction> transactions,
    String period, // 'daily', 'weekly', 'monthly', 'yearly'
    DateTime startDate,
    DateTime endDate,
  ) {
    print('=== FINANCIAL ANALYSIS SERVICE: Gerando tendências ===');
    print('Transações recebidas: ${transactions.length}');
    print('Período: $period');
    print('Data inicial: $startDate');
    print('Data final: $endDate');
    
    final trends = <FinancialTrend>[];
    final groupedTransactions = _groupTransactionsByPeriod(transactions, period, startDate, endDate);
    
    print('Grupos de transações: ${groupedTransactions.length}');

    for (final entry in groupedTransactions.entries) {
      final date = entry.key;
      final periodTransactions = entry.value;
      
      final income = periodTransactions
          .where((t) => t.value > 0)
          .fold(0.0, (sum, t) => sum + t.value);
      
      final expense = periodTransactions
          .where((t) => t.value < 0)
          .fold(0.0, (sum, t) => sum + t.value);
      
      final balance = income + expense; // expense já é negativo
      
      print('Tendência: $date - Receita: $income, Despesa: ${expense.abs()}, Saldo: $balance');
      
      trends.add(FinancialTrend(
        date: date,
        income: income,
        expense: expense.abs(),
        balance: balance,
        period: period,
      ));
    }

    print('Total de tendências geradas: ${trends.length}');
    return trends..sort((a, b) => a.date.compareTo(b.date));
  }

  /// Agrupa transações por período
  Map<DateTime, List<Transaction>> _groupTransactionsByPeriod(
    List<Transaction> transactions,
    String period,
    DateTime startDate,
    DateTime endDate,
  ) {
    final grouped = <DateTime, List<Transaction>>{};
    
    for (final transaction in transactions) {
      if (transaction.date.isBefore(startDate) || transaction.date.isAfter(endDate)) {
        continue;
      }
      
      DateTime groupKey;
      switch (period) {
        case 'daily':
          groupKey = DateTime(transaction.date.year, transaction.date.month, transaction.date.day);
          break;
        case 'weekly':
          final weekStart = transaction.date.subtract(Duration(days: transaction.date.weekday - 1));
          groupKey = DateTime(weekStart.year, weekStart.month, weekStart.day);
          break;
        case 'monthly':
          groupKey = DateTime(transaction.date.year, transaction.date.month, 1);
          break;
        case 'yearly':
          groupKey = DateTime(transaction.date.year, 1, 1);
          break;
        default:
          groupKey = DateTime(transaction.date.year, transaction.date.month, 1);
      }
      
      grouped.putIfAbsent(groupKey, () => []).add(transaction);
    }
    
    return grouped;
  }

  /// Analisa categorias de gastos
  List<CategoryAnalysis> analyzeCategories(
    List<Transaction> transactions,
    List<Category> categories,
    DateTime startDate,
    DateTime endDate,
  ) {
    final filteredTransactions = transactions.where((t) =>
        t.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
        t.date.isBefore(endDate.add(const Duration(days: 1)))
    ).toList();

    final categoryMap = <String, List<Transaction>>{};
    
    for (final transaction in filteredTransactions) {
      if (transaction.value < 0) { // Apenas despesas
        categoryMap.putIfAbsent(transaction.category, () => []).add(transaction);
      }
    }

    final totalExpense = filteredTransactions
        .where((t) => t.value < 0)
        .fold(0.0, (sum, t) => sum + t.value.abs());

    final analyses = <CategoryAnalysis>[];
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
    ];

    int colorIndex = 0;
    for (final entry in categoryMap.entries) {
      final categoryName = entry.key;
      final categoryTransactions = entry.value;
      
      final amount = categoryTransactions.fold(0.0, (sum, t) => sum + t.value.abs());
      final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0.0;
      final averageAmount = amount / categoryTransactions.length;
      
      analyses.add(CategoryAnalysis(
        category: categoryName,
        amount: amount,
        percentage: percentage,
        color: colors[colorIndex % colors.length],
        icon: Icons.category, // TODO: Parse string to IconData
        transactionCount: categoryTransactions.length,
        averageAmount: averageAmount,
      ));
      
      colorIndex++;
    }

    return analyses..sort((a, b) => b.amount.compareTo(a.amount));
  }

  /// Gera insights inteligentes
  List<FinancialInsight> generateInsights(
    List<Transaction> transactions,
    List<FinancialTrend> trends,
    List<CategoryAnalysis> categoryAnalysis,
  ) {
    final insights = <FinancialInsight>[];
    final now = DateTime.now();
    
    // Insight 1: Análise de gastos mensais
    if (trends.length >= 3) {
      final recentTrends = trends.length >= 3 ? trends.skip(trends.length - 3).toList() : trends;
      final avgExpense = recentTrends.fold(0.0, (sum, t) => sum + t.expense) / recentTrends.length;
      final lastExpense = recentTrends.last.expense;
      
      if (lastExpense > avgExpense * 1.2) {
        insights.add(FinancialInsight(
          title: 'Gastos Acima da Média',
          description: 'Seus gastos este mês estão 20% acima da média dos últimos 3 meses.',
          type: InsightType.warning,
          impact: ((lastExpense - avgExpense) / avgExpense) * 100,
          recommendation: 'Revise suas despesas e identifique categorias com maior crescimento.',
          date: now,
        ));
      } else if (lastExpense < avgExpense * 0.8) {
        insights.add(FinancialInsight(
          title: 'Excelente Controle de Gastos',
          description: 'Parabéns! Você reduziu seus gastos em 20% comparado à média.',
          type: InsightType.success,
          impact: ((avgExpense - lastExpense) / avgExpense) * 100,
          recommendation: 'Mantenha esse padrão e considere investir o valor economizado.',
          date: now,
        ));
      }
    }

    // Insight 2: Categoria com maior gasto
    if (categoryAnalysis.isNotEmpty) {
      final topCategory = categoryAnalysis.first;
      if (topCategory.percentage > 30) {
        insights.add(FinancialInsight(
          title: 'Categoria Dominante',
          description: '${topCategory.category} representa ${topCategory.percentage.toStringAsFixed(1)}% dos seus gastos.',
          type: InsightType.info,
          impact: topCategory.percentage,
          recommendation: 'Considere otimizar gastos nesta categoria para melhorar seu orçamento.',
          date: now,
        ));
      }
    }

    // Insight 3: Análise de sazonalidade
    final monthlyExpenses = <int, double>{};
    for (final trend in trends) {
      final month = trend.date.month;
      monthlyExpenses[month] = (monthlyExpenses[month] ?? 0) + trend.expense;
    }
    
    if (monthlyExpenses.length >= 6) {
      final currentMonth = now.month;
      final currentExpense = monthlyExpenses[currentMonth] ?? 0;
      final avgExpense = monthlyExpenses.values.fold(0.0, (sum, e) => sum + e) / monthlyExpenses.length;
      
      if (currentExpense > avgExpense * 1.3) {
        insights.add(FinancialInsight(
          title: 'Gastos Sazonais Elevados',
          description: 'Este mês apresenta gastos 30% acima da média histórica.',
          type: InsightType.alert,
          impact: ((currentExpense - avgExpense) / avgExpense) * 100,
          recommendation: 'Identifique se há eventos especiais causando este aumento.',
          date: now,
        ));
      }
    }

    // Insight 4: Análise de economia
    final totalIncome = trends.fold(0.0, (sum, t) => sum + t.income);
    final totalExpense = trends.fold(0.0, (sum, t) => sum + t.expense);
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0;
    
    if (savingsRate < 10) {
      insights.add(FinancialInsight(
        title: 'Taxa de Poupança Baixa',
        description: 'Sua taxa de poupança está em ${savingsRate.toStringAsFixed(1)}%.',
        type: InsightType.warning,
        impact: (10 - savingsRate).toDouble(),
        recommendation: 'Tente aumentar sua taxa de poupança para pelo menos 20% da renda.',
        date: now,
      ));
    } else if (savingsRate > 30) {
      insights.add(FinancialInsight(
        title: 'Excelente Taxa de Poupança',
        description: 'Parabéns! Você está poupando ${savingsRate.toStringAsFixed(1)}% da sua renda.',
        type: InsightType.success,
        impact: savingsRate - 20,
        recommendation: 'Considere investir parte desses recursos para crescimento.',
        date: now,
      ));
    }

    return insights;
  }

  /// Gera projeções financeiras
  List<FinancialProjection> generateProjections(
    List<FinancialTrend> trends,
    int monthsAhead,
  ) {
    if (trends.length < 3) return [];

    final projections = <FinancialProjection>[];
    final recentTrends = trends.length >= 6 ? trends.skip(trends.length - 6).toList() : trends; // Últimos 6 períodos
    
    // Calcular médias móveis
    final avgIncome = recentTrends.fold(0.0, (sum, t) => sum + t.income) / recentTrends.length;
    final avgExpense = recentTrends.fold(0.0, (sum, t) => sum + t.expense) / recentTrends.length;
    
    // Calcular tendências
    final incomeTrend = _calculateTrend(recentTrends.map((t) => t.income).toList());
    final expenseTrend = _calculateTrend(recentTrends.map((t) => t.expense).toList());
    
    // Calcular sazonalidade (simplificada)
    final seasonalFactors = _calculateSeasonalFactors(trends);
    
    final startDate = trends.last.date;
    
    for (int i = 1; i <= monthsAhead; i++) {
      final projectionDate = DateTime(startDate.year, startDate.month + i, 1);
      final month = projectionDate.month;
      
      // Aplicar tendência e sazonalidade
      final projectedIncome = avgIncome * (1 + incomeTrend * i) * (seasonalFactors[month] ?? 1.0);
      final projectedExpense = avgExpense * (1 + expenseTrend * i) * (seasonalFactors[month] ?? 1.0);
      final projectedBalance = projectedIncome - projectedExpense;
      
      // Calcular confiança baseada na consistência dos dados
      final confidence = _calculateConfidence(recentTrends, i);
      
      projections.add(FinancialProjection(
        date: projectionDate,
        projectedIncome: projectedIncome,
        projectedExpense: projectedExpense,
        projectedBalance: projectedBalance,
        confidence: confidence,
        basis: 'trend_seasonal',
      ));
    }
    
    return projections;
  }

  /// Calcula tendência linear simples
  double _calculateTrend(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final n = values.length;
    final sumX = (n * (n - 1)) / 2;
    final sumY = values.fold(0.0, (sum, v) => sum + v);
    final sumXY = values.asMap().entries.fold(0.0, (sum, entry) => sum + entry.key * entry.value);
    final sumX2 = (n * (n - 1) * (2 * n - 1)) / 6;
    
    return ((n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX)).toDouble();
  }

  /// Calcula fatores sazonais
  Map<int, double> _calculateSeasonalFactors(List<FinancialTrend> trends) {
    final monthlyData = <int, List<double>>{};
    
    for (final trend in trends) {
      final month = trend.date.month;
      monthlyData.putIfAbsent(month, () => []).add(trend.expense);
    }
    
    final factors = <int, double>{};
    final overallAvg = trends.fold(0.0, (sum, t) => sum + t.expense) / trends.length;
    
    for (final entry in monthlyData.entries) {
      final month = entry.key;
      final values = entry.value;
      final monthAvg = values.fold(0.0, (sum, v) => sum + v) / values.length;
      factors[month] = overallAvg > 0 ? monthAvg / overallAvg : 1.0;
    }
    
    return factors;
  }

  /// Calcula confiança da projeção
  double _calculateConfidence(List<FinancialTrend> trends, int monthsAhead) {
    if (trends.length < 3) return 0.3;
    
    // Calcular variabilidade dos dados
    final expenses = trends.map((t) => t.expense).toList();
    final mean = expenses.fold(0.0, (sum, e) => sum + e) / expenses.length;
    final variance = expenses.fold(0.0, (sum, e) => sum + pow(e - mean, 2)) / expenses.length;
    final coefficientOfVariation = sqrt(variance) / mean;
    
    // Confiança diminui com o tempo e variabilidade
    final timeFactor = max(0.1, 1.0 - (monthsAhead * 0.1));
    final variabilityFactor = max(0.1, 1.0 - coefficientOfVariation);
    
    return (timeFactor + variabilityFactor) / 2;
  }

  /// Calcula indicadores financeiros
  FinancialIndicators calculateIndicators(
    List<FinancialTrend> trends,
    List<Transaction> transactions,
  ) {
    if (trends.isEmpty) {
      return FinancialIndicators(
        monthlyAverageIncome: 0.0,
        monthlyAverageExpense: 0.0,
        savingsRate: 0.0,
        expenseGrowthRate: 0.0,
        incomeGrowthRate: 0.0,
        debtToIncomeRatio: 0.0,
        emergencyFundMonths: 0.0,
        investmentRate: 0.0,
      );
    }

    final totalIncome = trends.fold(0.0, (sum, t) => sum + t.income);
    final totalExpense = trends.fold(0.0, (sum, t) => sum + t.expense);
    final months = trends.length;
    
    final monthlyAverageIncome = totalIncome / months;
    final monthlyAverageExpense = totalExpense / months;
    final savingsRate = totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0.0;
    
    // Calcular taxas de crescimento
    final incomeGrowthRate = _calculateGrowthRate(trends.map((t) => t.income).toList());
    final expenseGrowthRate = _calculateGrowthRate(trends.map((t) => t.expense).toList());
    
    // Calcular fundo de emergência (simplificado)
    final emergencyFundMonths = monthlyAverageExpense > 0 ? 
        (totalIncome - totalExpense) / monthlyAverageExpense : 0.0;
    
    // Taxa de investimento (assumindo 20% da poupança)
    final investmentRate = savingsRate * 0.2;
    
    return FinancialIndicators(
      monthlyAverageIncome: monthlyAverageIncome,
      monthlyAverageExpense: monthlyAverageExpense,
      savingsRate: savingsRate,
      expenseGrowthRate: expenseGrowthRate,
      incomeGrowthRate: incomeGrowthRate,
      debtToIncomeRatio: 0.0, // Seria calculado com dados de dívidas
      emergencyFundMonths: emergencyFundMonths,
      investmentRate: investmentRate,
    );
  }

  /// Calcula taxa de crescimento
  double _calculateGrowthRate(List<double> values) {
    if (values.length < 2) return 0.0;
    
    final firstValue = values.first;
    final lastValue = values.last;
    
    if (firstValue == 0) return 0.0;
    
    return ((lastValue - firstValue) / firstValue) * 100;
  }

  /// Gera relatório anual completo
  AnnualReport generateAnnualReport(
    List<Transaction> transactions,
    List<Category> categories,
    int year,
  ) {
    final startDate = DateTime(year, 1, 1);
    final endDate = DateTime(year, 12, 31);
    
    final yearTransactions = transactions.where((t) =>
        t.date.year == year
    ).toList();
    
    final monthlyTrends = generateTrends(yearTransactions, 'monthly', startDate, endDate);
    final categoryAnalysis = analyzeCategories(yearTransactions, categories, startDate, endDate);
    final insights = generateInsights(yearTransactions, monthlyTrends, categoryAnalysis);
    final indicators = calculateIndicators(monthlyTrends, yearTransactions);
    final projections = generateProjections(monthlyTrends, 6); // 6 meses à frente
    
    final totalIncome = yearTransactions
        .where((t) => t.value > 0)
        .fold(0.0, (sum, t) => sum + t.value);
    
    final totalExpense = yearTransactions
        .where((t) => t.value < 0)
        .fold(0.0, (sum, t) => sum + t.value.abs());
    
    final totalSavings = totalIncome - totalExpense;
    final savingsRate = totalIncome > 0 ? (totalSavings / totalIncome) * 100 : 0.0;
    
    return AnnualReport(
      year: year,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      totalSavings: totalSavings,
      savingsRate: savingsRate,
      topCategories: categoryAnalysis.take(5).toList(),
      monthlyTrends: monthlyTrends,
      insights: insights,
      indicators: indicators,
      projections: projections,
    );
  }
}

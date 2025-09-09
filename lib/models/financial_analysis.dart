import 'package:flutter/material.dart';

/// Modelo para dados de tendência financeira
class FinancialTrend {
  final DateTime date;
  final double income;
  final double expense;
  final double balance;
  final String period; // 'daily', 'weekly', 'monthly', 'yearly'

  FinancialTrend({
    required this.date,
    required this.income,
    required this.expense,
    required this.balance,
    required this.period,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'income': income,
    'expense': expense,
    'balance': balance,
    'period': period,
  };

  factory FinancialTrend.fromJson(Map<String, dynamic> json) => FinancialTrend(
    date: DateTime.parse(json['date']),
    income: json['income']?.toDouble() ?? 0.0,
    expense: json['expense']?.toDouble() ?? 0.0,
    balance: json['balance']?.toDouble() ?? 0.0,
    period: json['period'] ?? 'monthly',
  );
}

/// Modelo para análise de categoria
class CategoryAnalysis {
  final String category;
  final double amount;
  final double percentage;
  final Color color;
  final IconData icon;
  final int transactionCount;
  final double averageAmount;

  CategoryAnalysis({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.icon,
    required this.transactionCount,
    required this.averageAmount,
  });

  Map<String, dynamic> toJson() => {
    'category': category,
    'amount': amount,
    'percentage': percentage,
    'color': color.value,
    'icon': icon.codePoint,
    'transactionCount': transactionCount,
    'averageAmount': averageAmount,
  };

  factory CategoryAnalysis.fromJson(Map<String, dynamic> json) => CategoryAnalysis(
    category: json['category'] ?? '',
    amount: json['amount']?.toDouble() ?? 0.0,
    percentage: json['percentage']?.toDouble() ?? 0.0,
    color: Color(json['color'] ?? 0xFF000000),
    icon: IconData(json['icon'] ?? 0, fontFamily: 'MaterialIcons'),
    transactionCount: json['transactionCount'] ?? 0,
    averageAmount: json['averageAmount']?.toDouble() ?? 0.0,
  );
}

/// Modelo para insights inteligentes
class FinancialInsight {
  final String title;
  final String description;
  final InsightType type;
  final double impact;
  final String recommendation;
  final DateTime date;

  FinancialInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.impact,
    required this.recommendation,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'type': type.toString(),
    'impact': impact,
    'recommendation': recommendation,
    'date': date.toIso8601String(),
  };

  factory FinancialInsight.fromJson(Map<String, dynamic> json) => FinancialInsight(
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    type: InsightType.values.firstWhere(
      (e) => e.toString() == json['type'],
      orElse: () => InsightType.info,
    ),
    impact: json['impact']?.toDouble() ?? 0.0,
    recommendation: json['recommendation'] ?? '',
    date: DateTime.parse(json['date']),
  );
}

/// Tipos de insights
enum InsightType {
  warning,
  success,
  info,
  alert,
}

/// Modelo para projeção financeira
class FinancialProjection {
  final DateTime date;
  final double projectedIncome;
  final double projectedExpense;
  final double projectedBalance;
  final double confidence; // 0.0 a 1.0
  final String basis; // 'historical', 'trend', 'seasonal'

  FinancialProjection({
    required this.date,
    required this.projectedIncome,
    required this.projectedExpense,
    required this.projectedBalance,
    required this.confidence,
    required this.basis,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'projectedIncome': projectedIncome,
    'projectedExpense': projectedExpense,
    'projectedBalance': projectedBalance,
    'confidence': confidence,
    'basis': basis,
  };

  factory FinancialProjection.fromJson(Map<String, dynamic> json) => FinancialProjection(
    date: DateTime.parse(json['date']),
    projectedIncome: json['projectedIncome']?.toDouble() ?? 0.0,
    projectedExpense: json['projectedExpense']?.toDouble() ?? 0.0,
    projectedBalance: json['projectedBalance']?.toDouble() ?? 0.0,
    confidence: json['confidence']?.toDouble() ?? 0.0,
    basis: json['basis'] ?? 'historical',
  );
}

/// Modelo para indicadores financeiros
class FinancialIndicators {
  final double monthlyAverageIncome;
  final double monthlyAverageExpense;
  final double savingsRate;
  final double expenseGrowthRate;
  final double incomeGrowthRate;
  final double debtToIncomeRatio;
  final double emergencyFundMonths;
  final double investmentRate;

  FinancialIndicators({
    required this.monthlyAverageIncome,
    required this.monthlyAverageExpense,
    required this.savingsRate,
    required this.expenseGrowthRate,
    required this.incomeGrowthRate,
    required this.debtToIncomeRatio,
    required this.emergencyFundMonths,
    required this.investmentRate,
  });

  Map<String, dynamic> toJson() => {
    'monthlyAverageIncome': monthlyAverageIncome,
    'monthlyAverageExpense': monthlyAverageExpense,
    'savingsRate': savingsRate,
    'expenseGrowthRate': expenseGrowthRate,
    'incomeGrowthRate': incomeGrowthRate,
    'debtToIncomeRatio': debtToIncomeRatio,
    'emergencyFundMonths': emergencyFundMonths,
    'investmentRate': investmentRate,
  };

  factory FinancialIndicators.fromJson(Map<String, dynamic> json) => FinancialIndicators(
    monthlyAverageIncome: json['monthlyAverageIncome']?.toDouble() ?? 0.0,
    monthlyAverageExpense: json['monthlyAverageExpense']?.toDouble() ?? 0.0,
    savingsRate: json['savingsRate']?.toDouble() ?? 0.0,
    expenseGrowthRate: json['expenseGrowthRate']?.toDouble() ?? 0.0,
    incomeGrowthRate: json['incomeGrowthRate']?.toDouble() ?? 0.0,
    debtToIncomeRatio: json['debtToIncomeRatio']?.toDouble() ?? 0.0,
    emergencyFundMonths: json['emergencyFundMonths']?.toDouble() ?? 0.0,
    investmentRate: json['investmentRate']?.toDouble() ?? 0.0,
  );
}

/// Modelo para relatório anual
class AnnualReport {
  final int year;
  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final double savingsRate;
  final List<CategoryAnalysis> topCategories;
  final List<FinancialTrend> monthlyTrends;
  final List<FinancialInsight> insights;
  final FinancialIndicators indicators;
  final List<FinancialProjection> projections;

  AnnualReport({
    required this.year,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.savingsRate,
    required this.topCategories,
    required this.monthlyTrends,
    required this.insights,
    required this.indicators,
    required this.projections,
  });

  Map<String, dynamic> toJson() => {
    'year': year,
    'totalIncome': totalIncome,
    'totalExpense': totalExpense,
    'totalSavings': totalSavings,
    'savingsRate': savingsRate,
    'topCategories': topCategories.map((c) => c.toJson()).toList(),
    'monthlyTrends': monthlyTrends.map((t) => t.toJson()).toList(),
    'insights': insights.map((i) => i.toJson()).toList(),
    'indicators': indicators.toJson(),
    'projections': projections.map((p) => p.toJson()).toList(),
  };

  factory AnnualReport.fromJson(Map<String, dynamic> json) => AnnualReport(
    year: json['year'] ?? DateTime.now().year,
    totalIncome: json['totalIncome']?.toDouble() ?? 0.0,
    totalExpense: json['totalExpense']?.toDouble() ?? 0.0,
    totalSavings: json['totalSavings']?.toDouble() ?? 0.0,
    savingsRate: json['savingsRate']?.toDouble() ?? 0.0,
    topCategories: (json['topCategories'] as List?)
        ?.map((c) => CategoryAnalysis.fromJson(c))
        .toList() ?? [],
    monthlyTrends: (json['monthlyTrends'] as List?)
        ?.map((t) => FinancialTrend.fromJson(t))
        .toList() ?? [],
    insights: (json['insights'] as List?)
        ?.map((i) => FinancialInsight.fromJson(i))
        .toList() ?? [],
    indicators: FinancialIndicators.fromJson(json['indicators'] ?? {}),
    projections: (json['projections'] as List?)
        ?.map((p) => FinancialProjection.fromJson(p))
        .toList() ?? [],
  );
}

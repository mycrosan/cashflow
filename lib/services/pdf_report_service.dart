import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/financial_analysis.dart';

class PDFReportService {
  static final PDFReportService _instance = PDFReportService._internal();
  factory PDFReportService() => _instance;
  PDFReportService._internal();

  /// Gera PDF do relatório mensal
  Future<Uint8List> generateMonthlyReportPDF({
    required List<FinancialTrend> trends,
    required List<CategoryAnalysis> categories,
    required List<FinancialInsight> insights,
    required FinancialIndicators indicators,
    required String period,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Relatório Financeiro Mensal'),
            pw.SizedBox(height: 20),
            _buildPeriodInfo(period, startDate, endDate),
            pw.SizedBox(height: 20),
            _buildSummaryCards(trends, indicators),
            pw.SizedBox(height: 20),
            _buildCategoryAnalysis(categories),
            pw.SizedBox(height: 20),
            _buildInsights(insights),
            pw.SizedBox(height: 20),
            _buildIndicators(indicators),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Gera PDF do relatório anual
  Future<Uint8List> generateAnnualReportPDF({
    required AnnualReport report,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader('Relatório Financeiro Anual - ${report.year}'),
            pw.SizedBox(height: 20),
            _buildAnnualSummary(report),
            pw.SizedBox(height: 20),
            _buildMonthlyTrends(report.monthlyTrends),
            pw.SizedBox(height: 20),
            _buildCategoryAnalysis(report.topCategories),
            pw.SizedBox(height: 20),
            _buildInsights(report.insights),
            pw.SizedBox(height: 20),
            _buildIndicators(report.indicators),
            pw.SizedBox(height: 20),
            _buildProjections(report.projections),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Imprime o relatório
  Future<void> printReport(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: title,
    );
  }

  /// Salva o relatório como arquivo
  Future<void> saveReportToFile(Uint8List pdfBytes, String fileName) async {
    // Implementar salvamento de arquivo
    // Depende da plataforma (mobile/desktop)
  }

  pw.Widget _buildHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Fluxo Família - Sistema de Gestão Financeira',
            style: const pw.TextStyle(
              fontSize: 14,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPeriodInfo(String period, DateTime startDate, DateTime endDate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Text(
            'Período: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            '${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
          ),
          pw.Spacer(),
          pw.Text(
            'Tipo: ${_getPeriodLabel(period)}',
            style: pw.TextStyle(
              color: PdfColors.blue700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCards(List<FinancialTrend> trends, FinancialIndicators indicators) {
    final totalIncome = trends.fold(0.0, (sum, t) => sum + t.income);
    final totalExpense = trends.fold(0.0, (sum, t) => sum + t.expense);
    final totalBalance = totalIncome - totalExpense;

    return pw.Row(
      children: [
        _buildSummaryCard('Receita Total', totalIncome, PdfColors.green),
        pw.SizedBox(width: 16),
        _buildSummaryCard('Despesa Total', totalExpense, PdfColors.red),
        pw.SizedBox(width: 16),
        _buildSummaryCard('Saldo Total', totalBalance, PdfColors.blue),
      ],
    );
  }

  pw.Widget _buildSummaryCard(String title, double value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              _formatCurrency(value),
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.blue900,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildAnnualSummary(AnnualReport report) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            'Resumo Anual ${report.year}',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _buildSummaryCard('Receita Anual', report.totalIncome, PdfColors.green),
              pw.SizedBox(width: 16),
              _buildSummaryCard('Despesa Anual', report.totalExpense, PdfColors.red),
              pw.SizedBox(width: 16),
              _buildSummaryCard('Poupança Anual', report.totalSavings, PdfColors.blue),
              pw.SizedBox(width: 16),
              _buildSummaryCard('Taxa Poupança', report.savingsRate, PdfColors.purple),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildCategoryAnalysis(List<CategoryAnalysis> categories) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Análise por Categoria',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Categoria', isHeader: true),
                _buildTableCell('Valor', isHeader: true),
                _buildTableCell('Percentual', isHeader: true),
                _buildTableCell('Transações', isHeader: true),
              ],
            ),
            ...categories.map((category) => pw.TableRow(
              children: [
                _buildTableCell(category.category),
                _buildTableCell(_formatCurrency(category.amount)),
                _buildTableCell('${category.percentage.toStringAsFixed(1)}%'),
                _buildTableCell(category.transactionCount.toString()),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildInsights(List<FinancialInsight> insights) {
    if (insights.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Insights Inteligentes',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        ...insights.map((insight) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                insight.title,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: _getInsightColor(insight.type),
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                insight.description,
                style: const pw.TextStyle(fontSize: 12),
              ),
              if (insight.recommendation.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(
                  'Recomendação: ${insight.recommendation}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.blue700,
                  ),
                ),
              ],
            ],
          ),
        )),
      ],
    );
  }

  pw.Widget _buildIndicators(FinancialIndicators indicators) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Indicadores Financeiros',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Indicador', isHeader: true),
                _buildTableCell('Valor', isHeader: true),
              ],
            ),
            pw.TableRow(children: [
              _buildTableCell('Receita Média Mensal'),
              _buildTableCell(_formatCurrency(indicators.monthlyAverageIncome)),
            ]),
            pw.TableRow(children: [
              _buildTableCell('Despesa Média Mensal'),
              _buildTableCell(_formatCurrency(indicators.monthlyAverageExpense)),
            ]),
            pw.TableRow(children: [
              _buildTableCell('Taxa de Poupança'),
              _buildTableCell('${indicators.savingsRate.toStringAsFixed(1)}%'),
            ]),
            pw.TableRow(children: [
              _buildTableCell('Crescimento Receita'),
              _buildTableCell('${indicators.incomeGrowthRate.toStringAsFixed(1)}%'),
            ]),
            pw.TableRow(children: [
              _buildTableCell('Crescimento Despesa'),
              _buildTableCell('${indicators.expenseGrowthRate.toStringAsFixed(1)}%'),
            ]),
            pw.TableRow(children: [
              _buildTableCell('Fundo Emergência'),
              _buildTableCell('${indicators.emergencyFundMonths.toStringAsFixed(1)} meses'),
            ]),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMonthlyTrends(List<FinancialTrend> trends) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Tendências Mensais',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Mês', isHeader: true),
                _buildTableCell('Receita', isHeader: true),
                _buildTableCell('Despesa', isHeader: true),
                _buildTableCell('Saldo', isHeader: true),
              ],
            ),
            ...trends.map((trend) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('MM/yyyy').format(trend.date)),
                _buildTableCell(_formatCurrency(trend.income)),
                _buildTableCell(_formatCurrency(trend.expense)),
                _buildTableCell(_formatCurrency(trend.balance)),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildProjections(List<FinancialProjection> projections) {
    if (projections.isEmpty) {
      return pw.SizedBox.shrink();
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Projeções Futuras',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey300),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(2),
            3: const pw.FlexColumnWidth(2),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Mês', isHeader: true),
                _buildTableCell('Receita Proj.', isHeader: true),
                _buildTableCell('Despesa Proj.', isHeader: true),
                _buildTableCell('Saldo Proj.', isHeader: true),
                _buildTableCell('Confiança', isHeader: true),
              ],
            ),
            ...projections.map((projection) => pw.TableRow(
              children: [
                _buildTableCell(DateFormat('MM/yyyy').format(projection.date)),
                _buildTableCell(_formatCurrency(projection.projectedIncome)),
                _buildTableCell(_formatCurrency(projection.projectedExpense)),
                _buildTableCell(_formatCurrency(projection.projectedBalance)),
                _buildTableCell('${(projection.confidence * 100).toStringAsFixed(0)}%'),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.Widget _buildFooter() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        'Relatório gerado automaticamente pelo Fluxo Família - Sistema de Gestão Financeira',
        style: const pw.TextStyle(
          fontSize: 10,
          color: PdfColors.grey600,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  String _getPeriodLabel(String period) {
    switch (period) {
      case 'daily':
        return 'Diário';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensal';
      case 'yearly':
        return 'Anual';
      default:
        return 'Mensal';
    }
  }

  PdfColor _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.success:
        return PdfColors.green;
      case InsightType.warning:
        return PdfColors.orange;
      case InsightType.alert:
        return PdfColors.red;
      case InsightType.info:
        return PdfColors.blue;
    }
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'R\$ ${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    } else {
      return 'R\$ ${value.toStringAsFixed(0)}';
    }
  }
}

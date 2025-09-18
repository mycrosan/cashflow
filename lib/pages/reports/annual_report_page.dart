import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/financial_analysis_provider.dart';
import '../../widgets/charts/trends_chart.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/financial_indicators_widget.dart';
import '../../widgets/insights_widget.dart';
import '../../services/pdf_report_service.dart';
import '../../models/financial_analysis.dart';

class AnnualReportPage extends StatefulWidget {
  const AnnualReportPage({super.key});

  @override
  _AnnualReportPageState createState() => _AnnualReportPageState();
}

class _AnnualReportPageState extends State<AnnualReportPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PDFReportService _pdfService = PDFReportService();
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAnnualReport();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório Anual $_selectedYear'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(icon: Icon(Icons.summarize), text: 'Resumo'),
            Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Categorias'),
            Tab(icon: Icon(Icons.analytics), text: 'Análise'),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            onSelected: (year) {
              setState(() {
                _selectedYear = year;
              });
              _generateAnnualReport();
            },
            itemBuilder: (context) {
              final currentYear = DateTime.now().year;
              return List.generate(5, (index) {
                final year = currentYear - index;
                return PopupMenuItem(
                  value: year,
                  child: Text('$year'),
                );
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Exportar PDF'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print),
                    SizedBox(width: 8),
                    Text('Imprimir'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FinancialAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isGeneratingReport) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Gerando relatório anual...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${provider.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _generateAnnualReport,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (provider.annualReport == null) {
            return const Center(
              child: Text('Nenhum relatório anual disponível'),
            );
          }

          final report = provider.annualReport!;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(report),
              _buildTrendsTab(report),
              _buildCategoriesTab(report),
              _buildAnalysisTab(report),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryTab(AnnualReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAnnualSummaryCard(report),
          const SizedBox(height: 20),
          _buildKeyMetricsCard(report),
          const SizedBox(height: 20),
          _buildYearComparisonCard(),
        ],
      ),
    );
  }

  Widget _buildTrendsTab(AnnualReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolução Mensal $_selectedYear',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TrendsChart(
                    trends: report.monthlyTrends,
                    selectedPeriod: 'monthly',
                    showIncome: true,
                    showExpense: true,
                    showBalance: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildMonthlyDetailsCard(report),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(AnnualReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distribuição por Categoria',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CategoryPieChart(
                    categories: report.topCategories,
                    maxItems: 8,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCategoryDetailsCard(report),
        ],
      ),
    );
  }

  Widget _buildAnalysisTab(AnnualReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FinancialIndicatorsWidget(indicators: report.indicators),
          const SizedBox(height: 20),
          InsightsWidget(insights: report.insights),
          const SizedBox(height: 20),
          _buildProjectionsCard(report),
        ],
      ),
    );
  }

  Widget _buildAnnualSummaryCard(AnnualReport report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Resumo Anual $_selectedYear',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Receita Anual',
                    _formatCurrency(report.totalIncome),
                    Colors.green,
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Despesa Anual',
                    _formatCurrency(report.totalExpense),
                    Colors.red,
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Poupança Anual',
                    _formatCurrency(report.totalSavings),
                    Colors.blue,
                    Icons.savings,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryItem(
                    'Taxa de Poupança',
                    '${report.savingsRate.toStringAsFixed(1)}%',
                    _getSavingsRateColor(report.savingsRate),
                    Icons.percent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyMetricsCard(AnnualReport report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métricas Principais',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricItem(
                  'Receita Média Mensal',
                  _formatCurrency(report.indicators.monthlyAverageIncome),
                  Colors.green,
                ),
                _buildMetricItem(
                  'Despesa Média Mensal',
                  _formatCurrency(report.indicators.monthlyAverageExpense),
                  Colors.red,
                ),
                _buildMetricItem(
                  'Crescimento Receita',
                  '${report.indicators.incomeGrowthRate.toStringAsFixed(1)}%',
                  report.indicators.incomeGrowthRate >= 0 ? Colors.green : Colors.red,
                ),
                _buildMetricItem(
                  'Crescimento Despesa',
                  '${report.indicators.expenseGrowthRate.toStringAsFixed(1)}%',
                  report.indicators.expenseGrowthRate <= 0 ? Colors.green : Colors.red,
                ),
                _buildMetricItem(
                  'Fundo Emergência',
                  '${report.indicators.emergencyFundMonths.toStringAsFixed(1)} meses',
                  _getEmergencyFundColor(report.indicators.emergencyFundMonths),
                ),
                _buildMetricItem(
                  'Taxa Investimento',
                  '${report.indicators.investmentRate.toStringAsFixed(1)}%',
                  Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearComparisonCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparativo Anual',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Funcionalidade em desenvolvimento',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyDetailsCard(AnnualReport report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detalhes Mensais',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            ...report.monthlyTrends.map((trend) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_getMonthName(trend.date.month)} ${trend.date.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    _formatCurrency(trend.income),
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _formatCurrency(trend.expense),
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _formatCurrency(trend.balance),
                    style: TextStyle(
                      color: trend.balance >= 0 ? Colors.blue : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDetailsCard(AnnualReport report) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categorias de Gastos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            ...report.topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: category.color,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.category,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${category.percentage.toStringAsFixed(1)}% • ${category.transactionCount} transações',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatCurrency(category.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionsCard(AnnualReport report) {
    if (report.projections.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projeções para o Próximo Ano',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            ...report.projections.take(6).map((projection) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_getMonthName(projection.date.month)} ${projection.date.year}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Text(
                    _formatCurrency(projection.projectedBalance),
                    style: TextStyle(
                      color: projection.projectedBalance >= 0 ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(projection.confidence * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _generateAnnualReport() {
    context.read<FinancialAnalysisProvider>().generateAnnualReport(_selectedYear);
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export_pdf':
        _exportToPDF();
        break;
      case 'print':
        _printReport();
        break;
    }
  }

  Future<void> _exportToPDF() async {
    final provider = context.read<FinancialAnalysisProvider>();
    
    if (provider.annualReport == null) return;

    try {
      final pdfBytes = await _pdfService.generateAnnualReportPDF(
        report: provider.annualReport!,
      );

      await _pdfService.printReport(pdfBytes, 'Relatório Anual $_selectedYear');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Relatório PDF gerado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _printReport() async {
    // Implementar impressão
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de impressão em desenvolvimento'),
        backgroundColor: Colors.orange,
      ),
    );
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

  Color _getSavingsRateColor(double rate) {
    if (rate >= 20) return Colors.green;
    if (rate >= 10) return Colors.orange;
    return Colors.red;
  }

  Color _getEmergencyFundColor(double months) {
    if (months >= 6) return Colors.green;
    if (months >= 3) return Colors.orange;
    return Colors.red;
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
      'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'
    ];
    return months[month - 1];
  }
}

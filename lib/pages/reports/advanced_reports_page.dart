import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/financial_analysis_provider.dart';
import '../../widgets/charts/trends_chart.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/projections_chart.dart';
import '../../widgets/financial_indicators_widget.dart';
import '../../widgets/insights_widget.dart';
import '../../services/pdf_report_service.dart';
import 'annual_report_page.dart';

class AdvancedReportsPage extends StatefulWidget {
  @override
  _AdvancedReportsPageState createState() => _AdvancedReportsPageState();
}

class _AdvancedReportsPageState extends State<AdvancedReportsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final PDFReportService _pdfService = PDFReportService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FinancialAnalysisProvider>().loadFinancialAnalysis();
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
        title: Text('Relatórios Avançados'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(icon: Icon(Icons.trending_up), text: 'Tendências'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Categorias'),
            Tab(icon: Icon(Icons.analytics), text: 'Indicadores'),
            Tab(icon: Icon(Icons.lightbulb), text: 'Insights'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'filters',
                child: Row(
                  children: [
                    Icon(Icons.filter_list),
                    SizedBox(width: 8),
                    Text('Filtros'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'export_pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf),
                    SizedBox(width: 8),
                    Text('Exportar PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'annual_report',
                child: Row(
                  children: [
                    Icon(Icons.calendar_today),
                    SizedBox(width: 8),
                    Text('Relatório Anual'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FinancialAnalysisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Carregando análise financeira...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Erro: ${provider.error}',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadFinancialAnalysis(),
                    child: Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTrendsTab(provider),
              _buildCategoriesTab(provider),
              _buildIndicatorsTab(provider),
              _buildInsightsTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTrendsTab(FinancialAnalysisProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPeriodSelector(provider),
          SizedBox(height: 20),
          _buildChartTypeSelector(provider),
          SizedBox(height: 20),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Evolução Financeira',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                  SizedBox(height: 16),
                  TrendsChart(
                    trends: provider.trends,
                    selectedPeriod: provider.selectedPeriod,
                    showIncome: true,
                    showExpense: true,
                    showBalance: true,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildProjectionsCard(provider),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(FinancialAnalysisProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  SizedBox(height: 16),
                  CategoryPieChart(
                    categories: provider.categoryAnalysis,
                    maxItems: 5,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          _buildTopCategoriesCard(provider),
        ],
      ),
    );
  }

  Widget _buildIndicatorsTab(FinancialAnalysisProvider provider) {
    if (provider.indicators == null) {
      return Center(
        child: Text('Nenhum indicador disponível'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          FinancialIndicatorsWidget(indicators: provider.indicators!),
          SizedBox(height: 20),
          _buildSummaryCard(provider),
        ],
      ),
    );
  }

  Widget _buildInsightsTab(FinancialAnalysisProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          InsightsWidget(insights: provider.insights),
          SizedBox(height: 20),
          _buildSavingsPotentialCard(provider),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(FinancialAnalysisProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Período de Análise',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 12),
            Column(
              children: [
                DropdownButtonFormField<String>(
                  value: provider.selectedPeriod,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Período',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(value: 'daily', child: Text('Diário')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensal')),
                    DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      provider.updateFilters(period: value);
                    }
                  },
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Data Inicial',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: provider.startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            provider.updateFilters(startDate: date);
                          }
                        },
                        controller: TextEditingController(
                          text: '${provider.startDate.day.toString().padLeft(2, '0')}/${provider.startDate.month.toString().padLeft(2, '0')}/${provider.startDate.year}',
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Data Final',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: provider.endDate,
                            firstDate: provider.startDate,
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            provider.updateFilters(endDate: date);
                          }
                        },
                        controller: TextEditingController(
                          text: '${provider.endDate.day.toString().padLeft(2, '0')}/${provider.endDate.month.toString().padLeft(2, '0')}/${provider.endDate.year}',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeSelector(FinancialAnalysisProvider provider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tipo de Gráfico',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: Text('Receitas'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Despesas'),
                  selected: true,
                  onSelected: (selected) {},
                ),
                FilterChip(
                  label: Text('Saldo'),
                  selected: true,
                  onSelected: (selected) {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionsCard(FinancialAnalysisProvider provider) {
    if (provider.projections.isEmpty) {
      return SizedBox.shrink();
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
              'Projeções Futuras',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 16),
            ProjectionsChart(
              historicalTrends: provider.trends,
              projections: provider.projections,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCategoriesCard(FinancialAnalysisProvider provider) {
    final topCategories = provider.getTopCategories(limit: 10);

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
            SizedBox(height: 16),
            ...topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 8),
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
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.category,
                            style: TextStyle(
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
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(FinancialAnalysisProvider provider) {
    final summary = provider.getFinancialSummary();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo Financeiro',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryItem(
                        'Receita Total',
                        _formatCurrency(summary['totalIncome']!),
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _buildSummaryItem(
                        'Despesa Total',
                        _formatCurrency(summary['totalExpense']!),
                        Colors.red,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildSummaryItem(
                  'Saldo Total',
                  _formatCurrency(summary['totalBalance']!),
                  summary['totalBalance']! >= 0 ? Colors.blue : Colors.red,
                  Icons.account_balance,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSavingsPotentialCard(FinancialAnalysisProvider provider) {
    final potentialSavings = provider.calculatePotentialSavings();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Economia Potencial',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.savings, color: Colors.green[600], size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baseado nos insights identificados',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[800],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _formatCurrency(potentialSavings),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'filters':
        _showFiltersDialog();
        break;
      case 'export_pdf':
        _exportToPDF();
        break;
      case 'annual_report':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AnnualReportPage(),
          ),
        );
        break;
    }
  }

  void _showFiltersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filtros Avançados'),
        content: Text('Funcionalidade em desenvolvimento'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPDF() async {
    final provider = context.read<FinancialAnalysisProvider>();
    
    try {
      final pdfBytes = await _pdfService.generateMonthlyReportPDF(
        trends: provider.trends,
        categories: provider.categoryAnalysis,
        insights: provider.insights,
        indicators: provider.indicators!,
        period: provider.selectedPeriod,
        startDate: provider.startDate,
        endDate: provider.endDate,
      );

      await _pdfService.printReport(pdfBytes, 'Relatório Financeiro');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

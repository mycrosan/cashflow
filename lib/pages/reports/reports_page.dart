import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'advanced_reports_page.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  _ReportsPageState createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatórios'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Consumer<ReportProvider>(
        builder: (context, reportProvider, child) {
          if (reportProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios Financeiros',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Botão para relatórios avançados
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvancedReportsPage(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.indigo[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.analytics,
                              color: Colors.indigo[700],
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Relatórios Avançados',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.indigo[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Gráficos interativos, insights inteligentes e análises preditivas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey[400],
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resumo mensal compacto
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumo Mensal',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactSummaryCard(
                                'Receitas',
                                reportProvider.totalIncome,
                                Colors.green,
                                Icons.trending_up,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCompactSummaryCard(
                                'Despesas',
                                reportProvider.totalExpense,
                                Colors.red,
                                Icons.trending_down,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildCompactSummaryCard(
                                'Saldo',
                                reportProvider.balance,
                                reportProvider.balance >= 0 ? Colors.green : Colors.red,
                                Icons.account_balance_wallet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Top categorias de despesa
                if (reportProvider.expensesByCategory.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Categorias de Despesa',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...reportProvider.getTopExpenseCategories().map((entry) {
                            final percentage = reportProvider.formatPercentage(
                              entry.value,
                              reportProvider.totalExpense,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.red.withOpacity(0.1),
                                child: const Icon(Icons.category, color: Colors.red),
                              ),
                              title: Text(entry.key),
                              subtitle: Text(percentage),
                              trailing: Text(
                                reportProvider.formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Top categorias de receita
                if (reportProvider.incomeByCategory.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Categorias de Receita',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...reportProvider.getTopIncomeCategories().map((entry) {
                            final percentage = reportProvider.formatPercentage(
                              entry.value,
                              reportProvider.totalIncome,
                            );
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.withOpacity(0.1),
                                child: const Icon(Icons.category, color: Colors.green),
                              ),
                              title: Text(entry.key),
                              subtitle: Text(percentage),
                              trailing: Text(
                                reportProvider.formatCurrency(entry.value),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Ações
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Relatório Anual',
                        onPressed: () {
                          // TODO: Implementar relatório anual
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Relatório anual em desenvolvimento')),
                          );
                        },
                        outlined: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Exportar PDF',
                        onPressed: () {
                          // TODO: Implementar exportação PDF
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Exportação PDF em desenvolvimento')),
                          );
                        },
                        outlined: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummaryCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            NumberFormat.currency(
              locale: 'pt_BR',
              symbol: 'R\$',
              decimalDigits: 0,
            ).format(value),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

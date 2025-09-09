import 'package:flutter/material.dart';
import '../models/financial_analysis.dart';

class FinancialIndicatorsWidget extends StatelessWidget {
  final FinancialIndicators indicators;

  const FinancialIndicatorsWidget({
    Key? key,
    required this.indicators,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Indicadores Financeiros',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.indigo[700],
              ),
            ),
            const SizedBox(height: 16),
            _buildIndicatorsGrid(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicatorsGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          children: [
        _buildIndicatorCard(
          context,
          'Receita Média',
          _formatCurrency(indicators.monthlyAverageIncome),
          Icons.trending_up,
          Colors.green,
        ),
        _buildIndicatorCard(
          context,
          'Despesa Média',
          _formatCurrency(indicators.monthlyAverageExpense),
          Icons.trending_down,
          Colors.red,
        ),
        _buildIndicatorCard(
          context,
          'Taxa de Poupança',
          '${indicators.savingsRate.toStringAsFixed(1)}%',
          Icons.savings,
          _getSavingsRateColor(indicators.savingsRate),
        ),
        _buildIndicatorCard(
          context,
          'Crescimento Receita',
          '${indicators.incomeGrowthRate.toStringAsFixed(1)}%',
          Icons.arrow_upward,
          indicators.incomeGrowthRate >= 0 ? Colors.green : Colors.red,
        ),
        _buildIndicatorCard(
          context,
          'Crescimento Despesa',
          '${indicators.expenseGrowthRate.toStringAsFixed(1)}%',
          Icons.arrow_downward,
          indicators.expenseGrowthRate <= 0 ? Colors.green : Colors.red,
        ),
        _buildIndicatorCard(
          context,
          'Fundo Emergência',
          '${indicators.emergencyFundMonths.toStringAsFixed(1)} meses',
          Icons.security,
          _getEmergencyFundColor(indicators.emergencyFundMonths),
        ),
        _buildIndicatorCard(
          context,
          'Taxa Investimento',
          '${indicators.investmentRate.toStringAsFixed(1)}%',
          Icons.account_balance,
          Colors.blue,
        ),
        _buildIndicatorCard(
          context,
          'Rel. Dívida/Renda',
          '${indicators.debtToIncomeRatio.toStringAsFixed(1)}%',
          Icons.credit_card,
          _getDebtRatioColor(indicators.debtToIncomeRatio),
        ),
      ],
        );
      },
    );
  }

  Widget _buildIndicatorCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
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

  Color _getDebtRatioColor(double ratio) {
    if (ratio <= 20) return Colors.green;
    if (ratio <= 40) return Colors.orange;
    return Colors.red;
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

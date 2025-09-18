import 'package:flutter/material.dart';
import '../models/financial_analysis.dart';

class InsightsWidget extends StatelessWidget {
  final List<FinancialInsight> insights;

  const InsightsWidget({
    super.key,
    required this.insights,
  });

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'Nenhum insight disponível',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[600],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Insights Inteligentes',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...insights.map((insight) => _buildInsightCard(context, insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, FinancialInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _getInsightColor(insight.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getInsightColor(insight.type).withOpacity(0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getInsightIcon(insight.type),
                  color: _getInsightColor(insight.type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getInsightColor(insight.type),
                    ),
                  ),
                ),
                if (insight.impact > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getInsightColor(insight.type),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${insight.impact.toStringAsFixed(0)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (insight.recommendation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: Colors.blue[600],
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        insight.recommendation,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[800],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(insight.date),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.success:
        return Colors.green;
      case InsightType.warning:
        return Colors.orange;
      case InsightType.alert:
        return Colors.red;
      case InsightType.info:
        return Colors.blue;
    }
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.success:
        return Icons.check_circle;
      case InsightType.warning:
        return Icons.warning;
      case InsightType.alert:
        return Icons.error;
      case InsightType.info:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Hoje';
    } else if (difference.inDays == 1) {
      return 'Ontem';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} dias atrás';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }
  }
}

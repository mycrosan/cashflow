import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/financial_analysis.dart';

class TrendsChart extends StatefulWidget {
  final List<FinancialTrend> trends;
  final String selectedPeriod;
  final bool showIncome;
  final bool showExpense;
  final bool showBalance;

  const TrendsChart({
    Key? key,
    required this.trends,
    required this.selectedPeriod,
    this.showIncome = true,
    this.showExpense = true,
    this.showBalance = true,
  }) : super(key: key);

  @override
  State<TrendsChart> createState() => _TrendsChartState();
}

class _TrendsChartState extends State<TrendsChart> {

  @override
  Widget build(BuildContext context) {
    if (widget.trends.isEmpty) {
      return Container(
        height: 300,
        child: Center(
          child: Text(
            'Nenhum dado disponível',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: _calculateInterval(),
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateXAxisInterval(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < widget.trends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatXAxisLabel(widget.trends[index].date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    );
                  }
                  return Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: _calculateInterval(),
                getTitlesWidget: (value, meta) {
                  return Text(
                    _formatCurrency(value),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minX: 0,
          maxX: (widget.trends.length - 1).toDouble(),
          minY: _calculateMinY(),
          maxY: _calculateMaxY(),
          lineBarsData: _buildLineBarsData(),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: Colors.blue[900]!.withOpacity(0.8),
              tooltipRoundedRadius: 8,
              tooltipPadding: const EdgeInsets.all(8),
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final trend = widget.trends[touchedSpot.x.toInt()];
                  return LineTooltipItem(
                    '${_formatDate(trend.date)}\n'
                    '${widget.showIncome ? 'Receita: ${_formatCurrency(trend.income)}\n' : ''}'
                    '${widget.showExpense ? 'Despesa: ${_formatCurrency(trend.expense)}\n' : ''}'
                    '${widget.showBalance ? 'Saldo: ${_formatCurrency(trend.balance)}' : ''}',
                    TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                  FlDotData(
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 6,
                        color: Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      );
                    },
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLineBarsData() {
    final List<LineChartBarData> lineBarsData = [];

    if (widget.showIncome) {
      lineBarsData.add(
        LineChartBarData(
          spots: widget.trends.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.income);
          }).toList(),
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
      );
    }

    if (widget.showExpense) {
      lineBarsData.add(
        LineChartBarData(
          spots: widget.trends.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.expense);
          }).toList(),
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.red,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withOpacity(0.1),
          ),
        ),
      );
    }

    if (widget.showBalance) {
      lineBarsData.add(
        LineChartBarData(
          spots: widget.trends.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.balance);
          }).toList(),
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
        ),
      );
    }

    return lineBarsData;
  }

  double _calculateInterval() {
    if (widget.trends.isEmpty) return 1000;
    
    final maxValue = widget.trends.fold(0.0, (max, trend) {
      return [
        max,
        trend.income,
        trend.expense,
        trend.balance,
      ].reduce((a, b) => a > b ? a : b);
    });

    return (maxValue / 5).roundToDouble();
  }

  double _calculateXAxisInterval() {
    final length = widget.trends.length;
    if (length <= 5) return 1;
    if (length <= 10) return 2;
    return (length / 5).ceilToDouble();
  }

  double _calculateMinY() {
    if (widget.trends.isEmpty) return 0;
    
    double minValue = double.infinity;
    for (final trend in widget.trends) {
      if (widget.showIncome) minValue = minValue < trend.income ? minValue : trend.income;
      if (widget.showExpense) minValue = minValue < trend.expense ? minValue : trend.expense;
      if (widget.showBalance) minValue = minValue < trend.balance ? minValue : trend.balance;
    }
    
    return minValue * 0.9; // 10% de margem
  }

  double _calculateMaxY() {
    if (widget.trends.isEmpty) return 1000;
    
    double maxValue = 0;
    for (final trend in widget.trends) {
      if (widget.showIncome) maxValue = maxValue > trend.income ? maxValue : trend.income;
      if (widget.showExpense) maxValue = maxValue > trend.expense ? maxValue : trend.expense;
      if (widget.showBalance) maxValue = maxValue > trend.balance ? maxValue : trend.balance;
    }
    
    return maxValue * 1.1; // 10% de margem
  }

  String _formatXAxisLabel(DateTime date) {
    switch (widget.selectedPeriod) {
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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

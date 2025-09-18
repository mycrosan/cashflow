import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/financial_analysis.dart';

class ProjectionsChart extends StatefulWidget {
  final List<FinancialTrend> historicalTrends;
  final List<FinancialProjection> projections;

  const ProjectionsChart({
    super.key,
    required this.historicalTrends,
    required this.projections,
  });

  @override
  State<ProjectionsChart> createState() => _ProjectionsChartState();
}

class _ProjectionsChartState extends State<ProjectionsChart> {

  @override
  Widget build(BuildContext context) {
    if (widget.historicalTrends.isEmpty && widget.projections.isEmpty) {
      return SizedBox(
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
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _calculateXAxisInterval(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < widget.historicalTrends.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatXAxisLabel(widget.historicalTrends[index].date),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    );
                  } else if (index < widget.historicalTrends.length + widget.projections.length) {
                    final projectionIndex = index - widget.historicalTrends.length;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _formatXAxisLabel(widget.projections[projectionIndex].date),
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
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
          maxX: (widget.historicalTrends.length + widget.projections.length - 1).toDouble(),
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
                  final index = touchedSpot.x.toInt();
                  if (index < widget.historicalTrends.length) {
                    final trend = widget.historicalTrends[index];
                    return LineTooltipItem(
                      '${_formatDate(trend.date)}\n'
                      'Saldo: ${_formatCurrency(trend.balance)}\n'
                      'Dados Históricos',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    );
                  } else {
                    final projectionIndex = index - widget.historicalTrends.length;
                    final projection = widget.projections[projectionIndex];
                    return LineTooltipItem(
                      '${_formatDate(projection.date)}\n'
                      'Saldo Projetado: ${_formatCurrency(projection.projectedBalance)}\n'
                      'Confiança: ${(projection.confidence * 100).toStringAsFixed(0)}%\n'
                      'Base: ${_getBasisLabel(projection.basis)}',
                      const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    );
                  }
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
            getTouchedSpotIndicator: (barData, spotIndexes) {
              return spotIndexes.map((spotIndex) {
                return TouchedSpotIndicatorData(
                  const FlLine(
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

    // Dados históricos
    if (widget.historicalTrends.isNotEmpty) {
      lineBarsData.add(
        LineChartBarData(
          spots: widget.historicalTrends.asMap().entries.map((entry) {
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
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withOpacity(0.1),
          ),
        ),
      );
    }

    // Projeções
    if (widget.projections.isNotEmpty) {
      final projectionSpots = widget.projections.asMap().entries.map((entry) {
        final x = widget.historicalTrends.length + entry.key.toDouble();
        return FlSpot(x, entry.value.projectedBalance);
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: projectionSpots,
          isCurved: true,
          color: Colors.orange,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.orange,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          dashArray: [5, 5], // Linha tracejada para projeções
        ),
      );

      // Área de confiança (simplificada)
      final confidenceSpots = widget.projections.asMap().entries.map((entry) {
        final x = widget.historicalTrends.length + entry.key.toDouble();
        final projection = entry.value;
        final confidence = projection.confidence;
        final upperBound = projection.projectedBalance * (1 + (1 - confidence));
        return FlSpot(x, upperBound);
      }).toList();

      lineBarsData.add(
        LineChartBarData(
          spots: confidenceSpots,
          isCurved: true,
          color: Colors.orange.withOpacity(0.3),
          barWidth: 1,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.orange.withOpacity(0.1),
          ),
        ),
      );
    }

    return lineBarsData;
  }

  double _calculateInterval() {
    final allValues = <double>[];
    
    for (final trend in widget.historicalTrends) {
      allValues.add(trend.balance);
    }
    
    for (final projection in widget.projections) {
      allValues.add(projection.projectedBalance);
    }

    if (allValues.isEmpty) return 1000;
    
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    return (maxValue / 5).roundToDouble();
  }

  double _calculateXAxisInterval() {
    final totalLength = widget.historicalTrends.length + widget.projections.length;
    if (totalLength <= 5) return 1;
    if (totalLength <= 10) return 2;
    return (totalLength / 5).ceilToDouble();
  }

  double _calculateMinY() {
    final allValues = <double>[];
    
    for (final trend in widget.historicalTrends) {
      allValues.add(trend.balance);
    }
    
    for (final projection in widget.projections) {
      allValues.add(projection.projectedBalance);
    }

    if (allValues.isEmpty) return 0;
    
    final minValue = allValues.reduce((a, b) => a < b ? a : b);
    return minValue * 0.9; // 10% de margem
  }

  double _calculateMaxY() {
    final allValues = <double>[];
    
    for (final trend in widget.historicalTrends) {
      allValues.add(trend.balance);
    }
    
    for (final projection in widget.projections) {
      allValues.add(projection.projectedBalance);
    }

    if (allValues.isEmpty) return 1000;
    
    final maxValue = allValues.reduce((a, b) => a > b ? a : b);
    return maxValue * 1.1; // 10% de margem
  }

  String _formatXAxisLabel(DateTime date) {
    return '${date.month}/${date.year}';
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

  String _getBasisLabel(String basis) {
    switch (basis) {
      case 'historical':
        return 'Histórico';
      case 'trend':
        return 'Tendência';
      case 'seasonal':
        return 'Sazonal';
      case 'trend_seasonal':
        return 'Tendência + Sazonal';
      default:
        return 'Desconhecido';
    }
  }
}

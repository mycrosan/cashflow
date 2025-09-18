import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/financial_analysis.dart';

class CategoryPieChart extends StatefulWidget {
  final List<CategoryAnalysis> categories;
  final int maxItems;

  const CategoryPieChart({
    super.key,
    required this.categories,
    this.maxItems = 5,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
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

    final displayCategories = widget.categories.take(widget.maxItems).toList();
    final othersAmount = widget.categories
        .skip(widget.maxItems)
        .fold(0.0, (sum, category) => sum + category.amount);

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Gráfico de pizza
          Expanded(
            flex: 2,
            child: Center(
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (event is FlTapUpEvent && pieTouchResponse?.touchedSection != null) {
                          _selectedIndex = pieTouchResponse!.touchedSection!.touchedSectionIndex;
                        } else {
                          _selectedIndex = -1;
                        }
                      });
                    },
                  ),
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: _buildSections(displayCategories, othersAmount),
                ),
              ),
            ),
          ),
          // Legenda
          Expanded(
            flex: 1,
            child: _buildLegend(displayCategories, othersAmount),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<CategoryAnalysis> categories,
    double othersAmount,
  ) {
    final sections = <PieChartSectionData>[];
    
    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final isSelected = _selectedIndex == i;
      
      sections.add(
        PieChartSectionData(
          color: category.color,
          value: category.amount,
          title: '${category.percentage.toStringAsFixed(1)}%',
          radius: isSelected ? 80 : 70,
          titleStyle: TextStyle(
            fontSize: isSelected ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Icon(
            category.icon,
            color: Colors.white,
            size: isSelected ? 20 : 16,
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    // Adicionar seção "Outros" se houver
    if (othersAmount > 0) {
      final othersPercentage = (othersAmount / 
          (categories.fold(0.0, (sum, c) => sum + c.amount) + othersAmount)) * 100;
      
      sections.add(
        PieChartSectionData(
          color: Colors.grey[400]!,
          value: othersAmount,
          title: '${othersPercentage.toStringAsFixed(1)}%',
          radius: _selectedIndex == categories.length ? 80 : 70,
          titleStyle: TextStyle(
            fontSize: _selectedIndex == categories.length ? 14 : 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: _selectedIndex == categories.length ? 20 : 16,
          ),
          badgePositionPercentageOffset: 1.3,
        ),
      );
    }

    return sections;
  }

  Widget _buildLegend(List<CategoryAnalysis> categories, double othersAmount) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...categories.asMap().entries.map((entry) {
          final index = entry.key;
          final category = entry.value;
          final isSelected = _selectedIndex == index;
          
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                    border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.category,
                        style: TextStyle(
                          fontSize: isSelected ? 14 : 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? category.color : Colors.grey[700],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatCurrency(category.amount),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        
        if (othersAmount > 0) ...[
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                    border: _selectedIndex == categories.length 
                        ? Border.all(color: Colors.black, width: 2) 
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outros',
                        style: TextStyle(
                          fontSize: _selectedIndex == categories.length ? 14 : 12,
                          fontWeight: _selectedIndex == categories.length 
                              ? FontWeight.bold 
                              : FontWeight.normal,
                          color: _selectedIndex == categories.length 
                              ? Colors.grey[700] 
                              : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatCurrency(othersAmount),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
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
}

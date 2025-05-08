import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:orcamentos_app/gastos_variados_page/formatters.dart';

class GraficoGastoCategorias extends StatelessWidget {
  final Map<String, double> categoryData;
  final double height;
  final double barWidth;
  final String title;
  final TextStyle? titleStyle;
  final EdgeInsetsGeometry? padding;

  const GraficoGastoCategorias({
    super.key,
    required this.categoryData,
    this.height = 350,
    this.barWidth = 20,
    this.title = '',
    this.titleStyle,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final categories = categoryData.keys.toList();
    final values = categoryData.values.toList();
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      margin: padding ?? const EdgeInsets.all(5),
      child: Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título do gráfico
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                title,
                style: titleStyle ?? theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo[700],
                ),
              ),
            ),
          
          // Gráfico
          SizedBox(
            height: title.isNotEmpty ? height - 30 : height,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(
                  border: const Border(
                    top: BorderSide.none,
                    right: BorderSide.none,
                    left: BorderSide(width: 1, color: Colors.grey),
                    bottom: BorderSide(width: 1, color: Colors.grey),
                  ),
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final category = categories[groupIndex];
                      final value = rod.toY;
                      return BarTooltipItem(
                        '$category\n${formatarValor(value)}',
                        const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                alignment: BarChartAlignment.spaceEvenly,
                groupsSpace: 16,
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt() - 1;
                        if (index < 0 || index >= categories.length) return const SizedBox();
                        
                        return SizedBox(
                          width: 15,
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                categories[index],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        );
                      },
                      reservedSize: 120,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: _calculateInterval(maxValue),
                      reservedSize: 80,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            formatarValor(value),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                ),
                barGroups: List.generate(categories.length, (index) {
                  return BarChartGroupData(
                    x: index + 1,
                    barRods: [
                      BarChartRodData(
                        fromY: 0,
                        toY: values[index],
                        width: barWidth,
                        color: _getCategoryColor(index),
                        borderRadius: BorderRadius.zero,
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ),
    );
    
    
  }

  Color _getCategoryColor(int index) {
    final colors = [
      Colors.indigoAccent,
      Colors.tealAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.redAccent,
      Colors.amberAccent,
    ];
    return colors[index % colors.length];
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 200) return 25;
    if (maxValue <= 500) return 50;
    if (maxValue <= 1000) return 100;
    if (maxValue <= 2000) return 200;
    if (maxValue <= 5000) return 500;
    if (maxValue <= 10000) return 1000;
    return 2000;
  }
}
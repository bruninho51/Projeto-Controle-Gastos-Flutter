import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:orcamentos_app/utils/formatters.dart';

class GraficoGastoCategorias extends StatefulWidget {
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
  State<GraficoGastoCategorias> createState() => _GraficoGastoCategoriasState();
}

class _GraficoGastoCategoriasState extends State<GraficoGastoCategorias> {
  int _touchedIndex = -1;

  // ─── Paleta indigo consistente com o resto do app ───────────────────────────
  static const List<Color> _palette = [
    Color(0xFF3949AB), // indigo
    Color(0xFF00897B), // teal
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFF5E35B1), // deep purple
    Color(0xFFF4511E), // deep orange
    Color(0xFF039BE5), // light blue
    Color(0xFFE53935), // red
    Color(0xFF00ACC1), // cyan
    Color(0xFF8E24AA), // purple
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  // ─── Ordena por valor decrescente ───────────────────────────────────────────
  List<MapEntry<String, double>> get _sortedEntries {
    final entries = widget.categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  double get _maxValue {
    final values = widget.categoryData.values;
    if (values.isEmpty) return 1;
    return values.reduce((a, b) => a > b ? a : b);
  }

  double _calculateInterval(double maxValue) {
    if (maxValue <= 200) return 50;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 2000) return 500;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    if (maxValue <= 50000) return 10000;
    return 20000;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _sortedEntries;
    if (entries.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        // Largura da barra adaptativa
        final double adaptiveBarWidth = isWide
            ? (widget.barWidth).clamp(16.0, 32.0)
            : (constraints.maxWidth / (entries.length * 2.5)).clamp(10.0, 22.0);

        // Altura do gráfico adaptativa
        final double chartHeight = isWide ? widget.height : widget.height * 0.85;

        return Container(
          padding: widget.padding ?? const EdgeInsets.fromLTRB(20, 24, 20, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Cabeçalho ─────────────────────────────────────────────────
              if (widget.title.isNotEmpty) ...[
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.indigo[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
                      style: widget.titleStyle ??
                          TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1F36),
                            letterSpacing: 0.1,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${entries.length} ${entries.length == 1 ? 'categoria' : 'categorias'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 24),
              ],

              // ── Gráfico de barras ──────────────────────────────────────────
              SizedBox(
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    maxY: _maxValue * 1.15,
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _calculateInterval(_maxValue),
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: Colors.grey[100]!,
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                        left: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    titlesData: FlTitlesData(
                      rightTitles: const AxisTitles(),
                      topTitles: const AxisTitles(),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _calculateInterval(_maxValue),
                          reservedSize: isWide ? 72 : 60,
                          getTitlesWidget: (value, _) {
                            if (value == 0) return const SizedBox.shrink();
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                _formatAxisValue(value),
                                style: TextStyle(
                                  fontSize: isWide ? 11 : 9,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isWide ? 80 : 64,
                          getTitlesWidget: (value, _) {
                            final index = value.toInt();
                            if (index < 0 || index >= entries.length) return const SizedBox.shrink();
                            final label = entries[index].key;
                            final isTouched = index == _touchedIndex;

                            return SizedBox(
                              width: adaptiveBarWidth * 2.5,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: RotatedBox(
                                  quarterTurns: 1,
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: isWide ? 11 : 10,
                                      color: isTouched ? _colorFor(index) : Colors.grey[500],
                                      fontWeight: isTouched ? FontWeight.w700 : FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        //tooltipRoundedRadius: 12,
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final entry = entries[groupIndex];
                          return BarTooltipItem(
                            '${entry.key}\n',
                            const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            children: [
                              TextSpan(
                                text: formatarValorDouble(entry.value),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      touchCallback: (event, response) {
                        setState(() {
                          if (response == null || response.spot == null || event is FlPointerExitEvent) {
                            _touchedIndex = -1;
                          } else {
                            _touchedIndex = response.spot!.touchedBarGroupIndex;
                          }
                        });
                      },
                    ),
                    alignment: BarChartAlignment.spaceEvenly,
                    barGroups: List.generate(entries.length, (index) {
                      final isTouched = index == _touchedIndex;
                      final color = _colorFor(index);
                      final value = entries[index].value;

                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            fromY: 0,
                            toY: value,
                            width: isTouched ? adaptiveBarWidth + 3 : adaptiveBarWidth,
                            color: isTouched ? color : color.withOpacity(0.75),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(6),
                              topRight: Radius.circular(6),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: _maxValue * 1.15,
                              color: Colors.grey[50],
                            ),
                          ),
                        ],
                        showingTooltipIndicators: isTouched ? [0] : [],
                      );
                    }),
                  ),
                  swapAnimationDuration: const Duration(milliseconds: 250),
                  swapAnimationCurve: Curves.easeOut,
                ),
              ),

              // ── Legenda ────────────────────────────────────────────────────
              const SizedBox(height: 20),
              _buildLegend(entries, isWide),
            ],
          ),
        );
      },
    );
  }

  // ─── Legenda em chips ────────────────────────────────────────────────────────
  Widget _buildLegend(List<MapEntry<String, double>> entries, bool isWide) {
    final total = entries.fold(0.0, (sum, e) => sum + e.value);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final color = _colorFor(index);
        final pct = total > 0 ? (entry.value / total * 100) : 0.0;
        final isTouched = index == _touchedIndex;

        return GestureDetector(
          onTap: () => setState(() => _touchedIndex = isTouched ? -1 : index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isTouched ? color.withOpacity(0.12) : Colors.grey[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isTouched ? color.withOpacity(0.4) : Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isTouched ? FontWeight.w700 : FontWeight.w500,
                    color: isTouched ? color : Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '${pct.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isTouched ? color : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  // ─── Formata eixo Y de forma compacta ────────────────────────────────────────
  String _formatAxisValue(double value) {
    if (value >= 1000000) return 'R\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return 'R\$${(value / 1000).toStringAsFixed(0)}k';
    return 'R\$${value.toStringAsFixed(0)}';
  }
}
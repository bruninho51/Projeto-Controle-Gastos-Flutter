import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

const _corFixos = Color(0xFF2F6FDE);
const _corVariaveis = Color(0xFFD0457A);

/// "Fixos × variáveis": peso de cada tipo de gasto.
class DashboardFixosVariaveis extends StatelessWidget {
  final DashboardData data;

  const DashboardFixosVariaveis({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = data.fixos + data.variaveis;
    String pct(double v) => total <= 0
        ? '0%'
        : '${(v / total * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

    Widget legenda(Color cor, String nome, double valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                      color: cor, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('$nome · ${pct(valor)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
              ]),
              const SizedBox(height: 4),
              Text(fmt.format(valor),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kWebTexto)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Fixos × variáveis',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kWebTexto)),
          const SizedBox(height: 4),
          const Text('Peso de cada tipo de gasto',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 20),
          if (total <= 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                  child:
                      Text('Sem gastos', style: TextStyle(color: Colors.grey))),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        sections: [
                          PieChartSectionData(
                              value: data.fixos,
                              color: _corFixos,
                              radius: 20,
                              showTitle: false),
                          PieChartSectionData(
                              value: data.variaveis,
                              color: _corVariaveis,
                              radius: 20,
                              showTitle: false),
                        ],
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Total',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[500])),
                          Text(fmt.format(total),
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: kWebTexto)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      legenda(_corFixos, 'Fixos', data.fixos),
                      legenda(_corVariaveis, 'Variáveis', data.variaveis),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

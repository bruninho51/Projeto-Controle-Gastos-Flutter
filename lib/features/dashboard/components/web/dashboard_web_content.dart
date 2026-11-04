import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/dashboard/components/charts/dashboard_comparativo.dart';
import 'package:orcamentos_app/features/dashboard/components/charts/dashboard_distribuicao.dart';
import 'package:orcamentos_app/features/dashboard/components/charts/dashboard_fixos_variaveis.dart';
import 'package:orcamentos_app/features/dashboard/components/charts/dashboard_situacao.dart';
import 'package:orcamentos_app/features/dashboard/components/web/dashboard_web_stats.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';

/// Corpo do dashboard na web: métricas e gráficos construídos sobre os mesmos dados.
class DashboardWebContent extends StatelessWidget {
  final DashboardData data;
  final VoidCallback onVerOrcamentos;

  const DashboardWebContent({
    super.key,
    required this.data,
    required this.onVerOrcamentos,
  });

  /// Largura mínima para colocar dois gráficos lado a lado.
  static const double _larguraDuasColunas = 900;

  @override
  Widget build(BuildContext context) {
    Widget par(Widget grande, Widget pequeno, bool lado) => lado
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: grande),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: pequeno),
            ],
          )
        : Column(children: [grande, const SizedBox(height: 16), pequeno]);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: LayoutBuilder(builder: (context, c) {
        final lado = c.maxWidth >= _larguraDuasColunas;
        return Column(
          children: [
            DashboardWebStats(data: data),
            const SizedBox(height: 20),
            par(
              DashboardDistribuicao(data: data),
              DashboardFixosVariaveis(data: data),
              lado,
            ),
            const SizedBox(height: 16),
            par(
              DashboardComparativo(data: data),
              DashboardSituacao(data: data, onVerOrcamentos: onVerOrcamentos),
              lado,
            ),
          ],
        );
      }),
    );
  }
}

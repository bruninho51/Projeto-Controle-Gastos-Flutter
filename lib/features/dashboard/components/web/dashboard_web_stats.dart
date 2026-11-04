import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/dashboard/constants/dashboard_cards.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_card_config.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Grade de métricas do dashboard (as mesmas do layout mobile).
class DashboardWebStats extends StatelessWidget {
  final DashboardData data;

  const DashboardWebStats({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = buildCardConfigs(data);

    return LayoutBuilder(builder: (context, c) {
      final colunas = c.maxWidth >= 900 ? 4 : 2;
      final linhas = <List<DashboardCardConfig>>[
        for (var i = 0; i < cards.length; i += colunas)
          cards.sublist(i, (i + colunas).clamp(0, cards.length)),
      ];

      return Column(
        children: [
          for (var l = 0; l < linhas.length; l++) ...[
            if (l > 0) const SizedBox(height: 16),
            Row(
              children: [
                for (var i = 0; i < colunas; i++) ...[
                  if (i > 0) const SizedBox(width: 16),
                  Expanded(
                    child: i < linhas[l].length
                        ? _Metrica(config: linhas[l][i])
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ],
        ],
      );
    });
  }
}

class _Metrica extends StatelessWidget {
  final DashboardCardConfig config;

  const _Metrica({required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: webCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: config.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(config.icon, color: config.color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(config.value,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: config.isCount
                              ? kWebTexto
                              : config.title == 'Valor Livre'
                                  ? const Color(0xFF047857)
                                  : kWebTexto)),
                ),
                const SizedBox(height: 2),
                Text(config.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

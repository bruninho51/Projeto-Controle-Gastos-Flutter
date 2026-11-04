import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_resumo.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/features/shared/components/web/web_stat_card.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Linha de 4 cards de métricas no topo da listagem de gastos fixos.
class GastosFixosWebStats extends StatelessWidget {
  final GastosFixosResumo resumo;

  const GastosFixosWebStats({super.key, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String itens(int n) => '$n ${n == 1 ? 'item' : 'itens'}';

    final cards = [
      WebStatCard(
        icon: Icons.receipt_long_rounded,
        cor: const Color(0xFF1A237E),
        titulo: 'Total previsto',
        valor: fmt.format(resumo.previsto),
        detalhe: itens(resumo.quantidade),
      ),
      WebStatCard(
        icon: Icons.check_circle_rounded,
        cor: const Color(0xFF43A047),
        titulo: 'Total pago',
        valor: fmt.format(resumo.pago),
        detalhe: '${(resumo.progresso * 100).round()}% do previsto',
      ),
      WebStatCard(
        icon: Icons.schedule_rounded,
        cor: const Color(0xFFF4511E),
        titulo: 'A pagar',
        valor: fmt.format(resumo.aPagar),
        detalhe: 'Pendentes e vencidos',
      ),
      WebStatCard(
        icon: Icons.warning_amber_rounded,
        cor: const Color(0xFFE53935),
        titulo: 'Vencidos',
        valor: fmt.format(resumo.vencido),
        detalhe: itens(resumo.qtdVencidos),
      ),
      WebStatCard(
        icon: TipoCategoriaGasto.patrimonio.icon,
        cor: TipoCategoriaGasto.patrimonio.color,
        titulo: 'Patrimônio previsto',
        valor: fmt.format(resumo.patrimonioPrevisto),
        detalhe: itens(resumo.qtdPatrimonio),
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

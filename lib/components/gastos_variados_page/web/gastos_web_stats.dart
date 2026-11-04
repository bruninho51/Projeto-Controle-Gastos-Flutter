import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_resumo.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/features/shared/components/web/web_stat_card.dart';

/// Linha de 4 cards de métricas no topo da listagem.
class GastosWebStats extends StatelessWidget {
  final GastosResumo resumo;
  final GastosResumo resumoMes;

  const GastosWebStats({
    super.key,
    required this.resumo,
    required this.resumoMes,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final mes = toBeginningOfSentenceCase(
        DateFormat("MMMM", 'pt_BR').format(DateTime.now()));

    String lanc(int n) => '$n ${n == 1 ? 'lançamento' : 'lançamentos'}';

    final cards = [
      WebStatCard(
        icon: Icons.calendar_month_rounded,
        cor: kWebRoxo,
        titulo: 'Total no período',
        valor: fmt.format(resumo.total),
        detalhe: lanc(resumo.quantidade),
      ),
      WebStatCard(
        icon: Icons.south_rounded,
        cor: const Color(0xFF43A047),
        titulo: 'Média por dia',
        valor: fmt.format(resumo.mediaDiaria),
        detalhe: 'Dias com gastos',
      ),
      WebStatCard(
        icon: Icons.folder_rounded,
        cor: const Color(0xFFFB8C00),
        titulo: 'Maior gasto',
        valor: fmt.format(
            resumo.maior == null ? 0 : GastosResumo.valorDe(resumo.maior!)),
        detalhe: resumo.maior?.descricao.toUpperCase() ?? '—',
      ),
      WebStatCard(
        icon: Icons.event_note_rounded,
        cor: const Color(0xFF1E88E5),
        titulo: 'Este mês',
        valor: fmt.format(resumoMes.total),
        detalhe: '$mes • ${lanc(resumoMes.quantidade)}',
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

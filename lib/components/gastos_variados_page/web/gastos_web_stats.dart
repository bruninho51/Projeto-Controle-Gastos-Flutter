import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_resumo.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

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
      _StatCard(
        icon: Icons.calendar_month_rounded,
        cor: kWebRoxo,
        titulo: 'Total no período',
        valor: fmt.format(resumo.total),
        detalhe: lanc(resumo.quantidade),
      ),
      _StatCard(
        icon: Icons.south_rounded,
        cor: const Color(0xFF43A047),
        titulo: 'Média por dia',
        valor: fmt.format(resumo.mediaDiaria),
        detalhe: 'Dias com gastos',
      ),
      _StatCard(
        icon: Icons.folder_rounded,
        cor: const Color(0xFFFB8C00),
        titulo: 'Maior gasto',
        valor: fmt.format(
            resumo.maior == null ? 0 : GastosResumo.valorDe(resumo.maior!)),
        detalhe: resumo.maior?.descricao.toUpperCase() ?? '—',
      ),
      _StatCard(
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String titulo;
  final String valor;
  final String detalhe;

  const _StatCard({
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.valor,
    required this.detalhe,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: webCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: kWebTexto)),
                ),
                const SizedBox(height: 2),
                Text(detalhe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

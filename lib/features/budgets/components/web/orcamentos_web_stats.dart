import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_resumo.dart';
import 'package:orcamentos_app/features/budgets/utils/orcamentos_aba.dart';
import 'package:orcamentos_app/features/shared/components/web/web_stat_card.dart';

/// Linha de 4 cards de métricas no topo da listagem de orçamentos.
class OrcamentosWebStats extends StatelessWidget {
  final OrcamentosResumo resumo;
  final OrcamentosAba aba;

  const OrcamentosWebStats(
      {super.key, required this.resumo, required this.aba});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final n = resumo.quantidade;
    final plural = n == 1 ? '' : 's';
    final tipo = switch (aba) {
      OrcamentosAba.ativos => 'orçamento$plural ativo$plural',
      OrcamentosAba.encerrados => 'orçamento$plural encerrado$plural',
      OrcamentosAba.todos => 'orçamento$plural',
    };

    final cards = [
      WebStatCard(
        icon: Icons.account_balance_wallet_outlined,
        cor: const Color(0xFF3949AB),
        titulo: 'Total orçado',
        valor: fmt.format(resumo.orcado),
        detalhe: '$n $tipo',
      ),
      WebStatCard(
        icon: Icons.trending_up_rounded,
        cor: const Color(0xFFF59E0B),
        titulo: 'Utilizado',
        valor: fmt.format(resumo.utilizado),
        detalhe:
            '${(resumo.percentualUtilizado * 100).toStringAsFixed(1).replaceAll('.', ',')}% do total orçado',
      ),
      WebStatCard(
        icon: Icons.check_circle_outline_rounded,
        cor: const Color(0xFF059669),
        titulo: 'Saldo disponível',
        valor: fmt.format(resumo.saldo),
        corValor: const Color(0xFF047857),
        detalhe: 'Soma dos saldos',
      ),
      WebStatCard(
        icon: Icons.credit_card_rounded,
        cor: const Color(0xFF1E88E5),
        titulo: 'Livre para gastar',
        valor: fmt.format(resumo.livre),
        detalhe: 'Após gastos fixos',
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

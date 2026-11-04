import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

const kCorUtilizado = Color(0xFF5E35B1);
const kCorComprometido = Color(0xFFC97100);
const kCorLivre = Color(0xFF0F9D6B);

/// "Para onde vai o valor total": utilizado, comprometido e livre.
class DashboardDistribuicao extends StatelessWidget {
  final DashboardData data;

  const DashboardDistribuicao({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final total = data.valorTotal;
    String pct(double v) => total <= 0
        ? '0%'
        : '${(v / total * 100).toStringAsFixed(1).replaceAll('.', ',')}%';

    final partes = [
      (
        kCorUtilizado,
        'Utilizado',
        data.utilizado,
        '${pct(data.utilizado)} do total'
      ),
      (
        kCorComprometido,
        'Comprometido',
        data.comprometido,
        '${pct(data.comprometido)} · valor atual – livre'
      ),
      (kCorLivre, 'Livre', data.valorLivre, '${pct(data.valorLivre)} do total'),
    ];
    final soma = partes.fold<double>(0, (s, p) => s + p.$3);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Para onde vai o valor total',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: kWebTexto)),
                    SizedBox(height: 4),
                    Text(
                        'Quanto já foi gasto, quanto está reservado e quanto sobra de verdade',
                        style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Text('Total ${fmt.format(total)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
          const SizedBox(height: 28),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 26,
              child: soma <= 0
                  ? ColoredBox(color: Colors.grey.shade200)
                  : Row(
                      children: [
                        for (final p in partes)
                          if (p.$3 > 0)
                            Expanded(
                              flex: (p.$3 * 100).round().clamp(1, 1 << 30),
                              child: Container(
                                  margin: const EdgeInsets.only(right: 1),
                                  color: p.$1),
                            ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 22),
          LayoutBuilder(builder: (context, c) {
            final itens = [
              for (final p in partes)
                _Parte(
                    cor: p.$1,
                    nome: p.$2,
                    valor: fmt.format(p.$3),
                    detalhe: p.$4),
            ];
            // Em telas estreitas os três blocos não cabem lado a lado.
            if (c.maxWidth < 520) {
              return Column(
                children: [
                  for (var i = 0; i < itens.length; i++) ...[
                    if (i > 0) const SizedBox(height: 14),
                    Align(alignment: Alignment.centerLeft, child: itens[i]),
                  ],
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final i in itens) Expanded(child: i)],
            );
          }),
        ],
      ),
    );
  }
}

class _Parte extends StatelessWidget {
  final Color cor;
  final String nome;
  final String valor;
  final String detalhe;

  const _Parte({
    required this.cor,
    required this.nome,
    required this.valor,
    required this.detalhe,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: cor, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          Text(nome, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ]),
        const SizedBox(height: 6),
        Text(valor,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: nome == 'Livre' ? kCorLivre : kWebTexto)),
        const SizedBox(height: 2),
        Text(detalhe, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
      ],
    );
  }
}

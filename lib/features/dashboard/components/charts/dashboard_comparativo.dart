import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/dashboard/components/charts/dashboard_distribuicao.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_orcamento.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

const _corOrcado = Color(0xFF8E8AA3);

/// "Comparativo por orçamento": orçado, utilizado e saldo de cada orçamento ativo.
class DashboardComparativo extends StatelessWidget {
  final DashboardData data;

  const DashboardComparativo({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final orcamentos = [...data.orcamentosAtivos]
      ..sort((a, b) => b.orcado.compareTo(a.orcado));
    final maximo =
        orcamentos.fold<double>(0, (m, o) => o.orcado > m ? o.orcado : m);

    Widget legenda(Color cor, String nome) => Padding(
          padding: const EdgeInsets.only(left: 0, right: 12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: cor, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(nome, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ]),
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, c) {
            const titulo = Text('Comparativo por orçamento',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kWebTexto));
            final legendas = [
              legenda(_corOrcado, 'Orçado'),
              legenda(kCorUtilizado, 'Utilizado'),
              legenda(kCorLivre, 'Saldo'),
            ];
            if (c.maxWidth < 520) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titulo,
                  const SizedBox(height: 8),
                  Wrap(runSpacing: 4, children: legendas),
                ],
              );
            }
            return Row(children: [const Expanded(child: titulo), ...legendas]);
          }),
          const SizedBox(height: 20),
          if (orcamentos.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                  child: Text('Nenhum orçamento ativo',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            for (var i = 0; i < orcamentos.length; i++) ...[
              if (i > 0) const SizedBox(height: 22),
              _Grupo(orcamento: orcamentos[i], maximo: maximo),
            ],
        ],
      ),
    );
  }
}

class _Grupo extends StatelessWidget {
  final DashboardOrcamento orcamento;
  final double maximo;

  const _Grupo({required this.orcamento, required this.maximo});

  @override
  Widget build(BuildContext context) {
    final mes = orcamento.dataCriacao == null
        ? ''
        : toBeginningOfSentenceCase(
            DateFormat('MMMM (yyyy)', 'pt_BR').format(orcamento.dataCriacao!));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(orcamento.nome.toUpperCase(),
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kWebTexto)),
            const SizedBox(width: 10),
            Text(mes, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        const SizedBox(height: 8),
        _Barra('Orçado', orcamento.orcado, maximo, _corOrcado),
        _Barra('Utilizado', orcamento.utilizado, maximo, kCorUtilizado),
        _Barra('Saldo', orcamento.saldo, maximo, kCorLivre),
      ],
    );
  }
}

class _Barra extends StatelessWidget {
  final String rotulo;
  final double valor;
  final double maximo;
  final Color cor;

  const _Barra(this.rotulo, this.valor, this.maximo, this.cor);

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final fracao = maximo <= 0 ? 0.0 : (valor / maximo).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(rotulo,
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: fracao == 0 ? 0.004 : fracao,
                child: Container(
                  height: 14,
                  decoration: BoxDecoration(
                    color: cor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(fmt.format(valor),
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: kWebTexto)),
          ),
        ],
      ),
    );
  }
}

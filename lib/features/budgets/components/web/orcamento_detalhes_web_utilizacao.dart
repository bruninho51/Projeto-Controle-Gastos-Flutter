import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

const _corUtilizado = Color(0xFF5E35B1);
const _corSaldo = Color(0xFF059669);

/// Card "Utilização": rosca de utilizado × saldo e dados do período.
class OrcamentoDetalhesWebUtilizacao extends StatelessWidget {
  final double valorInicial;
  final double valorAtual;
  final int vencidos;
  final DateTime? criadoEm;

  const OrcamentoDetalhesWebUtilizacao({
    super.key,
    required this.valorInicial,
    required this.valorAtual,
    required this.vencidos,
    required this.criadoEm,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final utilizado =
        (valorInicial - valorAtual).clamp(0, double.infinity).toDouble();
    final saldo = valorAtual.clamp(0, double.infinity).toDouble();
    final progresso =
        valorInicial <= 0 ? 0.0 : (utilizado / valorInicial).clamp(0.0, 1.0);
    final periodo = criadoEm == null
        ? '—'
        : toBeginningOfSentenceCase(
            DateFormat("MMMM 'de' yyyy", 'pt_BR').format(criadoEm!));

    Widget legenda(Color cor, String nome, double valor, {Color? corValor}) =>
        Padding(
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
                Text(nome,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ]),
              const SizedBox(height: 2),
              Text(fmt.format(valor),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: corValor ?? kWebTexto)),
            ],
          ),
        );

    Widget linha(String rotulo, String valor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Expanded(
                  child: Text(rotulo,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]))),
              Text(valor,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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
          const Text('Utilização',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kWebTexto)),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(PieChartData(
                      sectionsSpace: 0,
                      centerSpaceRadius: 46,
                      startDegreeOffset: -90,
                      sections: [
                        PieChartSectionData(
                            value: utilizado <= 0 && saldo <= 0 ? 0 : utilizado,
                            color: _corUtilizado,
                            radius: 14,
                            showTitle: false),
                        PieChartSectionData(
                            value: utilizado <= 0 && saldo <= 0 ? 1 : saldo,
                            color: _corSaldo.withOpacity(0.18),
                            radius: 14,
                            showTitle: false),
                      ],
                    )),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progresso * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kWebTexto),
                        ),
                        Text('utilizado',
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    legenda(_corUtilizado, 'Utilizado', utilizado),
                    legenda(_corSaldo.withOpacity(0.4), 'Saldo', saldo,
                        corValor: const Color(0xFF047857)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          linha('Período', periodo),
          linha(
              'Criado em',
              criadoEm == null
                  ? '—'
                  : DateFormat('dd/MM/yyyy').format(criadoEm!)),
          linha('Valor inicial', fmt.format(valorInicial)),
          linha('Vencidos', '$vencidos ${vencidos == 1 ? 'item' : 'itens'}'),
        ],
      ),
    );
  }
}

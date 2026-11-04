import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_resumo.dart';
import 'package:orcamentos_app/features/budgets/utils/orcamentos_aba.dart';
import 'package:orcamentos_app/features/shared/components/web/web_categorias_card.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

const _indigo = Color(0xFF1A237E);
const _paleta = [
  Color(0xFF1A237E),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF1E88E5),
  Color(0xFFE53935),
  Color(0xFF8E24AA),
];

/// Painel lateral: utilização por orçamento, lançamentos e filtros rápidos.
class OrcamentosWebSidebar extends StatelessWidget {
  final List<OrcamentoResponseDto> orcamentos;
  final OrcamentosResumo resumo;
  final OrcamentosAba aba;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;
  final ValueChanged<OrcamentosAba> onAba;
  final void Function(String campo, bool ascendente) onOrdenar;
  final VoidCallback onLimpar;

  const OrcamentosWebSidebar({
    super.key,
    required this.orcamentos,
    required this.resumo,
    required this.aba,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.onAba,
    required this.onOrdenar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _UtilizadoCard(orcamentos: orcamentos, resumo: resumo),
        const SizedBox(height: 16),
        _LancamentosCard(resumo: resumo),
        const SizedBox(height: 16),
        _FiltrosCard(
          aba: aba,
          campo: ordenacaoCampo,
          ascendente: ordenacaoAscendente,
          onAba: onAba,
          onOrdenar: onOrdenar,
          onLimpar: onLimpar,
        ),
      ],
    );
  }
}

class _UtilizadoCard extends StatelessWidget {
  final List<OrcamentoResponseDto> orcamentos;
  final OrcamentosResumo resumo;

  const _UtilizadoCard({required this.orcamentos, required this.resumo});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final itens = orcamentos
        .map((o) => (o, OrcamentosResumo.utilizadoDe(o)))
        .where((e) => e.$2 > 0)
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    final total = resumo.utilizado;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Utilizado por orçamento'),
          const SizedBox(height: 16),
          if (itens.isEmpty || total <= 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Sem dados',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (var i = 0; i < itens.length; i++)
                            PieChartSectionData(
                              value: itens[i].$2,
                              color: _paleta[i % _paleta.length],
                              radius: 16,
                              showTitle: false,
                            ),
                        ],
                      )),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(resumo.percentualUtilizado * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                            style: const TextStyle(
                                fontSize: 14,
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
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < itens.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                margin: const EdgeInsets.only(top: 4, right: 8),
                                decoration: BoxDecoration(
                                    color: _paleta[i % _paleta.length],
                                    borderRadius: BorderRadius.circular(2)),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(itens[i].$1.nome.toUpperCase(),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: kWebTexto)),
                                    Text(
                                      '${fmt.format(itens[i].$2)} · '
                                      '${(itens[i].$2 / total * 100).toStringAsFixed(1).replaceAll('.', ',')}%',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
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

class _LancamentosCard extends StatelessWidget {
  final OrcamentosResumo resumo;
  const _LancamentosCard({required this.resumo});

  static const _corVariados = Color(0xFFA78BDB);

  @override
  Widget build(BuildContext context) {
    final total = resumo.fixos + resumo.variados;

    Widget linha(String rotulo, int valor, Color cor) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    color: cor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(rotulo,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]))),
              Text('$valor',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kWebTexto)),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Lançamentos do mês'),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: total == 0
                  ? ColoredBox(color: Colors.grey.shade200)
                  : Row(
                      children: [
                        if (resumo.fixos > 0)
                          Expanded(
                              flex: resumo.fixos,
                              child: const ColoredBox(color: _indigo)),
                        if (resumo.variados > 0)
                          Expanded(
                              flex: resumo.variados,
                              child: const ColoredBox(color: _corVariados)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          linha('Gastos fixos', resumo.fixos, _indigo),
          linha('Gastos variados', resumo.variados, _corVariados),
        ],
      ),
    );
  }
}

class _FiltrosCard extends StatelessWidget {
  final OrcamentosAba aba;
  final String campo;
  final bool ascendente;
  final ValueChanged<OrcamentosAba> onAba;
  final void Function(String campo, bool ascendente) onOrdenar;
  final VoidCallback onLimpar;

  const _FiltrosCard({
    required this.aba,
    required this.campo,
    required this.ascendente,
    required this.onAba,
    required this.onOrdenar,
    required this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    final rotulo = TextStyle(fontSize: 12, color: Colors.grey[600]);
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: Colors.grey.shade300),
    );
    final decoracao = InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: borda,
      enabledBorder: borda,
    );
    const estilo = TextStyle(fontSize: 13, color: kWebTexto);

    final campos = <String, String>{
      'nome': 'Nome',
      'valor_atual': 'Saldo',
      'data_criacao': 'Data de criação',
      if (aba != OrcamentosAba.ativos)
        'data_encerramento': 'Data de encerramento',
    };
    final campoAtual = campos.containsKey(campo) ? campo : 'data_criacao';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WebTitulo('Filtros rápidos'),
          const SizedBox(height: 14),
          Text('Status', style: rotulo),
          const SizedBox(height: 6),
          DropdownButtonFormField<OrcamentosAba>(
            value: aba,
            isExpanded: true,
            decoration: decoracao,
            style: estilo,
            items: [
              for (final a in OrcamentosAba.values)
                DropdownMenuItem(value: a, child: Text(a.rotulo)),
            ],
            onChanged: (a) {
              if (a != null) onAba(a);
            },
          ),
          const SizedBox(height: 14),
          Text('Ordenar por', style: rotulo),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: campoAtual,
                  isExpanded: true,
                  decoration: decoracao,
                  style: estilo,
                  items: [
                    for (final e in campos.entries)
                      DropdownMenuItem(
                          value: e.key,
                          child:
                              Text(e.value, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (c) {
                    if (c != null) onOrdenar(c, ascendente);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.outlined(
                tooltip: ascendente ? 'Crescente' : 'Decrescente',
                onPressed: () => onOrdenar(campoAtual, !ascendente),
                icon: Icon(
                    ascendente
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 18),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onLimpar,
              style: OutlinedButton.styleFrom(
                foregroundColor: _indigo,
                side: const BorderSide(color: _indigo),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Limpar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

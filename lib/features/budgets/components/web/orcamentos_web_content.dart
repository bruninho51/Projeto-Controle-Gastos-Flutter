import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_resumo.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_sidebar.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_stats.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamentos_web_table.dart';
import 'package:orcamentos_app/features/budgets/utils/orcamentos_aba.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Corpo da versão web: cards + tabela à esquerda e painel lateral à direita.
class OrcamentosWebContent extends StatelessWidget {
  final List<OrcamentoResponseDto> orcamentos;
  final Map<int, ContagemGastos> contagens;
  final OrcamentosAba aba;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;
  final ValueChanged<OrcamentosAba> onAba;
  final void Function(String campo, bool ascendente) onOrdenar;
  final VoidCallback onLimpar;
  final ValueChanged<OrcamentoResponseDto> onAbrir;
  final ValueChanged<OrcamentoResponseDto> onFixos;
  final ValueChanged<OrcamentoResponseDto> onVariados;

  const OrcamentosWebContent({
    super.key,
    required this.orcamentos,
    required this.contagens,
    required this.aba,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.onAba,
    required this.onOrdenar,
    required this.onLimpar,
    required this.onAbrir,
    required this.onFixos,
    required this.onVariados,
  });

  /// Largura mínima disponível para exibir o painel lateral.
  static const double larguraMinimaSidebar = 1000;
  static const double _larguraSidebar = 320;

  static String _rotuloOrdenacao(String campo) => switch (campo) {
        'nome' => 'nome',
        'valor_atual' => 'saldo',
        'data_encerramento' => 'data de encerramento',
        _ => 'data de criação',
      };

  @override
  Widget build(BuildContext context) {
    final resumo = OrcamentosResumo.de(orcamentos, contagens);

    final principal = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 32),
      child: Column(
        children: [
          OrcamentosWebStats(resumo: resumo, aba: aba),
          const SizedBox(height: 20),
          OrcamentosWebTable(
            orcamentos: orcamentos,
            contagens: contagens,
            aba: aba,
            ordenadoPor: _rotuloOrdenacao(ordenacaoCampo),
            onAba: onAba,
            onAbrir: onAbrir,
            onFixos: onFixos,
            onVariados: onVariados,
          ),
        ],
      ),
    );

    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < larguraMinimaSidebar) return principal;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: principal),
          SizedBox(
            width: _larguraSidebar,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 12, 28, 32),
              child: OrcamentosWebSidebar(
                orcamentos: orcamentos,
                resumo: resumo,
                aba: aba,
                ordenacaoCampo: ordenacaoCampo,
                ordenacaoAscendente: ordenacaoAscendente,
                onAba: onAba,
                onOrdenar: onOrdenar,
                onLimpar: onLimpar,
              ),
            ),
          ),
        ],
      );
    });
  }
}

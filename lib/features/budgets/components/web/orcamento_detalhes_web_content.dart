import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/budgets/components/web/orcamento_detalhes_web_utilizacao.dart';

/// Corpo da tela de detalhes na web: métricas, gráfico por categoria e utilização.
class OrcamentoDetalhesWebContent extends StatelessWidget {
  /// Cards de métricas já existentes no app (os mesmos do mobile).
  final Widget cards;

  /// Gráfico de gastos por categoria já existente no app.
  final Widget grafico;
  final double valorInicial;
  final double valorAtual;
  final int vencidos;
  final DateTime? criadoEm;

  const OrcamentoDetalhesWebContent({
    super.key,
    required this.cards,
    required this.grafico,
    required this.valorInicial,
    required this.valorAtual,
    required this.vencidos,
    required this.criadoEm,
  });

  /// Largura mínima para exibir gráfico e utilização lado a lado.
  static const double _larguraDuasColunas = 900;

  @override
  Widget build(BuildContext context) {
    final utilizacao = OrcamentoDetalhesWebUtilizacao(
      valorInicial: valorInicial,
      valorAtual: valorAtual,
      vencidos: vencidos,
      criadoEm: criadoEm,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
      child: LayoutBuilder(builder: (context, c) {
        final lado = c.maxWidth >= _larguraDuasColunas;
        return Column(
          children: [
            cards,
            const SizedBox(height: 20),
            if (lado)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: grafico),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: utilizacao),
                ],
              )
            else ...[
              grafico,
              const SizedBox(height: 16),
              utilizacao,
            ],
          ],
        );
      }),
    );
  }
}

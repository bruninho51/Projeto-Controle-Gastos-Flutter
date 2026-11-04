import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/web/gasto_variado_web_lateral.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/web/gasto_variado_web_principal.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Tela de detalhe do gasto variado na web: caminho, card principal e lateral.
class GastoVariadoWebContent extends StatelessWidget {
  final List<WebCrumb> breadcrumb;
  final VoidCallback onBack;
  final String descricao;
  final dynamic valor;
  final DateTime? dataPgto;
  final String categoriaNome;
  final TipoCategoriaGasto tipo;
  final String? observacoes;
  final bool isPatrimonio;
  final bool isAtivo;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback? onDelete;
  final VoidCallback onEditNome;
  final VoidCallback onEditValor;
  final VoidCallback onEditData;
  final VoidCallback onEditCategoria;
  final VoidCallback onEditObservacoes;

  const GastoVariadoWebContent({
    super.key,
    required this.breadcrumb,
    required this.onBack,
    required this.descricao,
    required this.valor,
    required this.dataPgto,
    required this.categoriaNome,
    required this.tipo,
    required this.observacoes,
    required this.isPatrimonio,
    required this.isAtivo,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onDelete,
    required this.onEditNome,
    required this.onEditValor,
    required this.onEditData,
    required this.onEditCategoria,
    required this.onEditObservacoes,
  });

  /// Largura mínima para exibir a coluna lateral ao lado do card principal.
  static const double _larguraDuasColunas = 900;
  static const double _larguraLateral = 380;

  @override
  Widget build(BuildContext context) {
    final principal = GastoVariadoWebPrincipal(
      descricao: descricao,
      valor: valor,
      dataPgto: dataPgto,
      categoriaNome: categoriaNome,
      tipo: tipo,
      observacoes: observacoes,
      isPatrimonio: isPatrimonio,
      isAtivo: isAtivo,
      onEditNome: onEditNome,
      onEditValor: onEditValor,
      onEditData: onEditData,
      onEditCategoria: onEditCategoria,
      onEditObservacoes: onEditObservacoes,
    );
    final lateral = GastoVariadoWebLateral(
      valor: valor,
      dataPgto: dataPgto,
      isPatrimonio: isPatrimonio,
      refreshCtrl: refreshCtrl,
      onRefresh: onRefresh,
      onDelete: onDelete,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebBreadcrumb(itens: breadcrumb),
          const SizedBox(height: 14),
          Row(
            children: [
              WebBackButton(onTap: onBack),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        isPatrimonio
                            ? 'Detalhes do aporte'
                            : 'Detalhes do gasto',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: kWebTexto)),
                    const SizedBox(height: 2),
                    const Text('Consulte e edite os dados do lançamento',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(builder: (context, c) {
            if (c.maxWidth < _larguraDuasColunas) {
              return Column(children: [
                lateral,
                const SizedBox(height: 16),
                principal,
              ]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: principal),
                const SizedBox(width: 24),
                SizedBox(width: _larguraLateral, child: lateral),
              ],
            );
          }),
        ],
      ),
    );
  }
}

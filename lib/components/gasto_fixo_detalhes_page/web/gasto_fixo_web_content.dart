import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/gasto_fixo_detalhes_page/web/gasto_fixo_web_lateral.dart';
import 'package:orcamentos_app/components/gasto_fixo_detalhes_page/web/gasto_fixo_web_principal.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Tela de detalhe do gasto fixo na web: caminho, voltar, card principal e lateral.
class GastoFixoWebContent extends StatelessWidget {
  final List<WebCrumb> breadcrumb;
  final VoidCallback onBack;
  final GastoFixoResponseDto gasto;
  final bool isPago;
  final bool isVencido;
  final bool isPatrimonio;
  final bool isAtivo;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback? onRegistrar;
  final VoidCallback? onDelete;
  final VoidCallback onEditNome;
  final VoidCallback onEditPrevisto;
  final VoidCallback onEditPago;
  final VoidCallback onEditDataPgto;
  final VoidCallback onEditVencimento;
  final VoidCallback onEditCategoria;
  final VoidCallback onEditObservacoes;

  const GastoFixoWebContent({
    super.key,
    required this.breadcrumb,
    required this.onBack,
    required this.gasto,
    required this.isPago,
    required this.isVencido,
    required this.isPatrimonio,
    required this.isAtivo,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onRegistrar,
    required this.onDelete,
    required this.onEditNome,
    required this.onEditPrevisto,
    required this.onEditPago,
    required this.onEditDataPgto,
    required this.onEditVencimento,
    required this.onEditCategoria,
    required this.onEditObservacoes,
  });

  /// Largura mínima para exibir a coluna lateral ao lado do card principal.
  static const double _larguraDuasColunas = 900;
  static const double _larguraLateral = 380;

  @override
  Widget build(BuildContext context) {
    final principal = GastoFixoWebPrincipal(
      gasto: gasto,
      isPago: isPago,
      isVencido: isVencido,
      isPatrimonio: isPatrimonio,
      isAtivo: isAtivo,
      onEditNome: onEditNome,
      onEditPrevisto: onEditPrevisto,
      onEditPago: onEditPago,
      onEditDataPgto: onEditDataPgto,
      onEditVencimento: onEditVencimento,
      onEditCategoria: onEditCategoria,
      onEditObservacoes: onEditObservacoes,
    );
    final lateral = GastoFixoWebLateral(
      gasto: gasto,
      isPago: isPago,
      isPatrimonio: isPatrimonio,
      refreshCtrl: refreshCtrl,
      onRefresh: onRefresh,
      onRegistrar: onRegistrar,
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

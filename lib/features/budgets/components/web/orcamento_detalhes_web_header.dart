import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_botoes.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';
import 'package:provider/provider.dart';

/// Cabeçalho da tela de detalhes na web: breadcrumb, título, status e ações.
class OrcamentoDetalhesWebHeader extends StatelessWidget {
  final String nome;
  final bool encerrado;
  final DateTime? criadoEm;
  final AnimationController refreshCtrl;
  final GlobalKey menuKey;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onEditar;
  final VoidCallback onEncerrarOuReativar;
  final VoidCallback onMenu;

  /// Recebe `'fixo'` ou `'variado'`.
  final ValueChanged<String> onNovoGasto;

  const OrcamentoDetalhesWebHeader({
    super.key,
    required this.nome,
    required this.encerrado,
    required this.criadoEm,
    required this.refreshCtrl,
    required this.menuKey,
    required this.onBack,
    required this.onRefresh,
    required this.onEditar,
    required this.onEncerrarOuReativar,
    required this.onMenu,
    required this.onNovoGasto,
  });

  @override
  Widget build(BuildContext context) {
    final titulo = nome.isEmpty ? 'Detalhes' : nome;
    final criado = criadoEm == null
        ? ''
        : ' · criado em ${DateFormat('dd/MM/yyyy').format(criadoEm!)}';
    final corStatus =
        encerrado ? const Color(0xFF546E7A) : const Color(0xFF059669);

    return LayoutBuilder(builder: (context, c) {
      // Em larguras menores, Editar e Encerrar viram botões só de ícone.
      final compacto = c.maxWidth < _larguraBotoesComTexto;
      return _conteudo(context, titulo, criado, corStatus, compacto);
    });
  }

  /// Largura a partir da qual os botões de ação exibem o texto.
  static const double _larguraBotoesComTexto = 1000;

  Widget _conteudo(BuildContext context, String titulo, String criado,
      Color corStatus, bool compacto) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WebBreadcrumb(itens: [
            WebCrumb('Orçamentos',
                onTap: () => context
                    .read<NavigationController>()
                    .select(NavigationController.orcamentosIndex)),
            WebCrumb(titulo),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              WebBackButton(onTap: onBack),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(titulo,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: kWebTexto)),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: corStatus.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                  color: corStatus, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 6),
                            Text(encerrado ? 'Encerrado' : 'Ativo',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: corStatus)),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Detalhes do orçamento$criado',
                        style:
                            const TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
              ),
              WebIconButton(
                  tooltip: 'Recarregar',
                  onTap: onRefresh,
                  child: RotationTransition(
                    turns: refreshCtrl,
                    child: const Icon(Icons.refresh_rounded,
                        size: 18, color: kWebTexto),
                  )),
              if (!encerrado) ...[
                const SizedBox(width: 8),
                WebOutlinedButton(
                    icon: Icons.edit_outlined,
                    label: 'Editar',
                    compacto: compacto,
                    onTap: onEditar),
              ],
              const SizedBox(width: 8),
              WebOutlinedButton(
                icon: encerrado
                    ? Icons.lock_open_rounded
                    : Icons.event_available_outlined,
                label: encerrado ? 'Reativar' : 'Encerrar',
                compacto: compacto,
                onTap: onEncerrarOuReativar,
              ),
              if (!encerrado) ...[
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  tooltip: 'Novo gasto',
                  onSelected: onNovoGasto,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'fixo', child: Text('Gasto fixo')),
                    PopupMenuItem(
                        value: 'variado', child: Text('Gasto variado')),
                  ],
                  child: const WebPrimaryButton(
                      icon: Icons.add, label: 'Novo gasto'),
                ),
              ],
              const SizedBox(width: 8),
              WebIconButton(
                tooltip: 'Mais opções',
                onTap: onMenu,
                child: Icon(Icons.more_vert_rounded, key: menuKey, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_botoes.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Barra superior: título, busca, filtros, recarregar e novo gasto.
class WebPageToolbar extends StatefulWidget {
  final String busca;
  final String rotuloNovo;
  final bool mostrarFiltros;
  final String placeholderBusca;
  final String titulo;
  final String subtitulo;
  final Color cor;

  /// Ações extras exibidas antes do botão de novo gasto.
  final List<Widget> acoes;
  final bool temFiltroAtivo;
  final bool podeCriar;
  final bool isRefreshing;
  final AnimationController? refreshCtrl;
  final ValueChanged<String> onBuscar;
  final VoidCallback onFiltros;
  final VoidCallback onRefresh;
  final VoidCallback onNovoGasto;
  final VoidCallback? onBack;

  /// Caminho de navegação exibido acima do título (opcional).
  final List<WebCrumb>? breadcrumb;

  const WebPageToolbar({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.busca,
    this.cor = kWebRoxo,
    this.acoes = const [],
    required this.temFiltroAtivo,
    required this.podeCriar,
    this.isRefreshing = false,
    this.refreshCtrl,
    this.rotuloNovo = 'Novo Gasto',
    this.mostrarFiltros = true,
    this.placeholderBusca = 'Buscar lançamentos...',
    required this.onBuscar,
    required this.onFiltros,
    required this.onRefresh,
    required this.onNovoGasto,
    this.onBack,
    this.breadcrumb,
  });

  @override
  State<WebPageToolbar> createState() => _WebPageToolbarState();
}

class _WebPageToolbarState extends State<WebPageToolbar> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.busca);

  @override
  void didUpdateWidget(covariant WebPageToolbar old) {
    super.didUpdateWidget(old);
    // Mantém o campo em sincronia quando os filtros são limpos de fora.
    if (widget.busca != _ctrl.text) _ctrl.text = widget.busca;
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  /// Largura abaixo da qual os botões de texto viram só ícone.
  static const double _larguraBotoesComTexto = 1150;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) => WebCompactScope(
        compacto: c.maxWidth < _larguraBotoesComTexto,
        child: _conteudo(_larguraBusca(c.maxWidth)),
      ),
    );
  }

  /// Largura fixa do campo de busca, proporcional ao espaço disponível. Ser
  /// fixa mantém os botões encostados na direita (o título ocupa a sobra).
  static double _larguraBusca(double maxWidth) =>
      (maxWidth * 0.24).clamp(140.0, 280.0);

  Widget _conteudo(double larguraBusca) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.breadcrumb != null) ...[
            WebBreadcrumb(itens: widget.breadcrumb!),
            const SizedBox(height: 14),
          ],
          _linha(larguraBusca),
        ],
      ),
    );
  }

  Widget _linha(double larguraBusca) {
    return Row(
      children: [
        if (widget.onBack != null) ...[
          WebBackButton(onTap: widget.onBack!),
          const SizedBox(width: 14),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.titulo,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kWebTexto)),
              const SizedBox(height: 2),
              Text(widget.subtitulo,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ],
          ),
        ),
        SizedBox(
          width: larguraBusca,
          height: kWebAlturaBotao,
          child: TextField(
            controller: _ctrl,
            onChanged: widget.onBuscar,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: widget.placeholderBusca,
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
              suffixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: widget.cor, width: 1.5)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (widget.mostrarFiltros) ...[
          Badge(
            isLabelVisible: widget.temFiltroAtivo,
            smallSize: 9,
            backgroundColor: const Color(0xFFFFB300),
            child: WebOutlinedButton(
              icon: Icons.filter_list_rounded,
              label: 'Filtros',
              onTap: widget.onFiltros,
            ),
          ),
          const SizedBox(width: 8),
        ],
        WebIconButton(
          tooltip: 'Recarregar',
          onTap: widget.onRefresh,
          child: widget.refreshCtrl == null
              ? const Icon(Icons.refresh_rounded, size: 18, color: kWebTexto)
              : RotationTransition(
                  turns: widget.refreshCtrl!,
                  child: const Icon(Icons.refresh_rounded,
                      size: 18, color: kWebTexto),
                ),
        ),
        for (final a in widget.acoes) ...[
          const SizedBox(width: 8),
          a,
        ],
        if (widget.podeCriar) ...[
          const SizedBox(width: 8),
          WebPrimaryButton(
            icon: Icons.add,
            label: widget.rotuloNovo,
            cor: widget.cor,
            onTap: widget.onNovoGasto,
          ),
        ],
      ],
    );
  }
}

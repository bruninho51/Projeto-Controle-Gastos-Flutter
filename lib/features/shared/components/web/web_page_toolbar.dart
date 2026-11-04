import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Barra superior: título, busca, filtros, recarregar e novo gasto.
class WebPageToolbar extends StatefulWidget {
  final String busca;
  final String titulo;
  final String subtitulo;
  final Color cor;

  /// Ações extras exibidas antes do botão de novo gasto.
  final List<Widget> acoes;
  final bool temFiltroAtivo;
  final bool podeCriar;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final ValueChanged<String> onBuscar;
  final VoidCallback onFiltros;
  final VoidCallback onRefresh;
  final VoidCallback onNovoGasto;
  final VoidCallback? onBack;

  const WebPageToolbar({
    super.key,
    required this.titulo,
    required this.subtitulo,
    required this.busca,
    this.cor = kWebRoxo,
    this.acoes = const [],
    required this.temFiltroAtivo,
    required this.podeCriar,
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onBuscar,
    required this.onFiltros,
    required this.onRefresh,
    required this.onNovoGasto,
    this.onBack,
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Row(
        children: [
          if (widget.onBack != null) ...[
            IconButton(
              tooltip: 'Voltar',
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: kWebTexto),
            ),
            const SizedBox(width: 4),
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
            width: 280,
            child: TextField(
              controller: _ctrl,
              onChanged: widget.onBuscar,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar lançamentos...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                suffixIcon: const Icon(Icons.search_rounded, size: 20),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
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
          Badge(
            isLabelVisible: widget.temFiltroAtivo,
            smallSize: 9,
            backgroundColor: const Color(0xFFFFB300),
            child: OutlinedButton.icon(
              onPressed: widget.onFiltros,
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              label: const Text('Filtros'),
              style: _outlined(widget.cor),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Recarregar',
            child: OutlinedButton(
              onPressed: widget.onRefresh,
              style: _outlined(widget.cor),
              child: RotationTransition(
                turns: widget.refreshCtrl,
                child: const Icon(Icons.refresh_rounded, size: 18),
              ),
            ),
          ),
          for (final a in widget.acoes) ...[
            const SizedBox(width: 8),
            a,
          ],
          if (widget.podeCriar) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: widget.onNovoGasto,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Novo Gasto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.cor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static ButtonStyle _outlined(Color cor) => OutlinedButton.styleFrom(
    foregroundColor: cor,
    backgroundColor: cor.withOpacity(0.1),
    side: BorderSide.none,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );
}

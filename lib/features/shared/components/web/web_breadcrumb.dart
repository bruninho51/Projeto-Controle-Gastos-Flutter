import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Um nível do caminho de navegação; sem [onTap] é o nível atual.
class WebCrumb {
  final String label;
  final VoidCallback? onTap;

  const WebCrumb(this.label, {this.onTap});
}

/// Caminho de navegação da web: `Orçamentos › IFOOD › Gastos Fixos`.
class WebBreadcrumb extends StatelessWidget {
  final List<WebCrumb> itens;

  const WebBreadcrumb({super.key, required this.itens});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < itens.length; i++) ...[
          if (i > 0)
            Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.grey[500]),
          Flexible(child: _Nivel(itens[i], atual: i == itens.length - 1)),
        ],
      ],
    );
  }
}

class _Nivel extends StatelessWidget {
  final WebCrumb crumb;
  final bool atual;

  const _Nivel(this.crumb, {required this.atual});

  @override
  Widget build(BuildContext context) {
    final texto = Text(
      crumb.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: atual ? FontWeight.w600 : FontWeight.w400,
        color: atual ? kWebTexto : Colors.grey[600],
      ),
    );
    if (crumb.onTap == null) return texto;
    return InkWell(onTap: crumb.onTap, child: texto);
  }
}

/// Botão voltar padrão das telas web: quadrado branco com borda.
class WebBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const WebBackButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voltar',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 16, color: kWebTexto),
        ),
      ),
    );
  }
}

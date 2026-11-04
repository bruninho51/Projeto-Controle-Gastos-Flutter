import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Altura padrão dos botões das barras superiores da web.
const double kWebAlturaBotao = 44;

BoxDecoration _decoracaoBorda() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: Colors.grey.shade200),
    );

/// Indica aos [WebOutlinedButton] descendentes que o espaço é curto e eles
/// devem mostrar só o ícone.
class WebCompactScope extends InheritedWidget {
  final bool compacto;

  const WebCompactScope({
    super.key,
    required this.compacto,
    required super.child,
  });

  static bool of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<WebCompactScope>()?.compacto ??
      false;

  @override
  bool updateShouldNotify(WebCompactScope old) => old.compacto != compacto;
}

/// Botão quadrado só de ícone (recarregar, mais opções…).
class WebIconButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final IconData? icon;

  /// Substitui o [icon] (ex.: ícone animado).
  final Widget? child;

  const WebIconButton({
    super.key,
    required this.tooltip,
    required this.onTap,
    this.icon,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          width: kWebAlturaBotao,
          height: kWebAlturaBotao,
          alignment: Alignment.center,
          decoration: _decoracaoBorda(),
          child: child ?? Icon(icon, size: 18, color: kWebTexto),
        ),
      ),
    );
  }
}

/// Botão secundário com ícone e texto; com [compacto] vira só o ícone.
class WebOutlinedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Força (ou não) o modo só-ícone; por padrão segue o [WebCompactScope].
  final bool? compacto;

  const WebOutlinedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compacto,
  });

  @override
  Widget build(BuildContext context) {
    if (compacto ?? WebCompactScope.of(context)) {
      return WebIconButton(tooltip: label, onTap: onTap, icon: icon);
    }
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        height: kWebAlturaBotao,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: _decoracaoBorda(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: kWebTexto),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kWebTexto)),
          ],
        ),
      ),
    );
  }
}

/// Botão principal preenchido. Sem [onTap], só desenha o botão (para uso
/// dentro de um [PopupMenuButton], que trata o toque).
class WebPrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color cor;

  const WebPrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.cor = kIndigo,
  });

  @override
  Widget build(BuildContext context) {
    final corpo = Container(
      height: kWebAlturaBotao,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: cor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
    if (onTap == null) return corpo;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: corpo,
    );
  }
}

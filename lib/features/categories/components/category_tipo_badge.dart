import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Selo com o [TipoCategoriaGasto] de uma categoria.
///
/// [onDark] usa o estilo translúcido branco, próprio para cards coloridos.
/// [ocultarDespesa] esconde o selo de despesa, útil em listas densas onde só
/// o patrimônio precisa se destacar.
class CategoryTipoBadge extends StatelessWidget {
  final TipoCategoriaGasto tipo;
  final bool onDark;
  final bool ocultarDespesa;

  const CategoryTipoBadge({
    super.key,
    required this.tipo,
    this.onDark = false,
    this.ocultarDespesa = false,
  });

  @override
  Widget build(BuildContext context) {
    if (ocultarDespesa && tipo == TipoCategoriaGasto.despesa) {
      return const SizedBox.shrink();
    }

    final color = onDark ? Colors.white : tipo.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.15)
            : tipo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tipo.label,
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }
}

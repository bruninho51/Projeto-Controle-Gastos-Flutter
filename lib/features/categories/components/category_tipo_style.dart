import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Apresentação (ícone, cor e descrição) de cada [TipoCategoriaGasto].
extension CategoryTipoStyle on TipoCategoriaGasto {
  IconData get icon => switch (this) {
        TipoCategoriaGasto.despesa => Icons.shopping_cart_outlined,
        TipoCategoriaGasto.patrimonio => Icons.savings_outlined,
      };

  Color get color => switch (this) {
        TipoCategoriaGasto.despesa => const Color(0xFFE53935),
        TipoCategoriaGasto.patrimonio => const Color(0xFF00897B),
      };

  String get description => switch (this) {
        TipoCategoriaGasto.despesa => 'Dinheiro que saiu do seu bolso.',
        TipoCategoriaGasto.patrimonio =>
          'Dinheiro poupado, investido ou guardado.',
      };
}

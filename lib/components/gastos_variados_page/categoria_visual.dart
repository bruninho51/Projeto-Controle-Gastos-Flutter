import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Ícone e cor de uma categoria de gasto, inferidos pelo nome.
IconData iconeDaCategoria(String? nome) {
  if (nome == null) return Icons.receipt_long_rounded;
  final n = nome.toLowerCase();
  if (_any(n, ['aliment', 'comida', 'restaur', 'mercado']))
    return Icons.restaurant_outlined;
  if (_any(n, ['transport', 'carro', 'gasolina', 'uber', 'ônibus']))
    return Icons.directions_car_outlined;
  if (_any(n, ['saúde', 'saude', 'médico', 'farmácia', 'hospital']))
    return Icons.health_and_safety_outlined;
  if (_any(n, ['educação', 'escola', 'curso', 'livro']))
    return Icons.school_outlined;
  if (_any(n, ['casa', 'aluguel', 'condomínio', 'água', 'luz']))
    return Icons.home_outlined;
  if (_any(n, ['tecnologia', 'celular', 'computador', 'software']))
    return Icons.devices_outlined;
  if (_any(n, ['lazer', 'cinema', 'streaming', 'academia']))
    return Icons.sports_esports_outlined;
  if (_any(n, ['roupa', 'vestuário', 'moda']))
    return Icons.shopping_bag_outlined;
  if (_any(n, ['investimento', 'poupança', 'banco']))
    return Icons.savings_outlined;
  if (_any(n, ['viagem', 'voo', 'hotel'])) return Icons.flight_outlined;
  if (_any(n, ['pet', 'cachorro', 'gato', 'veterinário']))
    return Icons.pets_outlined;
  return Icons.receipt_long_rounded;
}

bool _any(String text, List<String> keys) => keys.any((k) => text.contains(k));

Color corDaCategoria(String? nome) {
  if (nome == null) return const Color(0xFF8E24AA);
  final n = nome.toLowerCase();
  if (_any(n, ['aliment', 'comida', 'restaur'])) return const Color(0xFFF4511E);
  if (_any(n, ['transport', 'carro', 'gasolina']))
    return const Color(0xFF1E88E5);
  if (_any(n, ['saúde', 'médico', 'farmácia'])) return const Color(0xFF43A047);
  if (_any(n, ['educação', 'escola', 'curso'])) return const Color(0xFF3949AB);
  if (_any(n, ['casa', 'aluguel'])) return const Color(0xFF00897B);
  if (_any(n, ['lazer', 'cinema'])) return const Color(0xFF039BE5);
  return const Color(0xFF8E24AA);
}

/// Cor de um gasto: patrimônio usa a cor do tipo; demais, a da categoria.
Color corDoGasto(GastoVariadoResponseDto gasto) {
  final tipo = gasto.categoriaGasto.tipo;
  return tipo == TipoCategoriaGasto.patrimonio
      ? tipo.color
      : corDaCategoria(gasto.categoriaGasto.nome);
}

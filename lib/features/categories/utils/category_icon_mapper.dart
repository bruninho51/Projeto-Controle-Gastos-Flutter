import 'package:flutter/material.dart';

class CategoryIconMapper {
  static IconData getIcon(String nome) {
    final n = nome.toLowerCase().trim();
    if (_containsAny(n, ['aliment', 'comida', 'restaur', 'lanche', 'refeição', 'mercado', 'supermercado'])) return Icons.restaurant_outlined;
    if (_containsAny(n, ['transport', 'carro', 'combustív', 'gasolina', 'uber', 'ônibus', 'metrô'])) return Icons.directions_car_outlined;
    if (_containsAny(n, ['saúde', 'saude', 'médico', 'medico', 'farmácia', 'farmacia', 'hospital'])) return Icons.health_and_safety_outlined;
    if (_containsAny(n, ['educação', 'educacao', 'escola', 'faculdade', 'curso', 'livro'])) return Icons.school_outlined;
    if (_containsAny(n, ['casa', 'aluguel', 'condomínio', 'moradia', 'água', 'luz', 'energia'])) return Icons.home_outlined;
    if (_containsAny(n, ['tecnologia', 'tech', 'celular', 'computador', 'eletrônico', 'software'])) return Icons.devices_outlined;
    if (_containsAny(n, ['lazer', 'entretenimento', 'cinema', 'streaming', 'hobby', 'academia'])) return Icons.sports_esports_outlined;
    if (_containsAny(n, ['roupa', 'vestuário', 'moda', 'calçado', 'acessório'])) return Icons.shopping_bag_outlined;
    if (_containsAny(n, ['investimento', 'poupança', 'reserva', 'financeiro', 'banco', 'cartão'])) return Icons.savings_outlined;
    if (_containsAny(n, ['viagem', 'voo', 'hotel', 'hospedagem', 'turismo'])) return Icons.flight_outlined;
    if (_containsAny(n, ['pet', 'animal', 'cachorro', 'gato', 'veterinário'])) return Icons.pets_outlined;
    if (_containsAny(n, ['presente', 'gift', 'doação', 'gorjeta'])) return Icons.card_giftcard_outlined;
    return Icons.category_outlined;
  }

  static bool _containsAny(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}

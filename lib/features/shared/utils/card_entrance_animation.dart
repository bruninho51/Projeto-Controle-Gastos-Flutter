import 'package:flutter/material.dart';

/// Animação de entrada (fade + slide) usada nos cards de orçamento, com
/// stagger baseado no índice do item na lista.
class CardEntranceAnimation {
  static AnimationController createController({
    required TickerProvider vsync,
    required int index,
  }) {
    return AnimationController(
      vsync: vsync,
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 500)),
    );
  }

  static Animation<double> fade(AnimationController controller) {
    return CurvedAnimation(parent: controller, curve: Curves.easeOut);
  }

  static Animation<Offset> slide(AnimationController controller) {
    return Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
  }
}

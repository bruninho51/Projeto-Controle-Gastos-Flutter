import 'package:flutter/material.dart';

double calculateBudgetProgress({
  required double valorInicial,
  required double valorAtual,
}) {
  if (valorInicial <= 0) return 0.0;
  return ((valorInicial - valorAtual) / valorInicial).clamp(0.0, 1.0);
}

Color getBudgetProgressColor(double value) {
  if (value < 0.5) return const Color(0xFF43A047);
  if (value < 0.8) return const Color(0xFFF4511E);
  return const Color(0xFFE53935);
}

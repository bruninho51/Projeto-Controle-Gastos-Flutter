// formatters.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatarValor(double valor) {
  final formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  return formatador.format(valor);
}

String formatarData(DateTime data) {
  return DateFormat('dd/MM/yyyy').format(data);
}

String formatarDataHora(DateTime data) {
  return DateFormat('dd/MM/yyyy HH:mm').format(data);
}

Color getProgressColor(double progress) {
  if (progress > 0.9) return Colors.red[400]!;
  if (progress > 0.7) return Colors.orange[400]!;
  return Colors.green[400]!;
}

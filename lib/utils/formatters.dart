import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatarValorDouble(double valor) {
  final formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );
  return formatador.format(valor);
}

String formatarValorDynamic(dynamic valor) {
  final numero = valor is String
      ? double.tryParse(valor.replaceAll(',', '.')) ?? 0.0
      : (valor is num ? valor.toDouble() : 0.0);

  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(numero);
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

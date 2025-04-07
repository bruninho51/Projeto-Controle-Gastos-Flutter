import 'package:intl/intl.dart';

String formatarValor(dynamic valor) {
  final numero = valor is String
      ? double.tryParse(valor.replaceAll(',', '.')) ?? 0.0
      : (valor is num ? valor.toDouble() : 0.0);

  final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(numero);
}

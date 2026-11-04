import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';

/// Situação de um gasto fixo: 'PAGO', 'VENCIDO' ou 'PENDENTE'.
String statusDoGastoFixo(GastoFixoResponseDto g) {
  if (g.valor != null) return 'PAGO';
  final venc = g.dataVenc;
  if (venc != null && venc.isBefore(DateTime.now())) return 'VENCIDO';
  return 'PENDENTE';
}

/// Cor associada a uma situação de gasto fixo.
Color corDoStatusFixo(String status) => switch (status) {
      'VENCIDO' => const Color(0xFFE53935),
      'PENDENTE' => const Color(0xFFF4511E),
      _ => const Color(0xFF43A047),
    };

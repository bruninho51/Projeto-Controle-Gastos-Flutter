import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/shared/api_models.dart';

import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_item.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-grupo de pagos por dia
// ═══════════════════════════════════════════════════════════════════════════════
class PagosDiaGroup extends StatelessWidget {
  final String diaKey;
  final List<GastoFixoResponseDto> itens;
  final double totalDia;
  final Future<void> Function(GastoFixoResponseDto) onTapItem;

  const PagosDiaGroup({required this.diaKey, required this.itens, required this.totalDia, required this.onTapItem});

  String get _diaLabel {
    if (diaKey == 'sem_data') return 'Sem data';
    try {
      final dt = DateTime.parse(diaKey);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day) return 'Hoje';
      if (dt.year == ontem.year && dt.month == ontem.month && dt.day == ontem.day) return 'Ontem';
      return DateFormat("d 'de' MMMM", 'pt_BR').format(dt);
    } catch (_) { return diaKey; }
  }

  String get _diaSemana {
    if (diaKey == 'sem_data') return '';
    try { return DateFormat('EEEE', 'pt_BR').format(DateTime.parse(diaKey)); } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_diaLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            if (_diaSemana.isNotEmpty)
              Text(_diaSemana, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmt.format(totalDia),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF43A047), letterSpacing: -0.2)),
            Text('${itens.length} ${itens.length == 1 ? 'lançamento' : 'lançamentos'}',
                style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ]),
      ),
      Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(children: itens.asMap().entries.map((e) => GastoFixoItem(
            gasto: e.value, isLast: e.key == itens.length - 1,
            onTap: () => onTapItem(e.value))).toList()),
      ),
    ]);
  }
}

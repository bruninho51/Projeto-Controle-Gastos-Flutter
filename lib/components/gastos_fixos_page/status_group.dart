import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/shared/api_models.dart';

import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_item.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Grupo de status (VENCIDO / PENDENTE)
// ═══════════════════════════════════════════════════════════════════════════════
class StatusGroup extends StatelessWidget {
  final String status;
  final List<GastoFixoResponseDto> itens;
  final Future<void> Function(GastoFixoResponseDto) onTapItem;

  /// Quando [TipoCategoriaGasto.patrimonio], a seção usa o visual de patrimônio.
  final TipoCategoriaGasto? tipo;

  /// Substitui o título padrão ("Vencidos" / "Pendentes").
  final String? titulo;

  const StatusGroup({
    required this.status,
    required this.itens,
    required this.onTapItem,
    this.tipo,
    this.titulo,
  });

  bool get _isPatrimonio => tipo == TipoCategoriaGasto.patrimonio;

  Color get _color => _isPatrimonio
      ? tipo!.color
      : status == 'VENCIDO'
          ? const Color(0xFFE53935)
          : const Color(0xFFF4511E);
  IconData get _icon => _isPatrimonio
      ? tipo!.icon
      : status == 'VENCIDO'
          ? Icons.warning_amber_rounded
          : Icons.schedule_rounded;
  String get _label =>
      titulo ?? (status == 'VENCIDO' ? 'Vencidos' : 'Pendentes');
  double get _totalPrevisto => itens.fold(
      0, (s, g) => s + (double.tryParse(g.previsto) ?? 0));

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Row(children: [
            Container(width: 28, height: 28,
                decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(_icon, color: _color, size: 15)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _color)),
              Text('${itens.length} ${itens.length == 1 ? 'item' : 'itens'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(fmt.format(_totalPrevisto),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _color, letterSpacing: -0.2)),
              Text('previsto', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
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
      ],
    );
  }
}

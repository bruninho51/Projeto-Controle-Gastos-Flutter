import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';
import 'package:orcamentos_app/shared/api_models.dart';

import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_status.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Item individual
// ═══════════════════════════════════════════════════════════════════════════════
class GastoFixoItem extends StatelessWidget {
  final GastoFixoResponseDto gasto;
  final bool isLast;
  final VoidCallback onTap;

  const GastoFixoItem({required this.gasto, required this.isLast, required this.onTap});

  /// Itens de patrimônio se destacam pela cor do ícone; o status segue nas demais cores.
  Color get _iconColor => gasto.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio
      ? gasto.categoriaGasto.tipo.color
      : _color;

  /// O PENDENTE de patrimônio acompanha a cor da seção "Patrimônio pendente";
  /// VENCIDO mantém o vermelho de alerta.
  Color _statusChipColor(String status) =>
      status == 'PENDENTE' && gasto.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio
          ? gasto.categoriaGasto.tipo.color
          : _color;

  Color get _color {
    switch (statusDoGastoFixo(gasto)) {
      case 'VENCIDO': return const Color(0xFFE53935);
      case 'PENDENTE': return const Color(0xFFF4511E);
      default: return const Color(0xFF43A047);
    }
  }

  IconData get _icon {
    switch (statusDoGastoFixo(gasto)) {
      case 'VENCIDO': return Icons.warning_amber_rounded;
      case 'PENDENTE': return Icons.schedule_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  String _fmtDate(DateTime? data) {
    if (data == null) return '';
    return DateFormat('dd/MM/yyyy').format(data);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final previsto = double.tryParse(gasto.previsto) ?? 0.0;
    final valorPago = gasto.valor != null ? double.tryParse(gasto.valor!) ?? 0.0 : null;
    final descricao = gasto.descricao;
    final categoriaNome = gasto.categoriaGasto.nome;
    final status = statusDoGastoFixo(gasto);

    String subtitulo = '';
    if (status == 'PAGO') subtitulo = 'Pago em ${_fmtDate(gasto.dataPgto)}';
    else if (gasto.dataVenc != null) {
      subtitulo = status == 'VENCIDO'
          ? 'Venceu em ${_fmtDate(gasto.dataVenc)}'
          : 'Vence em ${_fmtDate(gasto.dataVenc)}';
    }
    subtitulo = subtitulo.isNotEmpty ? '$categoriaNome · $subtitulo' : categoriaNome;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero,
        splashColor: _color.withOpacity(0.06), highlightColor: _color.withOpacity(0.03),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Container(width: 40, height: 40,
                  decoration: BoxDecoration(color: _iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(_icon, color: _iconColor, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(descricao, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitulo.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitulo, style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ])),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  status == 'PAGO' && valorPago != null ? fmt.format(valorPago) : fmt.format(previsto),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: status == 'PAGO' ? const Color(0xFF43A047) : const Color(0xFF1A1F36),
                      letterSpacing: -0.2),
                ),
                if (status == 'PAGO' && valorPago != null && valorPago != previsto) ...[
                  const SizedBox(height: 2),
                  Text('prev. ${fmt.format(previsto)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                ],
                if (status != 'PAGO') ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: _statusChipColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                    child: Text(status, style: TextStyle(fontSize: 9, color: _statusChipColor(status), fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                  ),
                ],
              ]),
            ]),
          ),
          if (!isLast) Padding(padding: const EdgeInsets.only(left: 70), child: Container(height: 1, color: Colors.grey[100])),
        ]),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// Cabeçalho da seção PAGO
// ═══════════════════════════════════════════════════════════════════════════════
class PagosHeader extends StatelessWidget {
  final int totalItens;
  final double totalValor;
  const PagosHeader({required this.totalItens, required this.totalValor});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    const color = Color(0xFF43A047);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
      child: Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_rounded, color: color, size: 15)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Pagos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
          Text('$totalItens ${totalItens == 1 ? 'item' : 'itens'}',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(fmt.format(totalValor),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.2)),
          Text('total pago', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
        ]),
      ]),
    );
  }
}

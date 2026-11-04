import 'package:flutter/material.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════════
class FixosEmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  final bool showClearButton;
  final VoidCallback? onClear;

  const FixosEmptyState({required this.message, required this.subtitle, this.showClearButton = false, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.06), shape: BoxShape.circle),
          child: Icon(showClearButton ? Icons.filter_alt_off_rounded : Icons.receipt_long_rounded,
              size: 48, color: const Color(0xFF3949AB).withOpacity(0.5))),
      const SizedBox(height: 20),
      Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
      const SizedBox(height: 6),
      Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[450])),
      if (showClearButton && onClear != null) ...[
        const SizedBox(height: 20),
        TextButton.icon(onPressed: onClear, icon: const Icon(Icons.clear_all_rounded, size: 16),
            label: const Text('Limpar filtros'),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF3949AB))),
      ],
      const SizedBox(height: 100),
    ]));
  }
}

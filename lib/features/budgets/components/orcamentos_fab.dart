import 'package:flutter/material.dart';

class OrcamentosFAB extends StatelessWidget {
  final bool isMenuOpen;
  final Duration animationDuration;
  final VoidCallback onToggle;
  final VoidCallback onAddCategoria;
  final VoidCallback onAddOrcamento;

  const OrcamentosFAB({
    super.key,
    required this.isMenuOpen,
    required this.animationDuration,
    required this.onToggle,
    required this.onAddCategoria,
    required this.onAddOrcamento,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedSlide(
          offset: isMenuOpen ? Offset.zero : const Offset(0, 0.4),
          duration: animationDuration,
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: isMenuOpen ? 1.0 : 0.0,
            duration: animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                heroTag: 'btnCategorias',
                onPressed: isMenuOpen ? onAddCategoria : null,
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.category_outlined, size: 18),
                label: const Text(
                  'Categorias',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
        AnimatedSlide(
          offset: isMenuOpen ? Offset.zero : const Offset(0, 0.4),
          duration: Duration(milliseconds: animationDuration.inMilliseconds - 40),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: isMenuOpen ? 1.0 : 0.0,
            duration: animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: FloatingActionButton.extended(
                heroTag: 'btnOrcamento',
                onPressed: isMenuOpen ? onAddOrcamento : null,
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                elevation: 3,
                icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                label: const Text(
                  'Orçamento',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
        FloatingActionButton(
          heroTag: 'btnOrcamentosPage',
          onPressed: onToggle,
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          elevation: 4,
          child: AnimatedRotation(
            turns: isMenuOpen ? 0.125 : 0,
            duration: animationDuration,
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ],
    );
  }
}
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
        if (isMenuOpen)
          AnimatedOpacity(
            opacity: 1.0,
            duration: animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: 'btnCategorias',
                onPressed: onAddCategoria,
                backgroundColor: Colors.orange[600],
                icon: const Icon(Icons.category, color: Colors.white),
                label: const Text('Categorias', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        if (isMenuOpen)
          AnimatedOpacity(
            opacity: 1.0,
            duration: animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: 'btnOrcamento',
                onPressed: onAddOrcamento,
                backgroundColor: Colors.indigo[600],
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text('Orçamento', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'btnOrcamentosPage',
          onPressed: onToggle,
          backgroundColor: Colors.indigo[700],
          child: Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}

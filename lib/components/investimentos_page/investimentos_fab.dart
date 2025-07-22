import 'package:flutter/material.dart';

class InvestimentosFAB extends StatelessWidget {
  final bool isMenuOpen;
  final Duration animationDuration;
  final VoidCallback onToggle;
  final VoidCallback onAddCategoria;
  final VoidCallback onAddInvestimento;

  const InvestimentosFAB({
    super.key,
    required this.isMenuOpen,
    required this.animationDuration,
    required this.onToggle,
    required this.onAddCategoria,
    required this.onAddInvestimento,
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
                label: const Text('    Categorias', style: TextStyle(color: Colors.white)),
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
                heroTag: 'btnInvestimento',
                onPressed: onAddInvestimento,
                backgroundColor: Colors.indigo[600],
                icon: const Icon(Icons.savings, color: Colors.white),
                label: const Text('Investimento', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'btnMain',
          onPressed: onToggle,
          backgroundColor: Colors.indigo[700],
          child: Icon(isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class GastosPageEmptyState extends StatelessWidget {
  final bool comFiltros;
  final VoidCallback? onLimparFiltros;

  const GastosPageEmptyState({
    super.key,
    this.comFiltros = false,
    this.onLimparFiltros,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              comFiltros ? Icons.filter_alt_off : Icons.shopping_cart,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              comFiltros
                  ? 'Nenhum gasto encontrado com os filtros aplicados'
                  : 'Nenhum gasto encontrado',
              style: const TextStyle(
                fontSize: 18, 
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (comFiltros && onLimparFiltros != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onLimparFiltros,
                child: const Text('Limpar filtros'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class OrcamentosPageEmptyState extends StatelessWidget {
  final VoidCallback onAddOrcamento;

  const OrcamentosPageEmptyState({
    super.key,
    required this.onAddOrcamento,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallet, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Nenhum orçamento ativo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Adicione um novo orçamento para começar a planejar seus gastos.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Novo orçamento'),
              onPressed: onAddOrcamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

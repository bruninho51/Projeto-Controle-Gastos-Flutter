import 'package:flutter/material.dart';

class InvestimentosPageEmptyState extends StatelessWidget {
  final VoidCallback onAddInvestimento;

  const InvestimentosPageEmptyState({
    super.key,
    required this.onAddInvestimento,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.savings, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Nenhum investimento ativo',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Adicione um investimento e dê o primeiro passo rumo à liberdade.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white,),
              label: const Text('Novo Investimento'),
              onPressed: onAddInvestimento,
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

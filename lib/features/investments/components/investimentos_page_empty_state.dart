import 'package:flutter/material.dart';

class InvestimentosPageEmptyState extends StatelessWidget {
  final VoidCallback onAddInvestimento;

  const InvestimentosPageEmptyState({super.key, required this.onAddInvestimento});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.savings_rounded,
              size: 52,
              color: Colors.indigo[300],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhum investimento ativo',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Adicione um investimento e dê o primeiro passo rumo à liberdade',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey[450]),
          ),
          const SizedBox(height: 28),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              'Novo Investimento',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            onPressed: onAddInvestimento,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo[700],
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

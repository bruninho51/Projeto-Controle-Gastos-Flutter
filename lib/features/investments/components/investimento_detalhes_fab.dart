import 'package:flutter/material.dart';

class InvestimentoDetalhesFAB extends StatelessWidget {
  final VoidCallback onAddItemLinhaDoTempo;

  const InvestimentoDetalhesFAB({
    super.key,
    required this.onAddItemLinhaDoTempo,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'btnAddLinhaTempo',
      onPressed: onAddItemLinhaDoTempo,
      backgroundColor: Colors.indigo[700],
      child: const Icon(Icons.add, color: Colors.white),
    );
  }
}
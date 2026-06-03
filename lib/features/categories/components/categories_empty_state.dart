import 'package:flutter/material.dart';

class CategoriesEmptyState extends StatelessWidget {
  const CategoriesEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
            child: Icon(Icons.category_outlined, size: 52, color: Colors.indigo[300]),
          ),
          const SizedBox(height: 20),
          Text(
            'Nenhuma categoria cadastrada',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Nova Categoria" para começar',
            style: TextStyle(fontSize: 13, color: Colors.grey[450]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

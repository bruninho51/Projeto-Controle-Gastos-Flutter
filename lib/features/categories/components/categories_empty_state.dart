import 'package:flutter/material.dart';

class CategoriesEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const CategoriesEmptyState({
    super.key,
    this.icon = Icons.category_outlined,
    this.title = 'Nenhuma categoria cadastrada',
    this.subtitle = 'Toque em "Nova" para começar',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle),
            child: Icon(icon, size: 52, color: Colors.indigo[300]),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey[450]),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

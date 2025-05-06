import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrcamentoTitulo extends StatelessWidget {
  final String nome;
  final bool isEncerrado;
  final String? dataEncerramento;
  final VoidCallback? onEditPressed;
  final Color? activeColor;
  final Color? inactiveColor;

  const OrcamentoTitulo({
    super.key,
    required this.nome,
    required this.isEncerrado,
    this.dataEncerramento,
    this.onEditPressed,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeBgColor = activeColor?.withAlpha(25) ?? Colors.green[50];
    final activeTextColor = activeColor ?? Colors.green[800];
    final inactiveBgColor = inactiveColor?.withAlpha(25) ?? Colors.grey[200];
    final inactiveTextColor = inactiveColor ?? Colors.grey[800];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isEncerrado ? inactiveBgColor : activeBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEncerrado ? 'ENCERRADO' : 'ATIVO',
                        style: TextStyle(
                          color: isEncerrado ? inactiveTextColor : activeTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    if (isEncerrado && dataEncerramento != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Encerrado em ${_formatDate(dataEncerramento!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isEncerrado && onEditPressed != null)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.indigo),
              onPressed: onEditPressed,
            ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      DateTime dateTime = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'data inválida';
    }
  }
}
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
    final activeBgColor = activeColor?.withAlpha(30) ?? Colors.green[50];
    final activeTextColor = activeColor ?? Colors.green[800];
    final inactiveBgColor = inactiveColor?.withAlpha(30) ?? Colors.grey[200];
    final inactiveTextColor = inactiveColor ?? Colors.grey[800];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
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
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[900],
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isEncerrado ? inactiveBgColor : activeBgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isEncerrado 
                              ? inactiveTextColor!.withAlpha(50) 
                              : activeTextColor!.withAlpha(50),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isEncerrado ? 'ENCERRADO' : 'ATIVO',
                        style: TextStyle(
                          color: isEncerrado ? inactiveTextColor : activeTextColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (isEncerrado && dataEncerramento != null) ...[
                      const SizedBox(width: 10),
                      Text(
                        'Encerrado em ${_formatDate(dataEncerramento!)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          letterSpacing: 0.2,
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
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_outlined,
                  size: 22,
                  color: Colors.indigo[700],
                ),
              ),
              onPressed: onEditPressed,
              splashRadius: 20,
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
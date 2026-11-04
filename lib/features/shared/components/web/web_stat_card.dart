import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Card de métrica da versão web: ícone colorido, título, valor e detalhe.
class WebStatCard extends StatelessWidget {
  final IconData icon;
  final Color cor;
  final String titulo;
  final String valor;
  final String detalhe;

  /// Cor do valor; por padrão o texto principal.
  final Color? corValor;

  const WebStatCard({
    super.key,
    required this.icon,
    required this.cor,
    required this.titulo,
    required this.valor,
    required this.detalhe,
    this.corValor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: webCardDecoration(),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: cor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(valor,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: corValor ?? kWebTexto)),
                ),
                const SizedBox(height: 2),
                Text(detalhe,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

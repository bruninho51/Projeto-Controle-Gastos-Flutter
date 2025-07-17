import 'package:flutter/material.dart';
import '../../utils/formatters.dart';

class GastoVariadoItemCard extends StatelessWidget {
  final Map<String, dynamic> gasto;
  final VoidCallback onTap;

  const GastoVariadoItemCard({
    super.key,
    required this.gasto,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dataPagamento = DateTime.parse(gasto['data_pgto']);
    final double valor = double.parse(gasto['valor']);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Card(
          elevation: 2.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                _buildIcon(),
                const SizedBox(width: 16),
                _buildInfoColumn(dataPagamento, valor),
                _buildStatusColumn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.shopping_bag,
        color: Colors.purple,
        size: 28,
      ),
    );
  }

  Widget _buildInfoColumn(DateTime dataPagamento, double valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            gasto['descricao'],
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            formatarValorDouble(valor),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pago em ${formatarData(dataPagamento)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'PAGO',
            style: TextStyle(
              color: Colors.purple[800],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Icon(
          Icons.check_circle,
          color: Colors.purple[800],
          size: 20,
        ),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import '../orcamento_detalhes_page/orcamento_detalhes_page.dart';

class OrcamentoCard extends StatelessWidget {
  final Map<String, dynamic> orcamento;
  final String apiToken;
  final VoidCallback onRefresh;

  const OrcamentoCard({
    super.key,
    required this.orcamento,
    required this.apiToken,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final valorAtual = double.tryParse(orcamento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorLivre = double.tryParse(orcamento['valor_livre']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(orcamento['valor_inicial']?.toString() ?? '0') ?? 0;
    final progresso = valorInicial > 0 ? ((valorInicial - valorAtual) / valorInicial).clamp(0.0, 1.0) : 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrcamentoDetalhesPage(
                orcamentoId: orcamento['id'],
              ),
            ),
          );
          onRefresh();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: Colors.indigo[700], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orcamento['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Criado em ${formatarData(DateTime.parse(orcamento['data_criacao']))}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValorDouble(valorAtual),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getProgressColor(progresso.toDouble()),
                        ),
                      ),
                      Text(
                        'de ${formatarValorDouble(valorInicial)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progresso.toDouble(),
                backgroundColor: Colors.grey[200],
                color: getProgressColor(progresso.toDouble()),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progresso * 100).toStringAsFixed(1)}% utilizado',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${formatarValorDouble(valorLivre)} livre',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

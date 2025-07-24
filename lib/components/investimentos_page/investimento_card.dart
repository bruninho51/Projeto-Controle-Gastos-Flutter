import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/investimento_detalhes_page/investimento_detalhes_page.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import '../orcamento_detalhes_page/orcamento_detalhes_page.dart';

class InvestimentoCard extends StatelessWidget {
  final Map<String, dynamic> investimento;
  final String apiToken;
  final VoidCallback onRefresh;

  const InvestimentoCard({
    super.key,
    required this.investimento,
    required this.apiToken,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final valorAtual = double.tryParse(investimento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(investimento['valor_inicial']?.toString() ?? '0') ?? 0;
    final lucro = valorAtual - valorInicial;
    final progresso = valorInicial != 0 ? (valorAtual - valorInicial) / valorInicial : 0;

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
              builder: (context) => InvestimentoDetalhesPage(
                investimentoId: investimento['id'],
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
                    child: Icon(Icons.savings, color: Colors.indigo[700], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investimento['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Criado em ${formatarData(DateTime.parse(investimento['data_criacao']))}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValorDouble(valorAtual),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: getArrowSavingColor(progresso.toDouble()),
                        ),
                      ),
                      Text(
                        formatarValorDouble(valorInicial),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
           
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            progresso >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                            color: progresso >= 0 ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(progresso * 100).toStringAsFixed(4)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: progresso >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${formatarValorDouble(lucro)} lucro',
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

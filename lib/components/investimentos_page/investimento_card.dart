import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/investimento_detalhes_page/investimento_detalhes_page.dart';
import 'package:orcamentos_app/utils/formatters.dart';

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
      elevation: kIsWeb ? 4 : 2,
      margin: EdgeInsets.only(bottom: kIsWeb ? 20 : 16),
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
        onHover: kIsWeb ? (hovering) {} : null,
        child: Padding(
          padding: EdgeInsets.all(kIsWeb ? 20 : 16),
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
                    child: Icon(
                      Icons.savings, 
                      color: Colors.indigo[700], 
                      size: kIsWeb ? 32 : 28,
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          investimento['nome'] ?? 'Sem nome',
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: kIsWeb ? 6 : 4),
                        Text(
                          'Criado em ${formatarData(DateTime.parse(investimento['data_criacao']))}',
                          style: TextStyle(
                            fontSize: kIsWeb ? 13 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 16 : 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValorDouble(valorAtual),
                        style: TextStyle(
                          fontSize: kIsWeb ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: getArrowSavingColor(progresso.toDouble()),
                        ),
                      ),
                      Text(
                        formatarValorDouble(valorInicial),
                        style: TextStyle(
                          fontSize: kIsWeb ? 13 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: kIsWeb ? 16 : 12),
              SizedBox(height: kIsWeb ? 12 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        progresso >= 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: progresso >= 0 ? Colors.green : Colors.red,
                        size: kIsWeb ? 18 : 16,
                      ),
                      SizedBox(width: kIsWeb ? 6 : 4),
                      Text(
                        '${(progresso * 100).toStringAsFixed(kIsWeb ? 2 : 4)}%',
                        style: TextStyle(
                          fontSize: kIsWeb ? 14 : 12,
                          color: progresso >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${formatarValorDouble(lucro)} lucro',
                    style: TextStyle(
                      fontSize: kIsWeb ? 14 : 12,
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

  Color getArrowSavingColor(double value) {
    if (value > 0) return Colors.green;
    if (value < 0) return Colors.red;
    return Colors.grey;
  }
}
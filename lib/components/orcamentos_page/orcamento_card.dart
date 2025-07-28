import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
      elevation: kIsWeb ? 4 : 2,
      margin: EdgeInsets.only(bottom: kIsWeb ? 20 : 16),
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
                      Icons.account_balance_wallet,
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
                          orcamento['nome'] ?? 'Sem nome',
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: kIsWeb ? 6 : 4),
                        Text(
                          'Criado em ${formatarData(DateTime.parse(orcamento['data_criacao']))}',
                          style: TextStyle(
                            fontSize: kIsWeb ? 13 : 12,
                            color: Colors.grey[600],
                          ),
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
                          fontSize: kIsWeb ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: getProgressColor(progresso.toDouble()),
                        ),
                      ),
                      Text(
                        'de ${formatarValorDouble(valorInicial)}',
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
              LinearProgressIndicator(
                value: progresso.toDouble(),
                backgroundColor: Colors.grey[200],
                color: getProgressColor(progresso.toDouble()),
                minHeight: kIsWeb ? 8 : 6,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: kIsWeb ? 12 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progresso * 100).toStringAsFixed(1)}% utilizado',
                    style: TextStyle(
                      fontSize: kIsWeb ? 13 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${formatarValorDouble(valorLivre)} livre',
                    style: TextStyle(
                      fontSize: kIsWeb ? 16 : 12,
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

  Color getProgressColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }
}
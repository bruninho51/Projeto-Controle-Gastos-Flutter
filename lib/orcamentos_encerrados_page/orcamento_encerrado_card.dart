import 'package:flutter/material.dart';
import 'package:orcamentos_app/refatorado/confirmation_dialog.dart';
import 'package:orcamentos_app/gastos_variados_page/formatters.dart';

class OrcamentoEncerradoCard extends StatelessWidget {
  final int id;
  final String nome;
  final String dataEncerramento;
  final double valorAtual;
  final double valorInicial;
  final Future<void> Function() onTap;
  final Future<void> Function() onReativar;

  const OrcamentoEncerradoCard({
    super.key,
    required this.id,
    required this.nome,
    required this.dataEncerramento,
    required this.valorAtual,
    required this.valorInicial,
    required this.onTap,
    required this.onReativar,
  });

  Color _getSaldoColor() {
    final saldo = valorInicial - valorAtual;
    if (saldo < 0) return Colors.red[700]!;
    if (saldo < valorInicial * 0.3) return Colors.orange[700]!;
    return Colors.green[700]!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
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
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.archive, color: Colors.grey[600], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Encerrado em $dataEncerramento',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValor(valorAtual),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'de ${formatarValor(valorInicial)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo final',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    formatarValor(valorInicial - valorAtual),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSaldoColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => ConfirmationDialog.confirmAction(
                  context: context,
                  title: 'Reativar Orçamento',
                  message: 'Deseja realmente reativar este orçamento?',
                  actionText: 'Reativar',
                  action: onReativar,
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[50],
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'Reativar Orçamento',
                  style: TextStyle(color: Colors.indigo[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
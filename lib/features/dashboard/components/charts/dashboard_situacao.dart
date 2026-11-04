import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

const _corAtivos = Color(0xFF2F6FDE);
const _corEncerrados = Color(0xFF8E8AA3);

/// "Situação dos orçamentos": ativos × encerrados, com atalho para a listagem.
class DashboardSituacao extends StatelessWidget {
  final DashboardData data;
  final VoidCallback onVerOrcamentos;

  const DashboardSituacao({
    super.key,
    required this.data,
    required this.onVerOrcamentos,
  });

  @override
  Widget build(BuildContext context) {
    final total = data.qtdOrcamentos;

    Widget item(Color cor, String nome, int valor) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: cor, borderRadius: BorderRadius.circular(3)),
                ),
                const SizedBox(width: 8),
                Text(nome,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ]),
              const SizedBox(height: 6),
              Text('$valor',
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: kWebTexto)),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: webCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Situação dos orçamentos',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: kWebTexto)),
          const SizedBox(height: 4),
          Text('$total ${total == 1 ? 'orçamento' : 'orçamentos'} no total',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 18,
              child: total == 0
                  ? ColoredBox(color: Colors.grey.shade200)
                  : Row(
                      children: [
                        if (data.qtdOrcamentosAtivos > 0)
                          Expanded(
                              flex: data.qtdOrcamentosAtivos,
                              child: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  color: _corAtivos)),
                        if (data.qtdOrcamentosEncerrados > 0)
                          Expanded(
                              flex: data.qtdOrcamentosEncerrados,
                              child: const ColoredBox(color: _corEncerrados)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              item(_corAtivos, 'Ativos', data.qtdOrcamentosAtivos),
              item(_corEncerrados, 'Encerrados', data.qtdOrcamentosEncerrados),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onVerOrcamentos,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Ver orçamentos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: BorderSide(color: Colors.grey.shade300),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

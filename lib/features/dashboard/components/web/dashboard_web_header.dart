import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/web/web_estilo.dart';

/// Cabeçalho do dashboard na web: título, seletor de módulo e mês atual.
class DashboardWebHeader extends StatelessWidget {
  final TabController tabController;

  const DashboardWebHeader({super.key, required this.tabController});

  static const _abas = [
    ('Orçamentos', Icons.account_balance_wallet_outlined),
    ('Investimentos', Icons.trending_up_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final mes = toBeginningOfSentenceCase(
        DateFormat("MMMM 'de' yyyy", 'pt_BR').format(DateTime.now()));

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: kIndigo.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard_outlined, color: kIndigo),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kWebTexto)),
                SizedBox(height: 2),
                Text('Visão geral dos seus orçamentos',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          ListenableBuilder(
            listenable: tabController,
            builder: (context, _) => Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE9E8F2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < _abas.length; i++)
                    InkWell(
                      borderRadius: BorderRadius.circular(9),
                      onTap: () => tabController.animateTo(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: tabController.index == i
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          children: [
                            Icon(_abas[i].$2,
                                size: 16,
                                color: tabController.index == i
                                    ? kIndigo
                                    : Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(_abas[i].$1,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: tabController.index == i
                                        ? kIndigo
                                        : Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(mes,
                style: const TextStyle(fontSize: 13, color: kWebTexto)),
          ),
        ],
      ),
    );
  }
}

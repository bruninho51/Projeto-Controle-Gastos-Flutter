import 'package:flutter/material.dart';

import 'package:orcamentos_app/features/dashboard/components/dashboard_card.dart';
import 'package:orcamentos_app/features/dashboard/constants/dashboard_cards.dart';
import 'package:orcamentos_app/features/dashboard/models/dashboard_data.dart';

class DashboardCardGrid extends StatelessWidget {
  final DashboardData data;

  const DashboardCardGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final cards = buildCardConfigs(data);
    return LayoutBuilder(
      builder: (context, constraints) {
        final int cols = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : 2;
        final double ratio = constraints.maxWidth > 800 ? 1.55 : 0.95;
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 16),
                  child: Text(
                    '${cards.length} métricas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[500],
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: ratio,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (_, i) =>
                      DashboardCard(config: cards[i], index: i),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:orcamentos_app/features/notifications/components/notification_day_group.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';
import 'package:orcamentos_app/features/notifications/utils/notifications_grouping.dart';

class NotificationsList extends StatelessWidget {
  final List<NotificacaoBancariaModel> notificacoes;
  final void Function(NotificacaoBancariaModel) onTap;

  const NotificationsList({
    super.key,
    required this.notificacoes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final grupos = groupByDay(notificacoes);
    final dias = grupos.keys.toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dia = dias[index];
                final itens = grupos[dia]!;
                return NotificationDayGroup(
                  diaKey: dia,
                  itens: itens,
                  onTap: onTap,
                );
              },
              childCount: dias.length,
            ),
          ),
        ),
      ],
    );
  }
}

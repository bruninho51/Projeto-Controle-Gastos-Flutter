import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/notifications/components/notification_list_item.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';

class NotificationDayGroup extends StatelessWidget {
  final String diaKey;
  final List<NotificacaoBancariaModel> itens;
  final void Function(NotificacaoBancariaModel) onTap;

  const NotificationDayGroup({
    super.key,
    required this.diaKey,
    required this.itens,
    required this.onTap,
  });

  String get _diaLabel {
    try {
      final dt = DateTime.parse(diaKey);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == hoje.year &&
          dt.month == hoje.month &&
          dt.day == hoje.day) {
        return 'Hoje';
      }
      if (dt.year == ontem.year &&
          dt.month == ontem.month &&
          dt.day == ontem.day) {
        return 'Ontem';
      }
      return DateFormat("d 'de' MMMM", 'pt_BR').format(dt);
    } catch (_) {
      return diaKey;
    }
  }

  String get _diaSemana {
    try {
      final dt = DateTime.parse(diaKey);
      return DateFormat('EEEE', 'pt_BR').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final totalDia = itens.fold<double>(0, (sum, n) => sum + n.valor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _diaLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    if (_diaSemana.isNotEmpty)
                      Text(
                        _diaSemana,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(totalDia),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00796B),
                    ),
                  ),
                  Text(
                    '${itens.length} ${itens.length == 1 ? 'notificação' : 'notificações'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: itens.asMap().entries.map((e) {
              final i = e.key;
              final notif = e.value;
              final isLast = i == itens.length - 1;
              return NotificationListItem(
                notificacao: notif,
                isLast: isLast,
                onTap: () => onTap(notif),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

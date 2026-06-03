import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';

class NotificationListItem extends StatelessWidget {
  final NotificacaoBancariaModel notificacao;
  final bool isLast;
  final VoidCallback onTap;

  const NotificationListItem({
    super.key,
    required this.notificacao,
    required this.isLast,
    required this.onTap,
  });

  IconData _iconForBanco(String banco) {
    switch (banco) {
      case 'com.nu.production':
        return Icons.credit_card_rounded;
      case 'one.inter':
      case 'com.itau':
      case 'com.bradesco':
        return Icons.account_balance_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _colorForBanco(String banco) {
    switch (banco) {
      case 'com.nu.production':
        return const Color(0xFF8B00FF);
      case 'one.inter':
        return const Color(0xFFFF6B00);
      case 'com.itau':
        return const Color(0xFF003366);
      case 'com.bradesco':
        return const Color(0xFFCC0000);
      default:
        return const Color(0xFF00796B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final color = _colorForBanco(notificacao.banco);
    final descricao = notificacao.descricaoNormalizada?.isNotEmpty == true
        ? notificacao.descricaoNormalizada!
        : notificacao.descricaoOriginal;
    final hora = DateFormat('HH:mm')
        .format(notificacao.dataNotificacaoDateTime.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
        splashColor: color.withValues(alpha: 0.06),
        highlightColor: color.withValues(alpha: 0.03),
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForBanco(notificacao.banco),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          descricao,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              notificacao.nomeBanco,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              ' · $hora',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.grey[400]),
                            ),
                            if (notificacao.vinculado) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Vinculado',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '- ${fmt.format(notificacao.valor)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLast)
              Padding(
                padding: const EdgeInsets.only(left: 70),
                child: Container(height: 1, color: Colors.grey[100]),
              ),
          ],
        ),
      ),
    );
  }
}

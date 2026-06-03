import 'package:flutter/material.dart';

class NotificationsEmptyState extends StatelessWidget {
  final bool comFiltro;
  final VoidCallback? onLimpar;

  const NotificationsEmptyState({
    super.key,
    this.comFiltro = false,
    this.onLimpar,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF00796B).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                comFiltro
                    ? Icons.filter_list_off_rounded
                    : Icons.notifications_off_outlined,
                size: 34,
                color: const Color(0xFF00796B),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              comFiltro
                  ? 'Nenhuma notificação pendente'
                  : 'Nenhuma notificação capturada',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              comFiltro
                  ? 'Todas as notificações já foram vinculadas a um gasto.'
                  : 'As notificações bancárias aparecerão aqui quando forem capturadas.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            if (comFiltro && onLimpar != null) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: onLimpar,
                child: const Text('Ver todas'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class NotificationsErrorState extends StatelessWidget {
  final String error;

  const NotificationsErrorState({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          'Erro ao carregar: $error',
          style: TextStyle(color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class NotificationsWebUnsupportedState extends StatelessWidget {
  const NotificationsWebUnsupportedState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smartphone_rounded, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Disponível apenas no app Android',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'As notificações bancárias são capturadas pelo app nativo.',
              style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/notifications/components/notifications_list.dart';
import 'package:orcamentos_app/features/notifications/components/notifications_states.dart';
import 'package:orcamentos_app/features/notifications/models/notification_model.dart';
import 'package:orcamentos_app/features/notifications/notifications_channel.dart';
import 'package:orcamentos_app/features/notifications/pages/notification_edit_page.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late Future<List<NotificacaoBancariaModel>> _future;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;
  bool _apenasNaoVinculadas = false;

  static const _blue = Color(0xFF3949AB);
  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _future = _fetch();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<List<NotificacaoBancariaModel>> _fetch() async {
    if (kIsWeb) return [];
    return NotificationsChannel.getAll();
  }

  Future<void> _abrirEdicao(NotificacaoBancariaModel n) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificationEditPage(
          notificacao: n,
          apiToken: auth.apiToken ?? '',
        ),
      ),
    );
    if (mounted) setState(() => _future = _fetch());
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _future = _fetch();
    });
    _refreshCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  Widget _buildFilterPill() {
    return GestureDetector(
      onTap: () =>
          setState(() => _apenasNaoVinculadas = !_apenasNaoVinculadas),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _apenasNaoVinculadas
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _apenasNaoVinculadas
                ? Colors.white.withValues(alpha: 0.6)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: _apenasNaoVinculadas
                    ? const Color(0xFFFFD740)
                    : const Color(0xFF69F0AE),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              _apenasNaoVinculadas ? 'Pendentes' : 'Todas',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          SharedAppBar(
            title: 'Notificações',
            subtitle: 'Capturas bancárias',
            mainIcon: Icons.notifications_rounded,
            gradientColors: _gradientColors,
            showAvatar: true,
            bottomContent: _buildFilterPill(),
            actionButtons: [
              SharedAppBar.headerButton(
                onTap: _handleRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: _refreshCtrl,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white
                        .withValues(alpha: _isRefreshing ? 1.0 : 0.9),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: kIsWeb
                ? const NotificationsWebUnsupportedState()
                : FutureBuilder<List<NotificacaoBancariaModel>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                              ConnectionState.waiting &&
                          snapshot.data == null) {
                        return Center(
                          child: OrcamentosLoading(
                              message: 'Carregando notificações...'),
                        );
                      }
                      if (snapshot.hasError) {
                        return NotificationsErrorState(
                            error: snapshot.error.toString());
                      }
                      final lista = snapshot.data ?? [];
                      final filtrada = _apenasNaoVinculadas
                          ? lista.where((n) => !n.vinculado).toList()
                          : lista;
                      if (filtrada.isEmpty) {
                        return NotificationsEmptyState(
                          comFiltro: _apenasNaoVinculadas,
                          onLimpar: () =>
                              setState(() => _apenasNaoVinculadas = false),
                        );
                      }
                      return RefreshIndicator(
                        color: _blue,
                        onRefresh: () async {
                          setState(() => _future = _fetch());
                          await _future;
                        },
                        child: NotificationsList(
                          notificacoes: filtrada,
                          onTap: _abrirEdicao,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

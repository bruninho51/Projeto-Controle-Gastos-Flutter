import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/notificacoes/notificacoes_channel.dart';
import 'package:orcamentos_app/components/notificacoes_page/notificacao_edicao_page.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class NotificacoesPage extends StatefulWidget {
  const NotificacoesPage({super.key});

  @override
  State<NotificacoesPage> createState() => _NotificacoesPageState();
}

class _NotificacoesPageState extends State<NotificacoesPage>
    with SingleTickerProviderStateMixin {
  late Future<List<NotificacaoBancariaModel>> _future;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;
  bool _apenasNaoVinculadas = false;

  static const _teal = Color(0xFF00796B);

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
    return NotificacoesChannel.getAll();
  }

  Future<void> _abrirEdicao(NotificacaoBancariaModel n) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NotificacaoEdicaoPage(
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

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          _NotificacoesHeader(
            auth: auth,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            apenasNaoVinculadas: _apenasNaoVinculadas,
            onToggleFiltro: () =>
                setState(() => _apenasNaoVinculadas = !_apenasNaoVinculadas),
          ),
          Expanded(
            child: kIsWeb
                ? _WebUnsupported()
                : FutureBuilder<List<NotificacaoBancariaModel>>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          snapshot.data == null) {
                        return Center(
                          child: OrcamentosLoading(
                              message: 'Carregando notificações...'),
                        );
                      }
                      if (snapshot.hasError) {
                        return _ErrorState(error: snapshot.error.toString());
                      }
                      final lista = snapshot.data ?? [];
                      final filtrada = _apenasNaoVinculadas
                          ? lista.where((n) => !n.vinculado).toList()
                          : lista;
                      if (filtrada.isEmpty) {
                        return _EmptyState(
                            comFiltro: _apenasNaoVinculadas,
                            onLimpar: () => setState(
                                () => _apenasNaoVinculadas = false));
                      }
                      return RefreshIndicator(
                        color: _teal,
                        onRefresh: () async {
                          setState(() => _future = _fetch());
                          await _future;
                        },
                        child: _ListaNotificacoes(
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

// ═══════════════════════════════════════════════════════════════════════════════
// Lista principal
// ═══════════════════════════════════════════════════════════════════════════════
class _ListaNotificacoes extends StatelessWidget {
  final List<NotificacaoBancariaModel> notificacoes;
  final void Function(NotificacaoBancariaModel) onTap;

  const _ListaNotificacoes({
    required this.notificacoes,
    required this.onTap,
  });

  Map<String, List<NotificacaoBancariaModel>> _agruparPorDia(
      List<NotificacaoBancariaModel> lista) {
    final Map<String, List<NotificacaoBancariaModel>> grupos = {};
    for (final n in lista) {
      final key =
          DateFormat('yyyy-MM-dd').format(n.dataNotificacaoDateTime.toLocal());
      grupos.putIfAbsent(key, () => []).add(n);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    final grupos = _agruparPorDia(notificacoes);
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
                return _DiaGroup(
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

// ═══════════════════════════════════════════════════════════════════════════════
// Grupo de um dia
// ═══════════════════════════════════════════════════════════════════════════════
class _DiaGroup extends StatelessWidget {
  final String diaKey;
  final List<NotificacaoBancariaModel> itens;
  final void Function(NotificacaoBancariaModel) onTap;

  const _DiaGroup({
    required this.diaKey,
    required this.itens,
    required this.onTap,
  });

  String get _diaLabel {
    try {
      final dt = DateTime.parse(diaKey);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day) {
        return 'Hoje';
      }
      if (dt.year == ontem.year && dt.month == ontem.month && dt.day == ontem.day) {
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
                            fontWeight: FontWeight.w400),
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
                color: Colors.black.withOpacity(0.04),
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
              return _NotificacaoItem(
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

// ═══════════════════════════════════════════════════════════════════════════════
// Item individual
// ═══════════════════════════════════════════════════════════════════════════════
class _NotificacaoItem extends StatelessWidget {
  final NotificacaoBancariaModel notificacao;
  final bool isLast;
  final VoidCallback onTap;

  const _NotificacaoItem({
    required this.notificacao,
    required this.isLast,
    required this.onTap,
  });

  IconData _iconForBanco(String banco) {
    switch (banco) {
      case 'com.nu.production':
        return Icons.credit_card_rounded;
      case 'one.inter':
        return Icons.account_balance_rounded;
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
    final hora = DateFormat('HH:mm').format(notificacao.dataNotificacaoDateTime.toLocal());

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : BorderRadius.zero,
        splashColor: color.withOpacity(0.06),
        highlightColor: color.withOpacity(0.03),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
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
                                  fontWeight: FontWeight.w400),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════════
class _NotificacoesHeader extends StatelessWidget {
  final AuthState auth;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final bool apenasNaoVinculadas;
  final VoidCallback onToggleFiltro;

  const _NotificacoesHeader({
    required this.auth,
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.apenasNaoVinculadas,
    required this.onToggleFiltro,
  });

  Widget _buildAvatar() {
    if (auth.user?.photoURL != null) {
      return ClipOval(
        child: Image.network(
          auth.user!.photoURL!,
          width: 38,
          height: 38,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004D40), Color(0xFF00695C), Color(0xFF00897B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF004D40).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.notifications_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notificações',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Capturas bancárias',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildAvatar(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: onToggleFiltro,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: apenasNaoVinculadas
                        ? Colors.white.withOpacity(0.25)
                        : Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: apenasNaoVinculadas
                          ? Colors.white.withOpacity(0.6)
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
                          color: apenasNaoVinculadas
                              ? const Color(0xFFFFD740)
                              : const Color(0xFF69F0AE),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        apenasNaoVinculadas ? 'Pendentes' : 'Todas',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              _HeaderButton(
                onTap: onRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(isRefreshing ? 1.0 : 0.9),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Estados auxiliares
// ═══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool comFiltro;
  final VoidCallback? onLimpar;

  const _EmptyState({this.comFiltro = false, this.onLimpar});

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
                color: const Color(0xFF00796B).withOpacity(0.08),
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

class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

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

class _WebUnsupported extends StatelessWidget {
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
                  color: Color(0xFF1A1F36)),
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

// ─── Botão glassmorphism ──────────────────────────────────────────────────────
class _HeaderButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final String tooltip;
  final bool isSquare;

  const _HeaderButton({
    required this.child,
    required this.onTap,
    required this.tooltip,
    this.isSquare = false,
  });

  @override
  State<_HeaderButton> createState() => _HeaderButtonState();
}

class _HeaderButtonState extends State<_HeaderButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(
              horizontal: widget.isSquare ? 10 : 14, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

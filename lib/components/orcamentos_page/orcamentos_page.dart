import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/categorias_gastos_page/categorias_gastos_page.dart';
import 'package:orcamentos_app/components/form_orcamento_page/form_orcamento_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamento_card.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page_empty_state.dart';
import 'package:orcamentos_app/components/orcamentos_encerrados_page/orcamentos_encerrados_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_fab.dart';

class OrcamentosPage extends StatefulWidget {
  const OrcamentosPage({super.key});

  @override
  State<OrcamentosPage> createState() => OrcamentosPageState();
}

class OrcamentosPageState extends State<OrcamentosPage> {
  List<OrcamentoResponseDto> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false;
  final _animationDuration = const Duration(milliseconds: 300);

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchApiData(_auth.apiToken);
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _fetchApiData(String apiToken) async {
    _safeSetState(() => _isLoading = true);
    try {
      final api = ApiService(tokenProvider: () => apiToken);
      final orcamentos = await api.getOrcamentos(encerrado: false);
      _safeSetState(() {
        _orcamentos = orcamentos;
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        OrcamentosSnackBar.error(context: context, message: 'Erro: ${e.toString()}');
      }
    }
  }

  void _addNewOrcamento(String apiToken) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FormularioOrcamentoPage(apiToken: apiToken)),
    );
    if (result == true) _fetchApiData(apiToken);
  }

  void _addNewCategoria(String apiToken) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => CategoriasDeGastoPage()));
  }

  void _navigateToArquivados(String apiToken) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => OrcamentosEncerradosPage()));
    _fetchApiData(apiToken);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header moderno ────────────────────────────────────────────────
          _OrcamentosHeader(
            auth: auth,
            isLoading: _isLoading,
            orcamentosCount: _orcamentos.length,
            onRefresh: () => _fetchApiData(_auth.apiToken),
            onArquivados: () => _navigateToArquivados(_auth.apiToken),
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Colors.indigo[700],
                strokeWidth: 2.5,
              ),
            )
                : _orcamentos.isEmpty
                ? OrcamentosPageEmptyState(
              onAddOrcamento: () => _addNewOrcamento(_auth.apiToken),
            )
                : RefreshIndicator(
              color: Colors.indigo[700],
              onRefresh: () => _fetchApiData(_auth.apiToken),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      kIsWeb ? 24 : 16,
                      8,
                      kIsWeb ? 24 : 16,
                      100,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) => OrcamentoCard(
                          orcamento: _orcamentos[index],
                          apiToken: _auth.apiToken,
                          onRefresh: () => _fetchApiData(_auth.apiToken),
                        ),
                        childCount: _orcamentos.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: OrcamentosFAB(
        isMenuOpen: _isMenuOpen,
        animationDuration: _animationDuration,
        onToggle: () => setState(() => _isMenuOpen = !_isMenuOpen),
        onAddCategoria: () {
          setState(() => _isMenuOpen = false);
          _addNewCategoria(_auth.apiToken);
        },
        onAddOrcamento: () {
          setState(() => _isMenuOpen = false);
          _addNewOrcamento(_auth.apiToken);
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Header moderno
// ═══════════════════════════════════════════════════════════════════════════════
class _OrcamentosHeader extends StatefulWidget {
  final AuthProvider auth;
  final bool isLoading;
  final int orcamentosCount;
  final VoidCallback onRefresh;
  final VoidCallback onArquivados;

  const _OrcamentosHeader({
    required this.auth,
    required this.isLoading,
    required this.orcamentosCount,
    required this.onRefresh,
    required this.onArquivados,
  });

  @override
  State<_OrcamentosHeader> createState() => _OrcamentosHeaderState();
}

class _OrcamentosHeaderState extends State<_OrcamentosHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCtrl.repeat();
    widget.onRefresh();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: ícone + título + avatar ─────────────────────────────
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
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Orçamentos',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      'Controle seus gastos ativos',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildAvatar(),
            ],
          ),

          const SizedBox(height: 16),

          // ── Linha 2: badge de contagem + botões de ação ───────────────────
          Row(
            children: [
              // Badge animado com contagem
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(anim),
                    child: child,
                  ),
                ),
                child: Container(
                  key: ValueKey(widget.orcamentosCount),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bolinha verde pulsando
                      _PulseDot(),
                      const SizedBox(width: 7),
                      Text(
                        widget.orcamentosCount == 0
                            ? 'Nenhum ativo'
                            : '${widget.orcamentosCount} ${widget.orcamentosCount == 1 ? 'ativo' : 'ativos'}',
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

              // Botão Encerrados (com label)
              _HeaderButton(
                onTap: widget.onArquivados,
                tooltip: 'Ver orçamentos encerrados',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.archive_outlined, color: Colors.white, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Encerrados',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Botão Refresh com ícone girando
              _HeaderButton(
                onTap: _handleRefresh,
                tooltip: 'Recarregar lista',
                isSquare: true,
                child: RotationTransition(
                  turns: _refreshCtrl,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Colors.white.withOpacity(_isRefreshing ? 1 : 0.9),
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

  Widget _buildAvatar() {
    if (widget.auth.user?.photoURL != null) {
      return ClipOval(
        child: Image.network(
          widget.auth.user!.photoURL!,
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
}

// ─── Botão glassmorphism do header ────────────────────────────────────────────
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
            horizontal: widget.isSquare ? 10 : 14,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: _pressed
                ? Colors.white.withOpacity(0.28)
                : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ─── Bolinha verde pulsando ───────────────────────────────────────────────────
class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: Color.lerp(
            const Color(0xFF69F0AE),
            const Color(0xFF00E676),
            _anim.value,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69F0AE).withOpacity(0.5 * _anim.value),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
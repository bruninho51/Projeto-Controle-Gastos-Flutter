import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';

import 'package:orcamentos_app/components/categorias_gastos_page/categorias_gastos_page.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/pulse_dot.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/components/common/status_badge.dart';
import 'package:orcamentos_app/components/form_orcamento_page/form_orcamento_page.dart';
import 'package:orcamentos_app/components/orcamentos_encerrados_page/orcamentos_encerrados_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamento_card.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_fab.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page_empty_state.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class OrcamentosPage extends StatefulWidget {
  const OrcamentosPage({super.key});

  @override
  State<OrcamentosPage> createState() => OrcamentosPageState();
}

class OrcamentosPageState extends State<OrcamentosPage> {
  // ── Estado ────────────────────────────────────────────────────────────────

  List<OrcamentoResponseDto> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false;

  static const _animationDuration = Duration(milliseconds: 300);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  AuthState get _auth => Provider.of<AuthState>(context, listen: false);
  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  String get _token => _auth.apiToken!;

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchOrcamentos();
    });
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  Future<void> _fetchOrcamentos() async {
    _safeSetState(() => _isLoading = true);

    try {
      final api = _api;

      final orcamentos = await api.getOrcamentos(encerrado: false);

      _safeSetState(() {
        _orcamentos = orcamentos;
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);

      if (mounted) {
        OrcamentosSnackBar.error(
          context: context,
          message: 'Erro: $e',
        );
      }
    }
  }

  Future<void> _navigateToNovoOrcamento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioOrcamentoPage(apiToken: _token),
      ),
    );

    if (result == true) _fetchOrcamentos();
  }

  Future<void> _navigateToCategorias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CategoriasDeGastoPage()),
    );
  }

  Future<void> _navigateToEncerrados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrcamentosEncerradosPage()),
    );

    _fetchOrcamentos();
  }

  void _toggleMenu() => setState(() => _isMenuOpen = !_isMenuOpen);

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildFAB(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final count = _orcamentos.length;

    final label = count == 0
        ? 'Nenhum ativo'
        : '$count ${count == 1 ? 'ativo' : 'ativos'}';

    return SharedAppBar(
      title: 'Orçamentos',
      subtitle: 'Controle seus gastos ativos',
      mainIcon: Icons.account_balance_wallet_rounded,
      gradientColors: _gradientColors,
      actionButtons: [
        SharedAppBar.headerButton(
          onTap: _navigateToEncerrados,
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
        SharedAppBar.headerButton(
          onTap: _fetchOrcamentos,
          tooltip: 'Recarregar lista',
          isSquare: true,
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.white.withOpacity(_isLoading ? 1 : 0.9),
            size: 18,
          ),
        ),
      ],
      bottomContent: StatusBadge(
        leading: const PulseDot.positive(),
        text: label,
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.indigo[700],
          strokeWidth: 2.5,
        ),
      );
    }

    if (_orcamentos.isEmpty) {
      return OrcamentosPageEmptyState(
        onAddOrcamento: _navigateToNovoOrcamento,
      );
    }

    return RefreshIndicator(
      color: Colors.indigo[700],
      onRefresh: _fetchOrcamentos,
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
                  apiToken: _token, // 👈 aqui também ajustado
                  onRefresh: _fetchOrcamentos,
                ),
                childCount: _orcamentos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return OrcamentosFAB(
      isMenuOpen: _isMenuOpen,
      animationDuration: _animationDuration,
      onToggle: _toggleMenu,
      onAddCategoria: () {
        _toggleMenu();
        _navigateToCategorias();
      },
      onAddOrcamento: () {
        _toggleMenu();
        _navigateToNovoOrcamento();
      },
    );
  }
}
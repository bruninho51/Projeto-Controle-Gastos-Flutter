import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/categories/pages/investment_categories_page.dart';
import 'package:orcamentos_app/features/investments/components/investimento_card.dart';
import 'package:orcamentos_app/features/investments/components/investimentos_fab.dart';
import 'package:orcamentos_app/features/investments/components/investimentos_page_empty_state.dart';
import 'package:orcamentos_app/features/investments/pages/form_investimento_page.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/pulse_dot.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/status_badge.dart';
import 'package:orcamentos_app/utils/http.dart';

class InvestimentosPage extends StatefulWidget {
  const InvestimentosPage({super.key});

  @override
  State<InvestimentosPage> createState() => InvestimentosPageState();
}

class InvestimentosPageState extends State<InvestimentosPage> {
  // ── Estado ────────────────────────────────────────────────────────────────

  List<dynamic> _investimentos = [];
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
  String get _token => _auth.apiToken!;

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchApiData(_token);
    });
  }

  // ── Ações ─────────────────────────────────────────────────────────────────

  Future<void> _fetchApiData(String apiToken) async {
    _safeSetState(() => _isLoading = true);

    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'investimentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
      );

      if (response.statusCode == 200) {
        final investimentos = (json.decode(response.body) as List)
            .where((investimento) => investimento['data_inatividade'] == null)
            .toList();

        _safeSetState(() {
          _investimentos = investimentos;
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar investimentos: ${response.statusCode}');
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);

      if (mounted) {
        OrcamentosSnackBar.error(context: context, message: 'Erro: $e');
      }
    }
  }

  Future<void> _navigateToNovoInvestimento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FormularioInvestimentoPage(apiToken: _token),
      ),
    );

    if (result == true) _fetchApiData(_token);
  }

  Future<void> _navigateToCategorias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => InvestmentCategoriesPage(apiToken: _token)),
    );
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
    final count = _investimentos.length;

    final label = count == 0
        ? 'Nenhum ativo'
        : '$count ${count == 1 ? 'ativo' : 'ativos'}';

    return SharedAppBar(
      title: 'Investimentos',
      subtitle: 'Acompanhe seus investimentos',
      mainIcon: Icons.savings_rounded,
      gradientColors: _gradientColors,
      actionButtons: [
        SharedAppBar.headerButton(
          onTap: () => _fetchApiData(_token),
          tooltip: 'Recarregar lista',
          isSquare: true,
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.white.withValues(alpha: _isLoading ? 1 : 0.9),
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
        child: OrcamentosLoading(message: 'Carregando investimentos...'),
      );
    }

    if (_investimentos.isEmpty) {
      return InvestimentosPageEmptyState(
        onAddInvestimento: _navigateToNovoInvestimento,
      );
    }

    return RefreshIndicator(
      color: Colors.indigo[700],
      onRefresh: () => _fetchApiData(_token),
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
                (context, index) => InvestimentoCard(
                  investimento: _investimentos[index],
                  apiToken: _token,
                  onRefresh: () => _fetchApiData(_token),
                  index: index,
                ),
                childCount: _investimentos.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── FAB ───────────────────────────────────────────────────────────────────

  Widget _buildFAB() {
    return InvestimentosFAB(
      isMenuOpen: _isMenuOpen,
      animationDuration: _animationDuration,
      onToggle: _toggleMenu,
      onAddCategoria: () {
        _toggleMenu();
        _navigateToCategorias();
      },
      onAddInvestimento: () {
        _toggleMenu();
        _navigateToNovoInvestimento();
      },
    );
  }
}

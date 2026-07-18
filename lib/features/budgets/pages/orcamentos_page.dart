import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/categories/pages/expense_categories_page.dart';
import 'package:orcamentos_app/features/shared/components/info_state_widget.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/pulse_dot.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/status_badge.dart';
import 'package:orcamentos_app/features/budgets/pages/form_orcamento_page.dart';
import 'package:orcamentos_app/features/budgets/components/orcamento_card.dart';
import 'package:orcamentos_app/features/budgets/components/orcamentos_fab.dart';
import 'package:orcamentos_app/features/budgets/components/orcamentos_filtros_sheet.dart';
import 'package:orcamentos_app/features/budgets/components/orcamentos_page_empty_state.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';

class OrcamentosPage extends StatefulWidget {
  /// Quando `true`, lista apenas os orçamentos encerrados (arquivados). Quando
  /// `false` (padrão), lista os ativos — comportamento da aba principal.
  final bool encerrados;

  const OrcamentosPage({super.key, this.encerrados = false});

  @override
  State<OrcamentosPage> createState() => OrcamentosPageState();
}

class OrcamentosPageState extends State<OrcamentosPage> {
  // ── Estado ────────────────────────────────────────────────────────────────

  List<OrcamentoResponseDto> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false;

  final _menuButtonKey = GlobalKey();

  // ── Filtros ─────────────────────────────────────────────────────────────
  String _filtroNome = '';
  late String _ordenacaoCampo;
  bool _ordenacaoAscendente = false; // padrão: decrescente

  static const _animationDuration = Duration(milliseconds: 300);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  // ── Helpers ───────────────────────────────────────────────────────────────

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  bool get _isEncerrados => widget.encerrados;

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ── Ciclo de vida ─────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Padrão de ordenação por modo: encerrados pela data de encerramento,
    // ativos pela data de criação (ambos decrescentes — mais recentes no topo).
    _ordenacaoCampo = _isEncerrados ? 'data_encerramento' : 'data_criacao';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchOrcamentos();
    });
  }

  bool get _temFiltroAtivo => _filtroNome.isNotEmpty;

  // ── Ações ─────────────────────────────────────────────────────────────────

  Future<void> _fetchOrcamentos() async {
    _safeSetState(() => _isLoading = true);

    try {
      final orcamentos = await _api.getOrcamentos(
        encerrado: _isEncerrados,
        nome: _filtroNome.isEmpty ? null : _filtroNome,
      );

      _ordenar(orcamentos);

      _safeSetState(() {
        _orcamentos = orcamentos;
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);

      if (mounted) {
        OrcamentosSnackBar.error(context: context, message: 'Erro: $e');
      }
    }
  }

  /// Ordena a lista no cliente conforme [_ordenacaoCampo]/[_ordenacaoAscendente]
  /// (a API de orçamentos não expõe parâmetro de ordenação).
  void _ordenar(List<OrcamentoResponseDto> orcamentos) {
    int cmp(OrcamentoResponseDto a, OrcamentoResponseDto b) {
      switch (_ordenacaoCampo) {
        case 'nome':
          return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
        case 'valor_atual':
          final va = double.tryParse(a.valorAtual) ?? 0;
          final vb = double.tryParse(b.valorAtual) ?? 0;
          return va.compareTo(vb);
        case 'data_encerramento':
          return _compareNullableDate(a.dataEncerramento, b.dataEncerramento);
        case 'data_criacao':
        default:
          return a.dataCriacao.compareTo(b.dataCriacao);
      }
    }

    orcamentos.sort((a, b) => _ordenacaoAscendente ? cmp(a, b) : -cmp(a, b));
  }

  /// Datas nulas vão sempre para o fim, independente da direção.
  int _compareNullableDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return _ordenacaoAscendente ? 1 : -1;
    if (b == null) return _ordenacaoAscendente ? -1 : 1;
    return a.compareTo(b);
  }

  void _abrirFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrcamentosFiltrosSheet(
        filtroNome: _filtroNome,
        ordenacaoCampo: _ordenacaoCampo,
        ordenacaoAscendente: _ordenacaoAscendente,
        incluirEncerramento: _isEncerrados,
        onAplicar: (nome, campo, ascendente) {
          setState(() {
            _filtroNome = nome;
            _ordenacaoCampo = campo;
            _ordenacaoAscendente = ascendente;
          });
          _fetchOrcamentos();
        },
        onLimpar: _limparFiltros,
      ),
    );
  }

  void _limparFiltros() {
    setState(() {
      _filtroNome = '';
      _ordenacaoCampo = _isEncerrados ? 'data_encerramento' : 'data_criacao';
      _ordenacaoAscendente = false;
    });
    _fetchOrcamentos();
  }

  Future<void> _navigateToNovoOrcamento() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const FormularioOrcamentoPage(),
      ),
    );

    if (result == true) _fetchOrcamentos();
  }

  Future<void> _navigateToCategorias() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseCategoriesPage()),
    );
  }

  Future<void> _navigateToEncerrados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrcamentosPage(encerrados: true)),
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
      floatingActionButton: _isEncerrados ? null : _buildFAB(),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return _isEncerrados ? _buildEncerradosHeader() : _buildAtivosHeader();
  }

  Widget _buildAtivosHeader() {
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
        _filtrosButton(),
        _refreshButton(),
        _menuButton(),
      ],
      bottomContent: StatusBadge(
        leading: const PulseDot.positive(),
        text: label,
      ),
    );
  }

  Widget _buildEncerradosHeader() {
    final count = _orcamentos.length;
    final label = count == 0
        ? 'Nenhum encerrado'
        : '$count ${count == 1 ? 'encerrado' : 'encerrados'}';

    return SharedAppBar(
      title: 'Orçamentos Encerrados',
      subtitle: 'Consulte ou reative os arquivados',
      mainIcon: Icons.archive_rounded,
      gradientColors: _gradientColors,
      showBackButton: true,
      onBack: () => Navigator.pop(context),
      showAvatar: false,
      actionButtons: [
        _filtrosButton(),
        _refreshButton(),
      ],
      bottomContent: StatusBadge(
        leading: const Icon(Icons.archive_rounded, color: Colors.white, size: 12),
        text: label,
      ),
    );
  }

  // Retorno inferido (_HeaderButton é privado ao SharedAppBar).
  // ignore: strict_top_level_inference
  _refreshButton() => SharedAppBar.headerButton(
        onTap: _fetchOrcamentos,
        tooltip: 'Recarregar lista',
        isSquare: true,
        child: Icon(
          Icons.refresh_rounded,
          color: Colors.white.withValues(alpha: _isLoading ? 1 : 0.9),
          size: 18,
        ),
      );

  // ignore: strict_top_level_inference
  _filtrosButton() => SharedAppBar.headerButton(
        onTap: _abrirFiltros,
        tooltip: 'Filtros',
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.filter_list_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Filtros',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_temFiltroAtivo)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFD740),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      );

  // ignore: strict_top_level_inference
  _menuButton() => SharedAppBar.headerButton(
        onTap: () => _showOptionsMenu(context),
        tooltip: 'Mais opções',
        isSquare: true,
        child: Icon(
          Icons.more_vert_rounded,
          key: _menuButtonKey,
          color: Colors.white,
          size: 18,
        ),
      );

  void _showOptionsMenu(BuildContext context) {
    final renderBox =
        _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      color: Colors.white,
      elevation: 16,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: RelativeRect.fromLTRB(
        offset.dx - 180,
        offset.dy + size.height + 6,
        offset.dx + size.width,
        offset.dy + size.height + 300,
      ),
      items: [
        _menuItem('encerrados', Icons.archive_outlined,
            'Ver orçamentos encerrados', const Color(0xFF546E7A)),
      ],
    ).then((value) {
      if (!context.mounted) return;
      if (value == 'encerrados') _navigateToEncerrados();
    });
  }

  PopupMenuItem<String> _menuItem(
      String value, IconData icon, String label, Color color) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1F36),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: OrcamentosLoading(message: 'Carregando orçamentos...'),
      );
    }

    if (_orcamentos.isEmpty) {
      if (_temFiltroAtivo) {
        return InfoStateWidget(
          icon: Icons.filter_alt_off_rounded,
          iconColor: Colors.grey[400]!,
          message: 'Nenhum orçamento encontrado',
          buttonText: 'Limpar filtros',
          buttonForegroundColor: _gradientColors[2],
          onPressed: _limparFiltros,
        );
      }
      return _isEncerrados
          ? InfoStateWidget(
              icon: Icons.archive_outlined,
              iconColor: Colors.grey[400]!,
              message: 'Nenhum orçamento encerrado',
            )
          : OrcamentosPageEmptyState(
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
                  onRefresh: _fetchOrcamentos,
                  index: index,
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

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/form_gasto_variado_page/form_gasto_variado_page.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/gasto_variado_detalhes_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/dia_group.dart';
import 'package:orcamentos_app/components/gastos_variados_page/filtros_sheet.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_header.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_page_empty_state.dart';
import 'package:orcamentos_app/components/gastos_variados_page/web/gastos_web_content.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/budgets/pages/orcamento_detalhes_page.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_page_toolbar.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:provider/provider.dart';

class GastosVariadosPage extends StatefulWidget {
  final int orcamentoId;

  const GastosVariadosPage({
    super.key,
    required this.orcamentoId,
  });

  @override
  _GastosVariadosPageState createState() => _GastosVariadosPageState();
}

class _GastosVariadosPageState extends State<GastosVariadosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<GastoVariadoResponseDto>> _gastosVariaveis;
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;
  int? _filtroCategoriaId;
  List<CategoriaGastoResponseDto> _categorias = [];
  String _ordenacaoCampo = 'data_pgto';
  bool _ordenacaoAscendente = false; // mais recente primeiro

  late final Future<OrcamentoResponseDto> _orcamento = _getOrcamento();

  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _gastosVariaveis = _fetchGastos();
    _fetchCategorias();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  Future<List<GastoVariadoResponseDto>> _fetchGastos() async {
    final gastos =
        await _api.getGastosVariados(orcamentoId: widget.orcamentoId);
    _aplicarOrdenacao(gastos);
    return gastos;
  }

  void _aplicarOrdenacao(List<GastoVariadoResponseDto> gastos) {
    gastos.sort((a, b) {
      final cmp = _ordenacaoCampo == 'descricao'
          ? a.descricao.compareTo(b.descricao)
          : a.dataPgto.compareTo(b.dataPgto);
      return _ordenacaoAscendente ? cmp : -cmp;
    });
  }

  List<GastoVariadoResponseDto> _filtrarGastos(
      List<GastoVariadoResponseDto> gastos) {
    return gastos.where((g) {
      final desc = g.descricao.toLowerCase();
      final correspondeName = desc.contains(_filtroNome.toLowerCase());
      final correspondeStatus = _filtroStatus == null;
      final correspondeData = _filtroData == null ||
          (g.dataPgto.day == _filtroData!.day &&
              g.dataPgto.month == _filtroData!.month &&
              g.dataPgto.year == _filtroData!.year);
      final correspondeCategoria =
          _filtroCategoriaId == null || g.categoriaId == _filtroCategoriaId;
      return correspondeName &&
          correspondeStatus &&
          correspondeData &&
          correspondeCategoria;
    }).toList();
  }

  Future<OrcamentoResponseDto> _getOrcamento() {
    return _api.getOrcamentoById(widget.orcamentoId);
  }

  Future<void> _fetchCategorias() async {
    try {
      final categorias = await _api.getCategorias();
      if (mounted) setState(() => _categorias = categorias);
    } catch (_) {}
  }

  void _aplicarFiltros(
      String nome, String? status, DateTime? data, String campo, bool asc) {
    setState(() {
      _filtroNome = nome;
      _filtroStatus = status;
      _filtroData = data;
      _ordenacaoCampo = campo;
      _ordenacaoAscendente = asc;
      _gastosVariaveis = _fetchGastos();
    });
  }

  void _limparFiltros() {
    setState(() {
      _filtroNome = '';
      _filtroStatus = null;
      _filtroData = null;
      _filtroCategoriaId = null;
      _ordenacaoCampo = 'data_pgto';
      _ordenacaoAscendente = false;
      _gastosVariaveis = _fetchGastos();
    });
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _gastosVariaveis = _fetchGastos();
    });
    _refreshCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  void _showFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Colors.transparent,
      builder: (_) => FiltrosSheet(
        filtroNome: _filtroNome,
        filtroData: _filtroData,
        filtroCategoriaId: _filtroCategoriaId,
        categorias: _categorias,
        ordenacaoCampo: _ordenacaoCampo,
        ordenacaoAscendente: _ordenacaoAscendente,
        onAplicar: (nome, data, campo, asc, categoriaId) {
          setState(() {
            _filtroNome = nome;
            _filtroData = data;
            _filtroCategoriaId = categoriaId;
            _ordenacaoCampo = campo;
            _ordenacaoAscendente = asc;
            _gastosVariaveis = _fetchGastos();
          });
        },
        onLimpar: _limparFiltros,
      ),
    );
  }

  // ─── Agrupa gastos por dia ────────────────────────────────────────────────
  Map<String, List<GastoVariadoResponseDto>> _agruparPorDia(
      List<GastoVariadoResponseDto> gastos) {
    final Map<String, List<GastoVariadoResponseDto>> grupos = {};
    for (final g in gastos) {
      final key = DateFormat('yyyy-MM-dd').format(g.dataPgto);
      grupos.putIfAbsent(key, () => []).add(g);
    }
    return grupos;
  }

  bool get _temFiltroAtivo =>
      _filtroNome.isNotEmpty ||
      _filtroStatus != null ||
      _filtroData != null ||
      _filtroCategoriaId != null;

  Future<void> _abrirDetalhes(GastoVariadoResponseDto gasto) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesGastoVariadoPage(
          gastoId: gasto.id,
          orcamentoId: gasto.orcamentoId,
        ),
      ),
    );
    if (!mounted) return;
    setState(() => _gastosVariaveis = _fetchGastos());
  }

  Future<void> _novoGasto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CriacaoGastoVariadoPage(orcamentoId: widget.orcamentoId),
      ),
    );
    if (!mounted) return;
    setState(() => _gastosVariaveis = _fetchGastos());
  }

  /// Layout de desktop apenas na web e com espaço suficiente.
  static const double _larguraMinimaWeb = 720;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isWeb = kIsWeb && constraints.maxWidth >= _larguraMinimaWeb;
      return Scaffold(
        backgroundColor: const Color(0xFFF4F5F9),
        body: isWeb ? _buildWeb() : _buildMobile(),
        floatingActionButton: isWeb ? null : _buildFab(),
      );
    });
  }

  // ── Versão web ──────────────────────────────────────────────────────────────
  Widget _buildWeb() {
    return Column(
      children: [
        FutureBuilder<OrcamentoResponseDto>(
          future: _orcamento,
          builder: (context, snapshot) => WebPageToolbar(
            titulo: 'Gastos Variados',
            breadcrumb: [
              WebCrumb('Orçamentos',
                  onTap: () => context
                      .read<NavigationController>()
                      .select(NavigationController.orcamentosIndex)),
              WebCrumb(
                snapshot.data?.nome ?? 'Orçamento',
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OrcamentoDetalhesPage(orcamentoId: widget.orcamentoId),
                  ),
                ),
              ),
              const WebCrumb('Gastos Variados'),
            ],
            subtitulo: 'Extrato de lançamentos',
            busca: _filtroNome,
            temFiltroAtivo: _temFiltroAtivo,
            podeCriar:
                snapshot.hasData && snapshot.data!.dataEncerramento == null,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onBuscar: (v) => setState(() => _filtroNome = v),
            onFiltros: _showFiltros,
            onRefresh: _handleRefresh,
            onNovoGasto: _novoGasto,
            onBack: Navigator.of(context).canPop()
                ? () => Navigator.of(context).pop()
                : null,
          ),
        ),
        Expanded(
          child: FutureBuilder<List<GastoVariadoResponseDto>>(
            future: _gastosVariaveis,
            builder: (context, snapshot) {
              final estado = _estadoVazio(snapshot);
              if (estado != null) return estado;

              final todos = snapshot.data!;
              return GastosWebContent(
                todos: todos,
                filtrados: _filtrarGastos(todos),
                categorias: _categorias,
                categoriaId: _filtroCategoriaId,
                data: _filtroData,
                onCategoria: (id) => setState(() => _filtroCategoriaId = id),
                onData: (d) => setState(() => _filtroData = d),
                onLimpar: _limparFiltros,
                onTapItem: _abrirDetalhes,
              );
            },
          ),
        ),
      ],
    );
  }

  /// Loading, erro ou vazio; `null` quando há gastos a exibir.
  Widget? _estadoVazio(AsyncSnapshot<List<GastoVariadoResponseDto>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        snapshot.data == null) {
      return Center(
          child: OrcamentosLoading(message: 'Carregando gastos variados...'));
    }
    if (snapshot.hasError) {
      return Center(
          child: Text('Erro: ${snapshot.error}',
              style: TextStyle(color: Colors.grey[600])));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const GastosPageEmptyState();
    }
    if (_filtrarGastos(snapshot.data!).isEmpty) {
      return GastosPageEmptyState(
          comFiltros: true, onLimparFiltros: _limparFiltros);
    }
    return null;
  }

  // ── Versão mobile ───────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return Column(
      children: [
        GastosHeader(
          auth: Provider.of<AuthState>(context),
          isRefreshing: _isRefreshing,
          refreshCtrl: _refreshCtrl,
          onRefresh: _handleRefresh,
          onFiltros: _showFiltros,
          onBack: () => Navigator.of(context).pop(),
          gastosFuture: _gastosVariaveis,
          filtrar: _filtrarGastos,
          temFiltroAtivo: _temFiltroAtivo,
        ),
        Expanded(
          child: FutureBuilder<List<GastoVariadoResponseDto>>(
            future: _gastosVariaveis,
            builder: (context, snapshot) {
              final estado = _estadoVazio(snapshot);
              if (estado != null) return estado;

              final grupos = _agruparPorDia(_filtrarGastos(snapshot.data!));
              final dias = grupos.keys.toList();

              return RefreshIndicator(
                color: Colors.purple[700],
                onRefresh: () async {
                  setState(() => _gastosVariaveis = _fetchGastos());
                  await _gastosVariaveis;
                },
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final dia = dias[index];
                            final itens = grupos[dia]!;
                            final totalDia = itens.fold<double>(0,
                                (s, g) => s + (double.tryParse(g.valor) ?? 0));
                            return DiaGroup(
                              diaKey: dia,
                              itens: itens,
                              totalDia: totalDia,
                              onTapItem: _abrirDetalhes,
                            );
                          },
                          childCount: dias.length,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFab() {
    return FutureBuilder<OrcamentoResponseDto>(
      future: _orcamento,
      builder: (context, snapshot) {
        final isAtivo =
            snapshot.hasData && snapshot.data!.dataEncerramento == null;
        if (!isAtivo) return const SizedBox.shrink();
        return FloatingActionButton.extended(
          onPressed: _novoGasto,
          backgroundColor: Colors.purple[700],
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Novo Gasto',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        );
      },
    );
  }
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/form_gasto_fixo_page/form_gasto_fixo_page.dart';
import 'package:orcamentos_app/components/gasto_fixo_detalhes_page/gasto_fixo_detalhes_page.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/copiar_gastos_fixos_page.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/filtros_sheet.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/fixos_empty_state.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/fixos_header.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gasto_fixo_status.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/pagos_dia_group.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/pagos_header.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/status_group.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/web/gastos_fixos_web_content.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/budgets/pages/orcamento_detalhes_page.dart';
import 'package:orcamentos_app/features/shared/components/web/web_breadcrumb.dart';
import 'package:orcamentos_app/features/shared/components/web/web_botoes.dart';
import 'package:orcamentos_app/features/shared/components/web/web_page_toolbar.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_controller.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:provider/provider.dart';

class GastosFixosPage extends StatefulWidget {
  final int orcamentoId;

  const GastosFixosPage({
    super.key,
    required this.orcamentoId,
  });

  @override
  _GastosFixosPageState createState() => _GastosFixosPageState();
}

class _GastosFixosPageState extends State<GastosFixosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<GastoFixoResponseDto>> _gastosFixos;
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;
  int? _filtroCategoriaId;
  List<CategoriaGastoResponseDto> _categorias = [];

  late final Future<OrcamentoResponseDto> _orcamento = _getOrcamento();

  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _gastosFixos = _fetchGastos();
    _fetchCategorias();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  Future<List<GastoFixoResponseDto>> _fetchGastos() {
    return _api.getGastosFixos(orcamentoId: widget.orcamentoId);
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

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _gastosFixos = _fetchGastos();
    });
    _refreshCtrl.repeat();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _navegar(GastoFixoResponseDto g) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesGastoFixoPage(
          gastoId: g.id,
          orcamentoId: g.orcamentoId,
        ),
      ),
    );
    _handleRefresh();
  }

  void _abrirCopiarGastos() async {
    final copiou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CopiarGastosFixosPage(
          orcamentoDestinoId: widget.orcamentoId,
        ),
      ),
    );
    if (copiou == true) _handleRefresh();
  }

  List<GastoFixoResponseDto> _filtrar(List<GastoFixoResponseDto> gastos) {
    return gastos.where((g) {
      final desc = g.descricao.toLowerCase();
      final status = statusDoGastoFixo(g);
      final nomeOk = desc.contains(_filtroNome.toLowerCase());
      final statusOk = _filtroStatus == null || _filtroStatus == status;
      final dataOk = _filtroData == null || (() {
        final campo = status == 'PAGO' ? g.dataPgto : g.dataVenc;
        if (campo == null) return false;
        return campo.year == _filtroData!.year &&
            campo.month == _filtroData!.month &&
            campo.day == _filtroData!.day;
      })();
      final categoriaOk =
          _filtroCategoriaId == null || g.categoriaId == _filtroCategoriaId;
      return nomeOk && statusOk && dataOk && categoriaOk;
    }).toList();
  }

  Map<String, List<GastoFixoResponseDto>> _agrupar(
      List<GastoFixoResponseDto> gastos) {
    final vencidos = <GastoFixoResponseDto>[];
    final pendentes = <GastoFixoResponseDto>[];
    final pagos = <GastoFixoResponseDto>[];

    for (final g in gastos) {
      final s = statusDoGastoFixo(g);
      if (s == 'VENCIDO') vencidos.add(g);
      else if (s == 'PENDENTE') pendentes.add(g);
      else pagos.add(g);
    }

    _sortByDate(vencidos, (g) => g.dataVenc, asc: true);
    _sortByDate(pendentes, (g) => g.dataVenc, asc: true);
    _sortByDate(pagos, (g) => g.dataPgto, asc: false);

    final map = <String, List<GastoFixoResponseDto>>{};
    if (vencidos.isNotEmpty) map['VENCIDO'] = vencidos;
    if (pendentes.isNotEmpty) map['PENDENTE'] = pendentes;
    if (pagos.isNotEmpty) map['PAGO'] = pagos;
    return map;
  }

  /// Separa os pendentes em duas seções: gastos (despesas) e patrimônio.
  /// Com um único tipo presente, a seção mantém o título "Pendentes".
  List<Widget> _gruposPendentes(List<GastoFixoResponseDto> itens) {
    final patrimonio = itens
        .where((g) => g.categoriaGasto.tipo == TipoCategoriaGasto.patrimonio)
        .toList();
    final gastos = itens
        .where((g) => g.categoriaGasto.tipo != TipoCategoriaGasto.patrimonio)
        .toList();
    final separar = patrimonio.isNotEmpty && gastos.isNotEmpty;

    return [
      if (gastos.isNotEmpty)
        StatusGroup(
          status: 'PENDENTE',
          itens: gastos,
          onTapItem: _navegar,
          titulo: separar ? 'Gastos pendentes' : null,
        ),
      if (patrimonio.isNotEmpty)
        StatusGroup(
          status: 'PENDENTE',
          itens: patrimonio,
          onTapItem: _navegar,
          tipo: TipoCategoriaGasto.patrimonio,
          titulo: separar ? 'Patrimônio pendente' : null,
        ),
    ];
  }

  void _sortByDate(List<GastoFixoResponseDto> list,
      DateTime? Function(GastoFixoResponseDto) field, {required bool asc}) {
    list.sort((a, b) {
      final dA = field(a);
      final dB = field(b);
      if (dA == null && dB == null) return 0;
      if (dA == null) return 1;
      if (dB == null) return -1;
      return asc ? dA.compareTo(dB) : dB.compareTo(dA);
    });
  }

  Map<String, List<GastoFixoResponseDto>> _agruparPorDia(
      List<GastoFixoResponseDto> pagos) {
    final map = <String, List<GastoFixoResponseDto>>{};
    for (final g in pagos) {
      final raw = g.dataPgto;
      final key = raw != null
          ? DateFormat('yyyy-MM-dd').format(raw)
          : 'sem_data';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  void _showFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      constraints: const BoxConstraints(maxWidth: 560),
      backgroundColor: Colors.transparent,
      builder: (_) => FiltrosSheet(
        filtroNome: _filtroNome,
        filtroStatus: _filtroStatus,
        filtroData: _filtroData,
        filtroCategoriaId: _filtroCategoriaId,
        categorias: _categorias,
        onAplicar: (nome, status, data, categoriaId) => setState(() {
          _filtroNome = nome;
          _filtroStatus = status;
          _filtroData = data;
          _filtroCategoriaId = categoriaId;
        }),
        onLimpar: () => setState(() {
          _filtroNome = '';
          _filtroStatus = null;
          _filtroData = null;
          _filtroCategoriaId = null;
        }),
      ),
    );
  }

  static const _indigo = Color(0xFF1A237E);

  bool get _temFiltroAtivo =>
      _filtroNome.isNotEmpty ||
      _filtroStatus != null ||
      _filtroData != null ||
      _filtroCategoriaId != null;

  void _limparFiltros() => setState(() {
        _filtroNome = '';
        _filtroStatus = null;
        _filtroData = null;
        _filtroCategoriaId = null;
      });

  Future<void> _novoGasto() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CriacaoGastoFixoPage(orcamentoId: widget.orcamentoId),
      ),
    );
    if (!mounted) return;
    setState(() => _gastosFixos = _fetchGastos());
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

  /// Loading, erro ou vazio; `null` quando há gastos a exibir.
  Widget? _estadoVazio(AsyncSnapshot<List<GastoFixoResponseDto>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting &&
        snapshot.data == null) {
      return Center(
          child: OrcamentosLoading(message: 'Carregando gastos fixos...'));
    }
    if (snapshot.hasError) {
      return Center(
          child: Text('Erro: ${snapshot.error}',
              style: TextStyle(color: Colors.grey[600])));
    }
    if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const FixosEmptyState(
          message: 'Nenhum gasto fixo cadastrado',
          subtitle: 'Adicione um novo gasto usando o botão abaixo');
    }
    if (_filtrar(snapshot.data!).isEmpty) {
      return FixosEmptyState(
        message: 'Nenhum resultado para os filtros',
        subtitle: 'Tente limpar os filtros aplicados',
        showClearButton: true,
        onClear: _limparFiltros,
      );
    }
    return null;
  }

  // ── Versão web ──────────────────────────────────────────────────────────────
  Widget _buildWeb() {
    return Column(
      children: [
        FutureBuilder<OrcamentoResponseDto>(
          future: _orcamento,
          builder: (context, snapshot) => WebPageToolbar(
            titulo: 'Gastos Fixos',
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
              const WebCrumb('Gastos Fixos'),
            ],
            subtitulo: 'Planejamento de despesas',
            cor: _indigo,
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
            acoes: [
              WebOutlinedButton(
                icon: Icons.copy_all_rounded,
                label: 'Copiar do Orçamento',
                onTap: _abrirCopiarGastos,
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<GastoFixoResponseDto>>(
            future: _gastosFixos,
            builder: (context, snapshot) {
              final estado = _estadoVazio(snapshot);
              if (estado != null) return estado;

              return GastosFixosWebContent(
                filtrados: _filtrar(snapshot.data!),
                categorias: _categorias,
                status: _filtroStatus,
                categoriaId: _filtroCategoriaId,
                data: _filtroData,
                onStatus: (s) => setState(() => _filtroStatus = s),
                onCategoria: (id) => setState(() => _filtroCategoriaId = id),
                onData: (d) => setState(() => _filtroData = d),
                onLimpar: _limparFiltros,
                onTapItem: _navegar,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Versão mobile ───────────────────────────────────────────────────────────
  Widget _buildMobile() {
    return Column(
      children: [
        FixosHeader(
          auth: Provider.of<AuthState>(context),
          isRefreshing: _isRefreshing,
          refreshCtrl: _refreshCtrl,
          onRefresh: _handleRefresh,
          onFiltros: _showFiltros,
          onBack: () => Navigator.of(context).pop(),
          onCopiar: _abrirCopiarGastos,
          gastosFuture: _gastosFixos,
          filtrar: _filtrar,
          temFiltroAtivo: _temFiltroAtivo,
        ),
        Expanded(
          child: FutureBuilder<List<GastoFixoResponseDto>>(
            future: _gastosFixos,
            builder: (context, snapshot) {
              final estado = _estadoVazio(snapshot);
              if (estado != null) return estado;

              final grupos = _agrupar(_filtrar(snapshot.data!));
              final widgets = <Widget>[];

              for (final chave in grupos.keys) {
                final itens = grupos[chave]!;
                if (chave == 'PENDENTE') {
                  widgets.addAll(_gruposPendentes(itens));
                } else if (chave != 'PAGO') {
                  widgets.add(StatusGroup(
                      status: chave, itens: itens, onTapItem: _navegar));
                } else {
                  final totalPagos = itens.fold<double>(
                      0, (s, g) => s + (double.tryParse(g.valor ?? '0') ?? 0));
                  widgets.add(PagosHeader(
                      totalItens: itens.length, totalValor: totalPagos));

                  final porDia = _agruparPorDia(itens);
                  for (final diaKey in porDia.keys) {
                    final diaItens = porDia[diaKey]!;
                    final totalDia = diaItens.fold<double>(
                        0, (s, g) => s + (double.tryParse(g.valor ?? '0') ?? 0));
                    widgets.add(PagosDiaGroup(
                      diaKey: diaKey,
                      itens: diaItens,
                      totalDia: totalDia,
                      onTapItem: _navegar,
                    ));
                  }
                }
              }

              return RefreshIndicator(
                color: _indigo,
                onRefresh: () async => _handleRefresh(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (_, i) => widgets[i],
                          childCount: widgets.length,
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
          backgroundColor: _indigo,
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

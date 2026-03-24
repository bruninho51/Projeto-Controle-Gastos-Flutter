import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/form_gasto_fixo_page/form_gasto_fixo_page.dart';
import 'package:orcamentos_app/components/gasto_fixo_detalhes_page/gasto_fixo_detalhes_page.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';

class GastosFixosPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosFixosPage({
    super.key,
    required this.orcamentoId,
    required this.apiToken,
  });

  @override
  _GastosFixosPageState createState() => _GastosFixosPageState();
}

class _GastosFixosPageState extends State<GastosFixosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _gastosFixos;
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;

  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _gastosFixos = _fetchGastos();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGastos() async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'orcamentos/${widget.orcamentoId}/gastos-fixos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    if (r.statusCode == 200) {
      final List<dynamic> data = jsonDecode(r.body);
      return data.map((e) => e as Map<String, dynamic>).toList();
    }
    throw Exception('Falha ao carregar os gastos fixos');
  }

  Future<Map<String, dynamic>> _getOrcamento() async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (r.statusCode >= 200 && r.statusCode <= 299) return jsonDecode(r.body);
    return {};
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

  Future<void> _navegar(Map<String, dynamic> g) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesGastoFixoPage(
          gastoId: g['id'],
          orcamentoId: g['orcamento_id'],
          apiToken: widget.apiToken,
        ),
      ),
    );
    setState(() => _gastosFixos = _fetchGastos());
  }

  String _statusOf(Map<String, dynamic> g) {
    if (g['valor'] != null) return 'PAGO';
    final vencStr = g['data_venc'] as String?;
    if (vencStr != null) {
      try {
        if (DateTime.parse(vencStr).isBefore(DateTime.now())) return 'VENCIDO';
      } catch (_) {}
    }
    return 'PENDENTE';
  }

  List<Map<String, dynamic>> _filtrar(List<Map<String, dynamic>> gastos) {
    return gastos.where((g) {
      final desc = g['descricao'].toString().toLowerCase();
      final status = _statusOf(g);
      final nomeOk = desc.contains(_filtroNome.toLowerCase());
      final statusOk = _filtroStatus == null || _filtroStatus == status;
      final dataOk = _filtroData == null || (() {
        final campo = status == 'PAGO' ? g['data_pgto'] : g['data_venc'];
        if (campo == null) return false;
        final dt = DateTime.tryParse(campo);
        if (dt == null) return false;
        return dt.year == _filtroData!.year &&
            dt.month == _filtroData!.month &&
            dt.day == _filtroData!.day;
      })();
      return nomeOk && statusOk && dataOk;
    }).toList();
  }

  Map<String, List<Map<String, dynamic>>> _agrupar(
      List<Map<String, dynamic>> gastos) {
    final vencidos = <Map<String, dynamic>>[];
    final pendentes = <Map<String, dynamic>>[];
    final pagos = <Map<String, dynamic>>[];

    for (final g in gastos) {
      final s = _statusOf(g);
      if (s == 'VENCIDO') vencidos.add(g);
      else if (s == 'PENDENTE') pendentes.add(g);
      else pagos.add(g);
    }

    _sortByDate(vencidos, 'data_venc', asc: true);
    _sortByDate(pendentes, 'data_venc', asc: true);
    _sortByDate(pagos, 'data_pgto', asc: false);

    final map = <String, List<Map<String, dynamic>>>{};
    if (vencidos.isNotEmpty) map['VENCIDO'] = vencidos;
    if (pendentes.isNotEmpty) map['PENDENTE'] = pendentes;
    if (pagos.isNotEmpty) map['PAGO'] = pagos;
    return map;
  }

  void _sortByDate(List<Map<String, dynamic>> list, String field,
      {required bool asc}) {
    list.sort((a, b) {
      final dA = DateTime.tryParse(a[field] ?? '');
      final dB = DateTime.tryParse(b[field] ?? '');
      if (dA == null && dB == null) return 0;
      if (dA == null) return 1;
      if (dB == null) return -1;
      return asc ? dA.compareTo(dB) : dB.compareTo(dA);
    });
  }

  Map<String, List<Map<String, dynamic>>> _agruparPorDia(
      List<Map<String, dynamic>> pagos) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final g in pagos) {
      final raw = g['data_pgto'] as String?;
      final key = raw != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(raw))
          : 'sem_data';
      map.putIfAbsent(key, () => []).add(g);
    }
    return map;
  }

  void _showFiltros() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltrosSheet(
        filtroNome: _filtroNome,
        filtroStatus: _filtroStatus,
        filtroData: _filtroData,
        onAplicar: (nome, status, data) => setState(() {
          _filtroNome = nome;
          _filtroStatus = status;
          _filtroData = data;
        }),
        onLimpar: () => setState(() {
          _filtroNome = '';
          _filtroStatus = null;
          _filtroData = null;
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          _FixosHeader(
            auth: Provider.of<AuthProvider>(context),
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onFiltros: _showFiltros,
            onBack: () => Navigator.of(context).pop(),
            temFiltroAtivo: _filtroNome.isNotEmpty ||
                _filtroStatus != null ||
                _filtroData != null,
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _gastosFixos,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    snapshot.data == null) {
                  return Center(
                      child: CircularProgressIndicator(
                          color: const Color(0xFF1A237E), strokeWidth: 2.5));
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text('Erro: ${snapshot.error}',
                          style: TextStyle(color: Colors.grey[600])));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _EmptyState(
                      message: 'Nenhum gasto fixo cadastrado',
                      subtitle: 'Adicione um novo gasto usando o botão abaixo');
                }

                final filtrados = _filtrar(snapshot.data!);
                if (filtrados.isEmpty) {
                  return _EmptyState(
                    message: 'Nenhum resultado para os filtros',
                    subtitle: 'Tente limpar os filtros aplicados',
                    showClearButton: true,
                    onClear: () => setState(() {
                      _filtroNome = '';
                      _filtroStatus = null;
                      _filtroData = null;
                    }),
                  );
                }

                final grupos = _agrupar(filtrados);
                final widgets = <Widget>[];

                for (final chave in grupos.keys) {
                  final itens = grupos[chave]!;
                  if (chave != 'PAGO') {
                    widgets.add(_StatusGroup(
                        status: chave, itens: itens, onTapItem: _navegar));
                  } else {
                    final totalPagos = itens.fold<double>(
                        0,
                            (s, g) => s +
                            (double.tryParse(g['valor']?.toString() ?? '0') ??
                                0));
                    widgets.add(_PagosHeader(
                        totalItens: itens.length, totalValor: totalPagos));

                    final porDia = _agruparPorDia(itens);
                    for (final diaKey in porDia.keys) {
                      final diaItens = porDia[diaKey]!;
                      final totalDia = diaItens.fold<double>(
                          0,
                              (s, g) => s +
                              (double.tryParse(
                                  g['valor']?.toString() ?? '0') ??
                                  0));
                      widgets.add(_PagosDiaGroup(
                        diaKey: diaKey,
                        itens: diaItens,
                        totalDia: totalDia,
                        onTapItem: _navegar,
                      ));
                    }
                  }
                }

                return RefreshIndicator(
                  color: const Color(0xFF1A237E),
                  onRefresh: () async {
                    setState(() => _gastosFixos = _fetchGastos());
                    await _gastosFixos;
                  },
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
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _getOrcamento(),
        builder: (context, snapshot) {
          final isAtivo = snapshot.hasData &&
              snapshot.data!['data_encerramento'] == null;
          if (!isAtivo) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CriacaoGastoFixoPage(
                    orcamentoId: widget.orcamentoId,
                    apiToken: widget.apiToken,
                  ),
                ),
              );
              setState(() => _gastosFixos = _fetchGastos());
            },
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Novo Gasto',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Grupo de status (VENCIDO / PENDENTE)
// ═══════════════════════════════════════════════════════════════════════════════
class _StatusGroup extends StatelessWidget {
  final String status;
  final List<Map<String, dynamic>> itens;
  final Future<void> Function(Map<String, dynamic>) onTapItem;

  const _StatusGroup(
      {required this.status, required this.itens, required this.onTapItem});

  Color get _color => status == 'VENCIDO'
      ? const Color(0xFFE53935)
      : const Color(0xFFF4511E);
  IconData get _icon => status == 'VENCIDO'
      ? Icons.warning_amber_rounded
      : Icons.schedule_rounded;
  String get _label => status == 'VENCIDO' ? 'Vencidos' : 'Pendentes';
  double get _totalPrevisto => itens.fold(
      0, (s, g) => s + (double.tryParse(g['previsto']?.toString() ?? '0') ?? 0));

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
          child: Row(
            children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                    color: _color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(_icon, color: _color, size: 15),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _color)),
                  Text('${itens.length} ${itens.length == 1 ? 'item' : 'itens'}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt.format(_totalPrevisto),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _color, letterSpacing: -0.2)),
                Text('previsto', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: itens.asMap().entries.map((e) => _GastoFixoItem(
                gasto: e.value,
                isLast: e.key == itens.length - 1,
                onTap: () => onTapItem(e.value))).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Cabeçalho da seção PAGO
// ═══════════════════════════════════════════════════════════════════════════════
class _PagosHeader extends StatelessWidget {
  final int totalItens;
  final double totalValor;
  const _PagosHeader({required this.totalItens, required this.totalValor});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    const color = Color(0xFF43A047);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 4),
      child: Row(
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.check_circle_rounded, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pagos', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
              Text('$totalItens ${totalItens == 1 ? 'item' : 'itens'}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(fmt.format(totalValor),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.2)),
            Text('total pago', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Sub-grupo de pagos por dia
// ═══════════════════════════════════════════════════════════════════════════════
class _PagosDiaGroup extends StatelessWidget {
  final String diaKey;
  final List<Map<String, dynamic>> itens;
  final double totalDia;
  final Future<void> Function(Map<String, dynamic>) onTapItem;

  const _PagosDiaGroup({
    required this.diaKey, required this.itens,
    required this.totalDia, required this.onTapItem,
  });

  String get _diaLabel {
    if (diaKey == 'sem_data') return 'Sem data';
    try {
      final dt = DateTime.parse(diaKey);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day) return 'Hoje';
      if (dt.year == ontem.year && dt.month == ontem.month && dt.day == ontem.day) return 'Ontem';
      return DateFormat("d 'de' MMMM", 'pt_BR').format(dt);
    } catch (_) { return diaKey; }
  }

  String get _diaSemana {
    if (diaKey == 'sem_data') return '';
    try { return DateFormat('EEEE', 'pt_BR').format(DateTime.parse(diaKey)); }
    catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_diaLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
                  if (_diaSemana.isNotEmpty)
                    Text(_diaSemana, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(fmt.format(totalDia),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF43A047), letterSpacing: -0.2)),
                Text('${itens.length} ${itens.length == 1 ? 'lançamento' : 'lançamentos'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: itens.asMap().entries.map((e) => _GastoFixoItem(
                gasto: e.value,
                isLast: e.key == itens.length - 1,
                onTap: () => onTapItem(e.value))).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item individual
// ═══════════════════════════════════════════════════════════════════════════════
class _GastoFixoItem extends StatelessWidget {
  final Map<String, dynamic> gasto;
  final bool isLast;
  final VoidCallback onTap;

  const _GastoFixoItem({required this.gasto, required this.isLast, required this.onTap});

  String _statusOf() {
    if (gasto['valor'] != null) return 'PAGO';
    final v = gasto['data_venc'] as String?;
    if (v != null) {
      try { if (DateTime.parse(v).isBefore(DateTime.now())) return 'VENCIDO'; } catch (_) {}
    }
    return 'PENDENTE';
  }

  Color get _color {
    switch (_statusOf()) {
      case 'VENCIDO': return const Color(0xFFE53935);
      case 'PENDENTE': return const Color(0xFFF4511E);
      default: return const Color(0xFF43A047);
    }
  }

  IconData get _icon {
    switch (_statusOf()) {
      case 'VENCIDO': return Icons.warning_amber_rounded;
      case 'PENDENTE': return Icons.schedule_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '';
    try { return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso)); } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final previsto = double.tryParse(gasto['previsto']?.toString() ?? '0') ?? 0.0;
    final valorPago = gasto['valor'] != null
        ? double.tryParse(gasto['valor'].toString()) ?? 0.0
        : null;
    final descricao = gasto['descricao']?.toString() ?? 'Sem descrição';
    final categoriaNome = gasto['categoriaGasto']?['nome']?.toString();
    final status = _statusOf();

    String subtitulo = '';
    if (status == 'PAGO') {
      subtitulo = 'Pago em ${_fmtDate(gasto['data_pgto'])}';
    } else if (gasto['data_venc'] != null) {
      subtitulo = status == 'VENCIDO'
          ? 'Venceu em ${_fmtDate(gasto['data_venc'])}'
          : 'Vence em ${_fmtDate(gasto['data_venc'])}';
    }
    if (categoriaNome != null && subtitulo.isNotEmpty) {
      subtitulo = '$categoriaNome · $subtitulo';
    } else if (categoriaNome != null) {
      subtitulo = categoriaNome;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(16)) : BorderRadius.zero,
        splashColor: _color.withOpacity(0.06),
        highlightColor: _color.withOpacity(0.03),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_icon, color: _color, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(descricao,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1F36)),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (subtitulo.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(subtitulo,
                            style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ]),
                  ),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(
                      status == 'PAGO' && valorPago != null
                          ? fmt.format(valorPago)
                          : fmt.format(previsto),
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700,
                          color: status == 'PAGO' ? const Color(0xFF43A047) : const Color(0xFF1A1F36),
                          letterSpacing: -0.2),
                    ),
                    if (status == 'PAGO' && valorPago != null && valorPago != previsto) ...[
                      const SizedBox(height: 2),
                      Text('prev. ${fmt.format(previsto)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[400], decoration: TextDecoration.lineThrough)),
                    ],
                    if (status != 'PAGO') ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: _color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(status, style: TextStyle(fontSize: 9, color: _color, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                      ),
                    ],
                  ]),
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
// Header navbar
// ═══════════════════════════════════════════════════════════════════════════════
class _FixosHeader extends StatelessWidget {
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onFiltros;
  final VoidCallback onBack;
  final bool temFiltroAtivo;
  final AuthProvider auth;

  const _FixosHeader({
    required this.isRefreshing, required this.refreshCtrl,
    required this.onRefresh, required this.onFiltros,
    required this.onBack, required this.temFiltroAtivo,
    required this.auth,
  });

  Widget _buildAvatar() {
    if (auth.user?.photoURL != null) {
      return ClipOval(
        child: Image.network(
          auth.user!.photoURL!,
          width: 38, height: 38, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackAvatar(),
        ),
      );
    }
    return _fallbackAvatar();
  }

  Widget _fallbackAvatar() => Container(
    width: 36, height: 36,
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canPop) ...[
                _HeaderButton(onTap: onBack, tooltip: 'Voltar', isSquare: true,
                    child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16)),
                const SizedBox(width: 12),
              ],
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Gastos Fixos',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                  Text('Planejamento de despesas',
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                ]),
              ),
              const SizedBox(width: 10),
              _buildAvatar(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF69F0AE), shape: BoxShape.circle)),
                  const SizedBox(width: 7),
                  const Text('Planejamentos', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
              const Spacer(),
              Stack(
                children: [
                  _HeaderButton(
                    onTap: onFiltros, tooltip: 'Filtros',
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.filter_list_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Filtros', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (temFiltroAtivo)
                    Positioned(
                      top: 2, right: 2,
                      child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFFD740), shape: BoxShape.circle)),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                onTap: onRefresh, tooltip: 'Recarregar', isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(isRefreshing ? 1.0 : 0.9), size: 18),
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
// Modal de filtros
// ═══════════════════════════════════════════════════════════════════════════════
class _FiltrosSheet extends StatefulWidget {
  final String filtroNome;
  final String? filtroStatus;
  final DateTime? filtroData;
  final void Function(String nome, String? status, DateTime? data) onAplicar;
  final VoidCallback onLimpar;

  const _FiltrosSheet({
    required this.filtroNome,
    required this.filtroStatus,
    required this.filtroData,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late TextEditingController _nomeCtrl;
  String? _status;
  DateTime? _data;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.filtroNome);
    _status = widget.filtroStatus;
    _data = widget.filtroData;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),

            // Título
            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list_rounded, color: Color(0xFF1A237E), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Filtros', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
            ]),
            const SizedBox(height: 20),

            // Campo nome
            TextField(
              controller: _nomeCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nome…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3949AB), size: 20),
                filled: true, fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            // Status chips
            Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: ['PAGO', 'PENDENTE', 'VENCIDO'].map((s) {
                final selected = _status == s;
                final color = s == 'PAGO'
                    ? const Color(0xFF43A047)
                    : s == 'VENCIDO'
                    ? const Color(0xFFE53935)
                    : const Color(0xFFF4511E);
                return FilterChip(
                  label: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
                  selected: selected,
                  onSelected: (v) => setState(() => _status = v ? s : null),
                  backgroundColor: color.withOpacity(0.08),
                  selectedColor: color,
                  checkmarkColor: Colors.white,
                  side: BorderSide(color: color.withOpacity(0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Filtro de data
            Text('Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _data ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E))),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _data = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _data != null ? const Color(0xFF3949AB) : Colors.grey[200]!,
                            width: _data != null ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, size: 16,
                              color: _data != null ? const Color(0xFF3949AB) : Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text(
                            _data != null
                                ? '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}'
                                : 'Selecionar data',
                            style: TextStyle(fontSize: 14, color: _data != null ? const Color(0xFF1A1F36) : Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_data != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _data = null),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Botões
            Row(children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                  ),
                  onPressed: () { widget.onLimpar(); Navigator.of(context).pop(); },
                  child: Text('Limpar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () { widget.onAplicar(_nomeCtrl.text, _status, _data); Navigator.of(context).pop(); },
                  child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Empty state
// ═══════════════════════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final String message;
  final String subtitle;
  final bool showClearButton;
  final VoidCallback? onClear;

  const _EmptyState({required this.message, required this.subtitle, this.showClearButton = false, this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.06), shape: BoxShape.circle),
            child: Icon(
              showClearButton ? Icons.filter_alt_off_rounded : Icons.receipt_long_rounded,
              size: 48, color: const Color(0xFF3949AB).withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          Text(message, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[700])),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[450])),
          if (showClearButton && onClear != null) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded, size: 16),
              label: const Text('Limpar filtros'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF3949AB)),
            ),
          ],
          const SizedBox(height: 100),
        ],
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

  const _HeaderButton({required this.child, required this.onTap, required this.tooltip, this.isSquare = false});

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
        onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: EdgeInsets.symmetric(horizontal: widget.isSquare ? 10 : 14, vertical: 8),
          decoration: BoxDecoration(
            color: _pressed ? Colors.white.withOpacity(0.28) : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
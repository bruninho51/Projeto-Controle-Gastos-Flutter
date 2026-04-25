import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/form_gasto_variado_page/form_gasto_variado_page.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/gasto_variado_detalhes_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_page_empty_state.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';

import '../common/orcamentos_loading.dart';

class GastosVariadosPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosVariadosPage({
    super.key,
    required this.orcamentoId,
    required this.apiToken,
  });

  @override
  _GastosVariadosPageState createState() => _GastosVariadosPageState();
}

class _GastosVariadosPageState extends State<GastosVariadosPage>
    with SingleTickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _gastosVariaveis;
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;
  String _ordenacaoCampo = 'data_pgto';
  bool _ordenacaoAscendente = false; // mais recente primeiro

  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _gastosVariaveis = _fetchGastos();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchGastos() async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}/gastos-variados',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      final gastos = data.map((e) => e as Map<String, dynamic>).toList();
      _aplicarOrdenacao(gastos);
      return gastos;
    }
    throw Exception('Falha ao carregar os gastos variados');
  }

  void _aplicarOrdenacao(List<Map<String, dynamic>> gastos) {
    gastos.sort((a, b) {
      int cmp;
      if (_ordenacaoCampo == 'descricao') {
        cmp = a['descricao'].toString().compareTo(b['descricao'].toString());
      } else {
        final dA = a['data_pgto'] != null ? DateTime.tryParse(a['data_pgto']) : null;
        final dB = b['data_pgto'] != null ? DateTime.tryParse(b['data_pgto']) : null;
        if (dA == null && dB == null) cmp = 0;
        else if (dA == null) cmp = 1;
        else if (dB == null) cmp = -1;
        else cmp = dA.compareTo(dB);
      }
      return _ordenacaoAscendente ? cmp : -cmp;
    });
  }

  List<Map<String, dynamic>> _filtrarGastos(List<Map<String, dynamic>> gastos) {
    return gastos.where((g) {
      final desc = g['descricao'].toString().toLowerCase();
      final dtPgto = g['data_pgto'];
      final correspondeName = desc.contains(_filtroNome.toLowerCase());
      final correspondeStatus = _filtroStatus == null;
      final correspondeData = _filtroData == null ||
          (dtPgto != null &&
              DateTime.tryParse(dtPgto)?.day == _filtroData!.day &&
              DateTime.tryParse(dtPgto)?.month == _filtroData!.month &&
              DateTime.tryParse(dtPgto)?.year == _filtroData!.year);
      return correspondeName && correspondeStatus && correspondeData;
    }).toList();
  }

  Future<Map<String, dynamic>> _getOrcamento() async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    }
    return {};
  }

  void _aplicarFiltros(String nome, String? status, DateTime? data,
      String campo, bool asc) {
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
      backgroundColor: Colors.transparent,
      builder: (_) => _FiltrosSheet(
        filtroNome: _filtroNome,
        filtroData: _filtroData,
        ordenacaoCampo: _ordenacaoCampo,
        ordenacaoAscendente: _ordenacaoAscendente,
        onAplicar: (nome, data, campo, asc) {
          setState(() {
            _filtroNome = nome;
            _filtroData = data;
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
  Map<String, List<Map<String, dynamic>>> _agruparPorDia(
      List<Map<String, dynamic>> gastos) {
    final Map<String, List<Map<String, dynamic>>> grupos = {};
    for (final g in gastos) {
      final raw = g['data_pgto'] as String?;
      final key = raw != null
          ? DateFormat('yyyy-MM-dd').format(DateTime.parse(raw))
          : 'sem_data';
      grupos.putIfAbsent(key, () => []).add(g);
    }
    return grupos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _GastosHeader(
            auth: Provider.of<AuthState>(context),
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onFiltros: _showFiltros,
            onBack: () => Navigator.of(context).pop(),
            temFiltroAtivo: _filtroNome.isNotEmpty ||
                _filtroStatus != null ||
                _filtroData != null,
          ),

          // ── Lista estilo extrato ────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _gastosVariaveis,
              builder: (context, snapshot) {
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

                final filtrados = _filtrarGastos(snapshot.data!);
                if (filtrados.isEmpty) {
                  return GastosPageEmptyState(
                      comFiltros: true, onLimparFiltros: _limparFiltros);
                }

                final grupos = _agruparPorDia(filtrados);
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
                              final totalDia = itens.fold<double>(
                                0,
                                    (sum, g) =>
                                sum +
                                    (double.tryParse(
                                        g['valor']?.toString() ?? '0') ??
                                        0),
                              );
                              return _DiaGroup(
                                diaKey: dia,
                                itens: itens,
                                totalDia: totalDia,
                                onTapItem: (gasto) async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => DetalhesGastoVariadoPage(
                                        gastoId: gasto['id'],
                                        orcamentoId: gasto['orcamento_id'],
                                        apiToken: widget.apiToken,
                                      ),
                                    ),
                                  );
                                  setState(() =>
                                  _gastosVariaveis = _fetchGastos());
                                },
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
      ),

      // ── FAB ─────────────────────────────────────────────────────────────────
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
                  builder: (_) => CriacaoGastoVariadoPage(
                    orcamentoId: widget.orcamentoId,
                    apiToken: widget.apiToken,
                  ),
                ),
              );
              setState(() => _gastosVariaveis = _fetchGastos());
            },
            backgroundColor: Colors.purple[700],
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
// Modal de filtros — mesmo tema dos gastos fixos
// ═══════════════════════════════════════════════════════════════════════════════
class _FiltrosSheet extends StatefulWidget {
  final String filtroNome;
  final DateTime? filtroData;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;
  final void Function(String nome, DateTime? data, String campo, bool asc) onAplicar;
  final VoidCallback onLimpar;

  const _FiltrosSheet({
    required this.filtroNome,
    required this.filtroData,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  State<_FiltrosSheet> createState() => _FiltrosSheetState();
}

class _FiltrosSheetState extends State<_FiltrosSheet> {
  late TextEditingController _nomeCtrl;
  DateTime? _data;
  late String _campo;
  late bool _asc;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.filtroNome);
    _data = widget.filtroData;
    _campo = widget.ordenacaoCampo;
    _asc = widget.ordenacaoAscendente;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6A1B9A);
    const purpleLight = Color(0xFF7B1FA2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list_rounded,
                    color: purple, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Filtros',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36))),
            ]),
            const SizedBox(height: 20),

            // Campo de nome
            TextField(
              controller: _nomeCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por descrição…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: purpleLight, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: purpleLight, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            // Filtro por data
            Text('Data de pagamento',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5)),
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
                              colorScheme:
                              const ColorScheme.light(primary: purple)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _data = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _data != null
                                ? purple
                                : Colors.grey[200]!,
                            width: _data != null ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16,
                              color:
                              _data != null ? purple : Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text(
                            _data != null
                                ? '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}'
                                : 'Selecionar data',
                            style: TextStyle(
                                fontSize: 14,
                                color: _data != null
                                    ? const Color(0xFF1A1F36)
                                    : Colors.grey[400]),
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
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Ordenação
            Text('Ordenação',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                _OrdemChip(
                  label: 'Descrição',
                  selected: _campo == 'descricao',
                  asc: _asc,
                  color: purple,
                  onTap: () => setState(() {
                    if (_campo == 'descricao') {
                      _asc = !_asc;
                    } else {
                      _campo = 'descricao';
                      _asc = true;
                    }
                  }),
                ),
                const SizedBox(width: 8),
                _OrdemChip(
                  label: 'Data',
                  selected: _campo == 'data_pgto',
                  asc: _asc,
                  color: purple,
                  onTap: () => setState(() {
                    if (_campo == 'data_pgto') {
                      _asc = !_asc;
                    } else {
                      _campo = 'data_pgto';
                      _asc = false;
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!)),
                  ),
                  onPressed: () {
                    widget.onLimpar();
                    Navigator.of(context).pop();
                  },
                  child: Text('Limpar',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.onAplicar(
                        _nomeCtrl.text, _data, _campo, _asc);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _OrdemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool asc;
  final Color color;
  final VoidCallback onTap;

  const _OrdemChip({
    required this.label,
    required this.selected,
    required this.asc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.grey[200]!,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.grey[500])),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Grupo de um dia — cabeçalho + itens + total do dia
// ═══════════════════════════════════════════════════════════════════════════════
class _DiaGroup extends StatelessWidget {
  final String diaKey;
  final List<Map<String, dynamic>> itens;
  final double totalDia;
  final Future<void> Function(Map<String, dynamic>) onTapItem;

  const _DiaGroup({
    required this.diaKey,
    required this.itens,
    required this.totalDia,
    required this.onTapItem,
  });

  String get _diaLabel {
    if (diaKey == 'sem_data') return 'Sem data';
    try {
      final dt = DateTime.parse(diaKey);
      final hoje = DateTime.now();
      final ontem = hoje.subtract(const Duration(days: 1));
      if (dt.year == hoje.year && dt.month == hoje.month && dt.day == hoje.day)
        return 'Hoje';
      if (dt.year == ontem.year &&
          dt.month == ontem.month &&
          dt.day == ontem.day) return 'Ontem';
      return DateFormat("d 'de' MMMM", 'pt_BR').format(dt);
    } catch (_) {
      return diaKey;
    }
  }

  String get _diaSemana {
    if (diaKey == 'sem_data') return '';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabeçalho do dia ────────────────────────────────────────────────
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
                        letterSpacing: 0.1,
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
              // Total gasto no dia
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmt.format(totalDia),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.purple[700],
                      letterSpacing: -0.2,
                    ),
                  ),
                  Text(
                    '${itens.length} ${itens.length == 1 ? 'lançamento' : 'lançamentos'}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400]),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Card do dia com todos os itens ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: itens.asMap().entries.map((e) {
              final i = e.key;
              final gasto = e.value;
              final isLast = i == itens.length - 1;
              return _ExtratoItem(
                gasto: gasto,
                isLast: isLast,
                onTap: () => onTapItem(gasto),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Item individual do extrato
// ═══════════════════════════════════════════════════════════════════════════════
class _ExtratoItem extends StatelessWidget {
  final Map<String, dynamic> gasto;
  final bool isLast;
  final VoidCallback onTap;

  const _ExtratoItem({
    required this.gasto,
    required this.isLast,
    required this.onTap,
  });

  IconData _iconForCategoria(String? nome) {
    if (nome == null) return Icons.receipt_long_rounded;
    final n = nome.toLowerCase();
    if (_any(n, ['aliment', 'comida', 'restaur', 'mercado'])) return Icons.restaurant_outlined;
    if (_any(n, ['transport', 'carro', 'gasolina', 'uber', 'ônibus'])) return Icons.directions_car_outlined;
    if (_any(n, ['saúde', 'saude', 'médico', 'farmácia', 'hospital'])) return Icons.health_and_safety_outlined;
    if (_any(n, ['educação', 'escola', 'curso', 'livro'])) return Icons.school_outlined;
    if (_any(n, ['casa', 'aluguel', 'condomínio', 'água', 'luz'])) return Icons.home_outlined;
    if (_any(n, ['tecnologia', 'celular', 'computador', 'software'])) return Icons.devices_outlined;
    if (_any(n, ['lazer', 'cinema', 'streaming', 'academia'])) return Icons.sports_esports_outlined;
    if (_any(n, ['roupa', 'vestuário', 'moda'])) return Icons.shopping_bag_outlined;
    if (_any(n, ['investimento', 'poupança', 'banco'])) return Icons.savings_outlined;
    if (_any(n, ['viagem', 'voo', 'hotel'])) return Icons.flight_outlined;
    if (_any(n, ['pet', 'cachorro', 'gato', 'veterinário'])) return Icons.pets_outlined;
    return Icons.receipt_long_rounded;
  }

  bool _any(String text, List<String> keys) => keys.any((k) => text.contains(k));

  Color _colorForCategoria(String? nome) {
    if (nome == null) return const Color(0xFF8E24AA);
    final n = nome.toLowerCase();
    if (_any(n, ['aliment', 'comida', 'restaur'])) return const Color(0xFFF4511E);
    if (_any(n, ['transport', 'carro', 'gasolina'])) return const Color(0xFF1E88E5);
    if (_any(n, ['saúde', 'médico', 'farmácia'])) return const Color(0xFF43A047);
    if (_any(n, ['educação', 'escola', 'curso'])) return const Color(0xFF3949AB);
    if (_any(n, ['casa', 'aluguel'])) return const Color(0xFF00897B);
    if (_any(n, ['lazer', 'cinema'])) return const Color(0xFF039BE5);
    return const Color(0xFF8E24AA);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valor = double.tryParse(gasto['valor']?.toString() ?? '0') ?? 0;
    final descricao = gasto['descricao']?.toString() ?? 'Sem descrição';
    final categoriaNome = gasto['categoriaGasto']?['nome']?.toString();
    final color = _colorForCategoria(categoriaNome);

    final radius = BorderRadius.vertical(
      top: isLast && gasto == gasto ? Radius.zero : Radius.zero,
      bottom: isLast ? const Radius.circular(16) : Radius.zero,
    );

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
                  // Ícone da categoria
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_iconForCategoria(categoriaNome),
                        color: color, size: 20),
                  ),
                  const SizedBox(width: 14),

                  // Descrição + categoria
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
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (categoriaNome != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            categoriaNome,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                fontWeight: FontWeight.w400),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Valor
                  Text(
                    '- ${fmt.format(valor)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[800],
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            // Divisor (exceto no último)
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
// Header — navbar indigo com botões de filtro e refresh
// ═══════════════════════════════════════════════════════════════════════════════
class _GastosHeader extends StatelessWidget {
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onFiltros;
  final VoidCallback onBack;
  final bool temFiltroAtivo;
  final AuthState auth;

  const _GastosHeader({
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onFiltros,
    required this.onBack,
    required this.temFiltroAtivo,
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
    width: 36,
    height: 36,
    decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
  );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A148C), Color(0xFF6A1B9A), Color(0xFF7B1FA2)],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF4A148C).withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: voltar + ícone + título ──────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (canPop) ...[
                _HeaderButton(
                    onTap: onBack,
                    tooltip: 'Voltar',
                    isSquare: true,
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 16)),
                const SizedBox(width: 12),
              ],
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.trending_up_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gastos Variados',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2)),
                    Text('Extrato de lançamentos',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _buildAvatar(),
            ],
          ),

          const SizedBox(height: 16),

          // ── Linha 2: badge + filtros + refresh ────────────────────────────
          Row(
            children: [
              // Badge "Extrato"
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                        color: Color(0xFF69F0AE), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 7),
                  const Text('Lançamentos',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ),

              const Spacer(),

              // Botão Filtros (com indicador se ativo)
              Stack(
                children: [
                  _HeaderButton(
                    onTap: onFiltros,
                    tooltip: 'Filtros',
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.filter_list_rounded,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text('Filtros',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  if (temFiltroAtivo)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFFD740),
                            shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),

              // Refresh
              _HeaderButton(
                onTap: onRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(Icons.refresh_rounded,
                      color: Colors.white
                          .withOpacity(isRefreshing ? 1.0 : 0.9),
                      size: 18),
                ),
              ),
            ],
          ),
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
            border:
            Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
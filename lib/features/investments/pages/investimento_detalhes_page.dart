import 'dart:convert';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/features/budgets/components/metric_card.dart';
import 'package:orcamentos_app/features/shared/components/confirmation_dialog.dart';
import 'package:orcamentos_app/features/shared/components/info_state_widget.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/pulse_dot.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/status_badge.dart';
import 'package:orcamentos_app/features/investments/components/investimento_detalhes_fab.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/utils/http.dart';

class InvestimentoDetalhesPage extends StatefulWidget {
  final int investimentoId;

  const InvestimentoDetalhesPage({
    super.key,
    required this.investimentoId,
  });

  @override
  State<InvestimentoDetalhesPage> createState() => _InvestimentoDetalhesPageState();
}

class _InvestimentoDetalhesPageState extends State<InvestimentoDetalhesPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dadosInvestimento;
  late Future<List<Map<String, dynamic>>> _dadosTimeline;
  final PageController _pageController = PageController();
  final _menuButtonKey = GlobalKey();
  late AnimationController _refreshCtrl;
  int _currentPage = 0;
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _nomeInvestimento = '';
  bool _isEncerrado = false;

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  AuthState get _auth => Provider.of<AuthState>(context, listen: false);

  final _formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );
  final _formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _formatadorData = DateFormat('dd/MM/yyyy');
  final _formatadorPercentual = NumberFormat.percentPattern('pt_BR')
    ..minimumFractionDigits = 2
    ..maximumFractionDigits = 2;

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _carregarDados();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  String _formatarValor(String value) {
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100;
      return _formatador.format(parsedValue);
    }
    return '';
  }

  String _converterParaFormatoNumerico(String valorFormatado) {
    return valorFormatado
        .replaceAll('R\$', '')
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_auth.apiToken}',
    };
  }

  Future<Map<String, dynamic>> _buscarInvestimento(String apiToken) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'investimentos/${widget.investimentoId}',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar investimento');
    }
  }

  Future<List<Map<String, dynamic>>> _buscarTimeline(String apiToken, Map<String, dynamic> investimento) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'investimentos/${widget.investimentoId}/linha-do-tempo',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      data.add({'data_registro': investimento['data_criacao'], 'valor': investimento['valor_inicial']});
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Falha ao carregar timeline');
    }
  }

  Future<void> _updateInvestimento(Map<String, dynamic> data, String successMessage) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'investimentos/${widget.investimentoId}',
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(context: context, message: successMessage);
    } else {
      throw Exception('Falha ao atualizar o investimento');
    }
  }

  Future<void> _encerrarInvestimento() async {
    await _updateInvestimento({
      'data_inatividade': DateTime.now().toIso8601String(),
    }, 'Investimento encerrado com sucesso!');
  }

  Future<void> _reativarInvestimento() async {
    await _updateInvestimento({
      'data_inatividade': null,
    }, 'Investimento reativado com sucesso!');
  }

  Future<void> _deleteInvestimento() async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'investimentos/${widget.investimentoId}',
      headers: _buildHeaders(),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(context: context, message: 'Investimento apagado com sucesso!');
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o investimento');
    }
  }

  Future<void> _deleteItemLinhaDoTempo(int linhaDoTempoId) async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'investimentos/${widget.investimentoId}/linha-do-tempo/$linhaDoTempoId',
      headers: _buildHeaders(),
    );

    if (!mounted) return;
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(context: context, message: 'Entrada apagada com sucesso!');
    } else {
      throw Exception('Falha ao apagar a entrada na linha do tempo');
    }
  }

  Future<void> _createNewItemLinhaDoTempo(DateTime selectedDate, String valor) async {
    final client = await MyHttpClient.create();
    final response = await client.post(
      'investimentos/${widget.investimentoId}/linha-do-tempo',
      headers: _buildHeaders(),
      body: jsonEncode({
        'data_registro': selectedDate.toIso8601String(),
        'valor': valor,
      }),
    );

    if (!mounted) return;
    if (response.statusCode != 201) {
      throw Exception('Falha ao atualizar o investimento');
    }
  }

  Future<void> _carregarDados() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final investimento = await _buscarInvestimento(_auth.apiToken!);
      final timeline = await _buscarTimeline(_auth.apiToken!, investimento);
      final groupedData = _agruparPorMes(timeline);

      if (!mounted) return;
      setState(() {
        _dadosInvestimento = Future.value(investimento);
        _dadosTimeline = Future.value(timeline);
        _groupedData = groupedData;
        _isLoading = false;
        _nomeInvestimento = investimento['nome'] ?? '';
        _isEncerrado = investimento['data_inatividade'] != null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      OrcamentosSnackBar.error(context: context, message: 'Erro ao carregar dados: ${e.toString()}');
    }
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCtrl.repeat();
    await _carregarDados();
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  List<Map<String, dynamic>> _agruparPorMes(List<Map<String, dynamic>> timeline) {
    final Map<String, Map<String, dynamic>> meses = {};
    final formatadorMes = DateFormat('MMMM yyyy', 'pt_BR');

    // Ordena a timeline por data (mais antigo para mais recente)
    timeline.sort((a, b) {
      return DateTime.parse(a['data_registro']).compareTo(DateTime.parse(b['data_registro']));
    });

    for (var entry in timeline) {
      final date = DateTime.parse(entry['data_registro']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthName = formatadorMes.format(date);

      if (!meses.containsKey(monthKey)) {
        meses[monthKey] = {
          'month': monthName,
          'monthKey': monthKey,
          'startValue': double.parse(entry['valor']),
          'endValue': double.parse(entry['valor']),
          'minValue': double.parse(entry['valor']),
          'maxValue': double.parse(entry['valor']),
          'data': [entry],
        };
      } else {
        final currentValue = double.parse(entry['valor']);
        meses[monthKey]!['endValue'] = currentValue;
        meses[monthKey]!['minValue'] = min(meses[monthKey]!['minValue'] as double, currentValue);
        meses[monthKey]!['maxValue'] = max(meses[monthKey]!['maxValue'] as double, currentValue);
        meses[monthKey]!['data'].add(entry);
      }
    }

    // Ordena os meses do mais antigo para o mais recente
    final sortedKeys = meses.keys.toList()..sort((a, b) => a.compareTo(b));

    return sortedKeys.map((key) => meses[key]!).toList();
  }

  // ── Opções do header (encerrar/reativar/apagar) ───────────────────────────

  void _showOptionsMenu(BuildContext context) {
    final renderBox = _menuButtonKey.currentContext!.findRenderObject() as RenderBox;
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
        if (!_isEncerrado) _menuItem('encerrar', Icons.lock_outline_rounded, 'Encerrar investimento', const Color(0xFF546E7A)),
        if (_isEncerrado) _menuItem('reativar', Icons.lock_open_rounded, 'Reativar investimento', const Color(0xFF43A047)),
        _menuItem('apagar', Icons.delete_outline_rounded, 'Apagar investimento', const Color(0xFFE53935), isDanger: true),
      ],
    ).then((value) {
      if (!context.mounted) return;
      switch (value) {
        case 'encerrar':
          ConfirmationDialog.confirmAction(
            context: context,
            title: 'Confirmar Encerramento',
            message: 'Você tem certeza que deseja encerrar este investimento?',
            actionText: 'Encerrar',
            action: () async {
              await _encerrarInvestimento();
              _carregarDados();
            },
          );
          break;
        case 'reativar':
          ConfirmationDialog.confirmAction(
            context: context,
            title: 'Confirmar Reativação',
            message: 'Você tem certeza que deseja reativar este investimento?',
            actionText: 'Reativar',
            action: () async {
              await _reativarInvestimento();
              _carregarDados();
            },
          );
          break;
        case 'apagar':
          ConfirmationDialog.confirmAction(
            context: context,
            title: 'Confirmar Exclusão',
            message: 'Você tem certeza que deseja apagar este investimento?',
            actionText: 'Apagar',
            action: () async => _deleteInvestimento(),
          );
          break;
      }
    });
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, Color color, {bool isDanger = false}) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDanger ? color : const Color(0xFF1A1F36))),
        ]),
      ),
    );
  }

  // ── Dialog de nova entrada na linha do tempo ──────────────────────────────

  void _showCreateItemLinhaDoTempoDialog() {
    final valorController = TextEditingController();
    final dataController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.indigo.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.timeline_rounded, color: Colors.indigo[700], size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Nova Entrada', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.indigo[900])),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: dataController,
                    readOnly: true,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Selecione a data',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.calendar_today_rounded, color: Colors.indigo[400], size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5)),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: dialogContext,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        selectedDate = date;
                        dataController.text = DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                    validator: (value) => (value == null || value.isEmpty) ? 'Selecione uma data' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valorController,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 15),
                    onChanged: (value) {
                      final formatted = _formatarValor(value);
                      valorController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Insira um valor';
                      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (double.tryParse(cleaned) == null) return 'Valor inválido';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'R\$ 0,00',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.attach_money_rounded, color: Colors.indigo[400], size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5)),
                      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent, width: 1)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!)),
                        ),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate() && selectedDate != null) {
                            await _createNewItemLinhaDoTempo(
                              selectedDate!,
                              _converterParaFormatoNumerico(valorController.text),
                            );
                            _carregarDados();
                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Seções da página ──────────────────────────────────────────────────────

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.4)),
  );

  Widget _buildMetricas({
    required double valorInicial,
    required double valorAtual,
    required double valorizacao,
    required double crescimentoTotal,
    required double crescimentoMes,
  }) {
    final isPositivo = valorAtual >= valorInicial;
    final cardDefs = [
      MetricCardDef(title: 'Valor Inicial', value: _formatadorMoeda.format(valorInicial), color: const Color(0xFF3949AB), icon: Icons.account_balance_rounded),
      MetricCardDef(
        title: 'Valor Atual',
        value: _formatadorMoeda.format(valorAtual),
        color: isPositivo ? const Color(0xFF43A047) : const Color(0xFFE53935),
        icon: Icons.account_balance_wallet_rounded,
      ),
      MetricCardDef(
        title: 'Valorização',
        value: _formatadorMoeda.format(valorizacao),
        color: valorizacao >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935),
        icon: valorizacao >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      ),
      MetricCardDef(
        title: 'Cresc. Total',
        value: _formatadorPercentual.format(crescimentoTotal / 100),
        color: crescimentoTotal >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935),
        icon: Icons.show_chart_rounded,
      ),
      MetricCardDef(
        title: 'Cresc. Mensal',
        value: _formatadorPercentual.format(crescimentoMes / 100),
        color: crescimentoMes >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935),
        icon: Icons.calendar_month_rounded,
      ),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      if (isWide) {
        return SizedBox(
          height: 150,
          child: Row(
            children: cardDefs.asMap().entries.map((e) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10),
                  child: MetricCard(def: e.value),
                ),
              );
            }).toList(),
          ),
        );
      }
      return GridView.count(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.35,
        children: cardDefs.map((def) => MetricCard(def: def)).toList(),
      );
    });
  }

  Widget _buildTimelineDetail(Map<String, dynamic> monthData) {
    // Ordenar os lançamentos por data (mais recente primeiro)
    final lancamentos = (monthData['data'] as List<Map<String, dynamic>>)
      ..sort((a, b) => DateTime.parse(b['data_registro']).compareTo(DateTime.parse(a['data_registro'])));

    return Container(
      height: 150,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              'Lançamentos do Mês',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.grey[500], letterSpacing: 0.3),
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: lancamentos.length,
                itemBuilder: (context, index) {
                  final lancamento = lancamentos[index];
                  final data = DateTime.parse(lancamento['data_registro']);
                  final valor = double.parse(lancamento['valor'].toString());
                  final podeApagar = lancamento['id'] != null;

                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 16, right: 4),
                    title: Text(_formatadorData.format(data), style: const TextStyle(fontSize: 13)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatadorMoeda.format(valor),
                          style: TextStyle(
                            color: valor >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: podeApagar ? const Color(0xFFE53935) : Colors.grey[300],
                            size: 20,
                          ),
                          tooltip: podeApagar ? 'Apagar entrada' : null,
                          onPressed: podeApagar
                              ? () async {
                                  final confirmado = await ConfirmationDialog.show(
                                    context: context,
                                    title: 'Confirmar Remoção',
                                    message: 'Você tem certeza que deseja apagar esta entrada?',
                                    confirmText: 'Apagar',
                                  );
                                  if (confirmado == true) {
                                    await _deleteItemLinhaDoTempo(lancamento['id']);
                                    _carregarDados();
                                  }
                                }
                              : null,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(Map<String, dynamic> monthData) {
    final entries = (monthData['data'] as List<Map<String, dynamic>>)
        .map((e) => TimeSeriesData(DateTime.parse(e['data_registro']), double.parse(e['valor'])))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          capitalizeWords(monthData['month']),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36)),
        ),
        const SizedBox(height: 16),
        _buildLineChart(
          entries,
          color: const Color(0xFF3949AB),
          formatBottomLabel: (date) => DateFormat('dd/MM').format(date),
        ),
      ],
    );
  }

  Widget _buildOverallChart(List<Map<String, dynamic>> timeline) {
    final entries = timeline
        .map((e) => TimeSeriesData(DateTime.parse(e['data_registro']), double.parse(e['valor'].toString())))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return _buildLineChart(
      entries,
      color: const Color(0xFF00897B),
      formatBottomLabel: (date) => DateFormat('MM/yy').format(date),
    );
  }

  Widget _buildLineChart(
    List<TimeSeriesData> entries, {
    required Color color,
    required String Function(DateTime date) formatBottomLabel,
  }) {
    final values = entries.map((e) => e.value).toList();
    final minVal = values.reduce(min);
    final maxVal = values.reduce(max);
    final range = maxVal - minVal;
    final pad = range == 0 ? (maxVal.abs() * 0.1 + 1) : range * 0.2;
    final maxX = max(entries.length - 1, 1).toDouble();
    final step = (entries.length / 6).ceil().clamp(1, entries.length);

    return SizedBox(
      height: 240,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: minVal - pad,
          maxY: maxVal + pad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey[100]!, strokeWidth: 1),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              left: BorderSide(color: Colors.grey[200]!, width: 1),
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, _) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _formatAxisValue(value),
                    style: TextStyle(fontSize: 10, color: Colors.grey[400], fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final i = value.round();
                  if (i < 0 || i >= entries.length || i % step != 0) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      formatBottomLabel(entries[i].date),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => color,
              tooltipBorderRadius: BorderRadius.circular(10),
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final i = spot.x.round().clamp(0, entries.length - 1);
                return LineTooltipItem(
                  '${_formatadorData.format(entries[i].date)}\n',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  children: [
                    TextSpan(
                      text: _formatadorMoeda.format(entries[i].value),
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(entries.length, (i) => FlSpot(i.toDouble(), entries[i].value)),
              isCurved: true,
              curveSmoothness: 0.25,
              color: color,
              barWidth: 3,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.25),
                    color.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value.abs() >= 1000000) return 'R\$${(value / 1000000).toStringAsFixed(1)}M';
    if (value.abs() >= 1000) return 'R\$${(value / 1000).toStringAsFixed(0)}k';
    return 'R\$${value.toStringAsFixed(0)}';
  }

  Widget _sectionCard({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      floatingActionButton: InvestimentoDetalhesFAB(
        onAddItemLinhaDoTempo: _showCreateItemLinhaDoTempoDialog,
      ),
      body: Column(
        children: [
          SharedAppBar(
            title: _nomeInvestimento.isEmpty ? 'Detalhes' : _nomeInvestimento,
            subtitle: 'Detalhes do investimento',
            mainIcon: Icons.savings_rounded,
            gradientColors: _gradientColors,
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            bottomContent: StatusBadge(
              leading: PulseDot.variant(_isEncerrado ? PulseVariant.negative : PulseVariant.positive),
              text: _isEncerrado ? 'Encerrado' : 'Ativo',
            ),
            actionButtons: [
              SharedAppBar.headerButton(
                onTap: _handleRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: _refreshCtrl,
                  child: Icon(Icons.refresh_rounded, color: Colors.white.withValues(alpha: _isRefreshing ? 1.0 : 0.9), size: 18),
                ),
              ),
              SharedAppBar.headerButton(
                onTap: () => _showOptionsMenu(context),
                tooltip: 'Opções',
                isSquare: true,
                child: Icon(Icons.more_vert_rounded, key: _menuButtonKey, color: Colors.white, size: 18),
              ),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(child: OrcamentosLoading(message: 'Carregando investimento...'))
                : FutureBuilder(
                    future: Future.wait([_dadosInvestimento, _dadosTimeline]),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return InfoStateWidget(
                          buttonForegroundColor: Colors.red,
                          buttonBackgroundColor: Colors.white,
                          icon: Icons.error,
                          iconColor: Colors.red,
                          message: 'Erro: ${snapshot.error}',
                          buttonText: 'Tentar novamente',
                          onPressed: _carregarDados,
                        );
                      }

                      if (!snapshot.hasData) {
                        return Center(child: OrcamentosLoading(message: 'Carregando investimento...'));
                      }

                      final investimento = snapshot.data![0] as Map<String, dynamic>;

                      final valorInicial = double.parse(investimento['valor_inicial']);
                      final valorAtual = double.parse(investimento['valor_atual']);

                      // Calcular crescimento
                      final crescimentoTotal = ((valorAtual - valorInicial) / valorInicial) * 100;

                      // Calcular valorização
                      final valorizacao = valorAtual - valorInicial;

                      // Obter dados do investimento e timeline
                      final timeline = snapshot.data![1] as List<Map<String, dynamic>>;

                      // Definir o mês atual
                      final agora = DateTime.now();

                      // Encontrar o primeiro valor do mês
                      double? valorInicialMes;
                      final primeiroDiaMes = DateTime(agora.year, agora.month, 1);

                      // Procurar o último registro antes do mês atual
                      for (var entry in timeline) {
                        final data = DateTime.parse(entry['data_registro']);
                        if (data.isBefore(primeiroDiaMes)) {
                          valorInicialMes = double.parse(entry['valor'].toString());
                        }
                      }

                      // Se não encontrou, usar o primeiro registro do mês
                      if (valorInicialMes == null && timeline.isNotEmpty) {
                        final primeiroRegistroMes = timeline.firstWhere(
                          (entry) => DateTime.parse(entry['data_registro']).month == agora.month,
                          orElse: () => timeline.first,
                        );
                        valorInicialMes = double.parse(primeiroRegistroMes['valor'].toString());
                      }

                      // Calcular crescimento do mês atual
                      double crescimentoMes = 0;
                      if (valorInicialMes != null && valorInicialMes != 0) {
                        crescimentoMes = ((valorAtual - valorInicialMes) / valorInicialMes) * 100;
                      }

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionLabel('Métricas'),
                            _buildMetricas(
                              valorInicial: valorInicial,
                              valorAtual: valorAtual,
                              valorizacao: valorizacao,
                              crescimentoTotal: crescimentoTotal,
                              crescimentoMes: crescimentoMes,
                            ),
                            const SizedBox(height: 24),
                            _sectionLabel('EVOLUÇÃO GERAL'),
                            _sectionCard(child: _buildOverallChart(timeline)),
                            const SizedBox(height: 24),
                            _sectionLabel('EVOLUÇÃO MENSAL'),
                            _sectionCard(
                              child: SizedBox(
                                height: 470,
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: PageView.builder(
                                        controller: _pageController,
                                        itemCount: _groupedData.length,
                                        onPageChanged: (index) => setState(() => _currentPage = index),
                                        itemBuilder: (context, index) => Column(
                                          children: [
                                            _buildMonthChart(_groupedData[index]),
                                            _buildTimelineDetail(_groupedData[index]),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List<Widget>.generate(
                                        _groupedData.length,
                                        (index) => AnimatedContainer(
                                          duration: const Duration(milliseconds: 160),
                                          margin: const EdgeInsets.symmetric(horizontal: 3),
                                          width: _currentPage == index ? 18 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(3),
                                            color: _currentPage == index ? const Color(0xFF3949AB) : Colors.grey[300],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
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
    );
  }
}

class TimeSeriesData {
  final DateTime date;
  final double value;

  TimeSeriesData(this.date, this.value);
}

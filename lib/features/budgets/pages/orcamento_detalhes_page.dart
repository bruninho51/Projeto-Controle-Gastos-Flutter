import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_loading.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/features/categories/components/charts/grafico_gasto_categorias.dart';
import 'package:orcamentos_app/features/shared/components/info_state_widget.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/features/shared/components/status_badge.dart';
import 'package:orcamentos_app/features/shared/components/pulse_dot.dart';
import 'package:orcamentos_app/features/budgets/components/metric_card.dart';
import 'package:orcamentos_app/features/budgets/components/menu_metric_card.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/utils/graphql.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/features/shared/components/confirmation_dialog.dart';

class OrcamentoDetalhesPage extends StatefulWidget {
  final int orcamentoId;
  const OrcamentoDetalhesPage({super.key, required this.orcamentoId});

  @override
  State<OrcamentoDetalhesPage> createState() => _OrcamentoDetalhesPageState();
}

class _OrcamentoDetalhesPageState extends State<OrcamentoDetalhesPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _orcamentoDetalhes;
  late Future<Map<String, double>> _spendingData;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;
  final _menuButtonKey = GlobalKey();

  static const _valorInicialActions = [
    MetricCardAction(id: 'set', label: 'Novo valor', description: 'Substitui o valor atual', icon: Icons.edit_rounded, color: Color(0xFF3949AB)),
    MetricCardAction(id: 'add', label: 'Adicionar', description: 'Soma ao valor atual', icon: Icons.add_rounded, color: Color(0xFF43A047)),
    MetricCardAction(id: 'sub', label: 'Subtrair', description: 'Desconta do valor atual', icon: Icons.remove_rounded, color: Color(0xFFE53935)),
  ];

  // Estado extraído do orçamento para o header
  String _nomeOrcamento = '';
  bool _isEncerrado = false;
  String? _dataCriacao;
  String? _dataEncerramento;

  AuthState get _auth => Provider.of<AuthState>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _loadOrcamentoData();
  }

  @override
  void dispose() {
    _refreshCtrl.dispose();
    super.dispose();
  }

  void _loadOrcamentoData() {
    setState(() {
      _orcamentoDetalhes = _fetchOrcamentoDetalhes(widget.orcamentoId);
      _spendingData = _consolidarTotaisPorCategoria(_auth.apiToken!, widget.orcamentoId);
    });
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCtrl.repeat();
    _loadOrcamentoData();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      _refreshCtrl.stop();
      _refreshCtrl.reset();
      setState(() => _isRefreshing = false);
    }
  }

  Future<Map<String, dynamic>> _fetchOrcamentoDetalhes(int orcamentoId) async {
    final graphql = await MyGraphQLClient.create(token: _auth.apiToken!);
    final consolidadoResult = await graphql.query(
      """
      query ConsolidadoOrcamento(\$ids: [Int!]!) {
        consolidadoOrcamentos(filter: { orcamentoIds: \$ids }) {
          quantidadeGastosFixos, quantidadeGastosVariados, quantidadeGastosFixosVencidos
        }
      }
      """,
      variables: {'ids': [orcamentoId]},
    );
    final consolidado = consolidadoResult['consolidadoOrcamentos'] as Map<String, dynamic>;
    final httpClient = await MyHttpClient.create();
    final response = await httpClient.get('orcamentos/$orcamentoId', headers: _buildHeaders());
    if (response.statusCode != 200) throw Exception('Falha ao carregar os detalhes do orçamento');
    final detalhes = jsonDecode(response.body);
    detalhes['gastos_fixos'] = consolidado['quantidadeGastosFixos'].toString();
    detalhes['gastos_variados'] = consolidado['quantidadeGastosVariados'].toString();
    detalhes['gastos_vencidos'] = consolidado['quantidadeGastosFixosVencidos'].toString();

    // Sincroniza estado do header
    if (mounted) {
      setState(() {
        _nomeOrcamento = detalhes['nome'] ?? '';
        _isEncerrado = detalhes['data_encerramento'] != null;
        _dataCriacao = detalhes['data_criacao'];
        _dataEncerramento = detalhes['data_encerramento'];
      });
    }
    return detalhes;
  }

  Map<String, String> _buildHeaders() => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${_auth.apiToken}',
  };

  Future<void> _encerrarOrcamento() =>
      _updateOrcamento({'data_encerramento': DateTime.now().toIso8601String()}, 'Orçamento encerrado com sucesso!');

  Future<void> _reativarOrcamento() =>
      _updateOrcamento({'data_encerramento': null}, 'Orçamento reativado com sucesso!');

  Future<void> _renomearOrcamento(String nome) =>
      _updateOrcamento({'nome': nome}, 'Orçamento atualizado com sucesso!');

  Future<void> _updateOrcamento(Map<String, dynamic> data, String msg) async {
    final client = await MyHttpClient.create();
    final response = await client.patch('orcamentos/${widget.orcamentoId}', headers: _buildHeaders(), body: jsonEncode(data));
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(context: context, message: msg);
      _loadOrcamentoData();
    } else {
      throw Exception('Falha ao atualizar o orçamento');
    }
  }

  Future<void> _deleteOrcamento() async {
    final client = await MyHttpClient.create();
    final response = await client.delete('orcamentos/${widget.orcamentoId}', headers: _buildHeaders());
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(context: context, message: 'Orçamento apagado com sucesso!');
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o orçamento');
    }
  }

  Future<List<dynamic>> _fetchGastos(String path) async {
    final client = await MyHttpClient.create();
    final response = await client.get(path, headers: _buildHeaders());
    if (response.statusCode >= 200 && response.statusCode <= 299) return jsonDecode(response.body);
    return [];
  }

  Future<Map<String, double>> _consolidarTotaisPorCategoria(String apiToken, int orcamentoId) async {
    try {
      final results = await Future.wait([
        _fetchGastos('orcamentos/$orcamentoId/gastos-fixos'),
        _fetchGastos('orcamentos/$orcamentoId/gastos-variados'),
      ]);
      final Map<String, double> totais = {};
      for (final lista in results) {
        for (final gasto in lista) {
          if (gasto is Map<String, dynamic>) {
            final cat = gasto['categoriaGasto']['nome']?.toString() ?? 'Sem Categoria';
            final val = double.tryParse(gasto['valor']?.toString() ?? '0') ?? 0.0;
            totais[cat] = (totais[cat] ?? 0.0) + val;
          }
        }
      }
      return totais;
    } catch (_) {
      return {};
    }
  }

  // ===== NOVOS MÉTODOS PARA O VALOR INICIAL =====
  Future<void> _updateValorInicial(double novoValor) async {
    await _updateOrcamento({'valor_inicial': novoValor.toString()}, 'Valor inicial atualizado!');
  }

  void _showValorInicialDialog(BuildContext context, String actionId, double currentValue, Function(double) onConfirm) {
    final _valorController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    bool _isSubmitting = false;
    final formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    String _formatarValor(String value) {
      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleaned.isNotEmpty) {
        final parsed = (double.tryParse(cleaned) ?? 0.0) / 100;
        return formatador.format(parsed);
      }
      return '';
    }

    String _converterParaNumerico(String valorFormatado) {
      return valorFormatado
          .replaceAll('R\$', '')
          .trim()
          .replaceAll('.', '')
          .replaceAll(',', '.');
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
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
                      BoxShadow(
                        color: Colors.indigo.withValues(alpha: 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header dinâmico baseado na ação
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getActionColor(actionId).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_getActionIcon(actionId), color: _getActionColor(actionId), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _getActionLabel(actionId),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1F36),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getActionDescription(actionId),
                        style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 20),

                      // Input
                      Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _valorController,
                          autofocus: true,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 15),
                          onChanged: (value) {
                            final formatted = _formatarValor(value);
                            _valorController.value = TextEditingValue(
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
                            prefixIcon: Icon(Icons.attach_money_rounded,
                                color: _getActionColor(actionId), size: 20),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding:
                            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[200]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: _getActionColor(actionId), width: 1.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _valorController.clear();
                              },
                              child: Text('Cancelar',
                                  style: TextStyle(
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getActionColor(actionId),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _isSubmitting
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  final valorDigitado = double.tryParse(
                                      _converterParaNumerico(
                                          _valorController.text)) ??
                                      0.0;
                                  double novoValor = currentValue;
                                  switch (actionId) {
                                    case 'set':
                                      novoValor = valorDigitado;
                                      break;
                                    case 'add':
                                      novoValor = currentValue + valorDigitado;
                                      break;
                                    case 'sub':
                                      novoValor = currentValue - valorDigitado;
                                      break;
                                  }
                                  setDialogState(() => _isSubmitting = true);
                                  // Fecha o diálogo e chama o callback
                                  Navigator.of(context).pop();
                                  onConfirm(novoValor);
                                }
                              },
                              child: _isSubmitting
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                                  : const Text('Confirmar',
                                  style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getActionColor(String actionId) {
    switch (actionId) {
      case 'set': return const Color(0xFF3949AB);
      case 'add': return const Color(0xFF43A047);
      case 'sub': return const Color(0xFFE53935);
      default: return Colors.grey;
    }
  }

  IconData _getActionIcon(String actionId) {
    switch (actionId) {
      case 'set': return Icons.edit_rounded;
      case 'add': return Icons.add_rounded;
      case 'sub': return Icons.remove_rounded;
      default: return Icons.help_outline;
    }
  }

  String _getActionLabel(String actionId) {
    switch (actionId) {
      case 'set': return 'Novo valor';
      case 'add': return 'Adicionar';
      case 'sub': return 'Subtrair';
      default: return 'Ação';
    }
  }

  String _getActionDescription(String actionId) {
    switch (actionId) {
      case 'set': return 'Substitui o valor atual';
      case 'add': return 'Soma ao valor atual';
      case 'sub': return 'Desconta do valor atual';
      default: return '';
    }
  }

  // ===== FIM DOS NOVOS MÉTODOS =====

  Widget _buildDashboardCards(Map<String, dynamic> orcamento) {
    final isEncerrado = orcamento['data_encerramento'] != null;
    final valorInicial = double.parse(orcamento['valor_inicial'] ?? '0.0');
    final valorAtual = double.parse(orcamento['valor_atual'] ?? '0.0');
    final valorLivre = double.parse(orcamento['valor_livre'] ?? '0.0');
    final gastosVencidos = int.parse(orcamento['gastos_vencidos']);

    final cardDefs = [
      MetricCardDef(title: 'Valor Inicial', value: formatarValorDouble(valorInicial), color: const Color(0xFF3949AB), icon: Icons.account_balance_rounded),
      MetricCardDef(title: 'Valor Atual', value: formatarValorDouble(valorAtual), color: const Color(0xFF00897B), icon: Icons.bar_chart_rounded),
      MetricCardDef(title: 'Valor Livre', value: formatarValorDouble(valorLivre), color: const Color(0xFF43A047), icon: Icons.account_balance_wallet_rounded),
      MetricCardDef(title: 'Gastos Fixos', value: '${orcamento['gastos_fixos']} itens', color: const Color(0xFF1E88E5), icon: Icons.receipt_long_rounded, onTap: _navigateToGastosFixos),
      MetricCardDef(title: 'Gastos Variados', value: '${orcamento['gastos_variados']} itens', color: const Color(0xFF5E35B1), icon: Icons.trending_up_rounded, onTap: _navigateToGastosVariados),
      MetricCardDef(title: 'Vencidos', value: '$gastosVencidos itens', color: gastosVencidos > 0 ? const Color(0xFFE53935) : const Color(0xFF43A047), icon: gastosVencidos > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      if (isWide) {
        return SizedBox(
          height: 150,
          child: Row(
            children: cardDefs.asMap().entries.map((e) {
              final def = e.value;
              // Para o card "Valor Inicial", usamos o widget com menu de ações
              if (def.title == 'Valor Inicial' && !isEncerrado) {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10),
                    child: MenuMetricCard(
                      def: def,
                      menuActions: _valorInicialActions,
                      onActionSelected: (actionId) => _showValorInicialDialog(
                        context, actionId, valorInicial, _updateValorInicial,
                      ),
                    ),
                  ),
                );
              } else {
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10),
                    child: MetricCard(def: def),
                  ),
                );
              }
            }).toList(),
          ),
        );
      }
      return GridView.count(
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.35,
        children: cardDefs.map((def) {
          if (def.title == 'Valor Inicial' && !isEncerrado) {
            return MenuMetricCard(
              def: def,
              menuActions: _valorInicialActions,
              onActionSelected: (actionId) => _showValorInicialDialog(
                context, actionId, valorInicial, _updateValorInicial,
              ),
            );
          } else {
            return MetricCard(def: def);
          }
        }).toList(),
      );
    });
  }

  Future<void> _navigateToGastosFixos() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GastosFixosPage(orcamentoId: widget.orcamentoId)));
    _loadOrcamentoData();
  }

  Future<void> _navigateToGastosVariados() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GastosVariadosPage(orcamentoId: widget.orcamentoId)));
    _loadOrcamentoData();
  }

  void _showRenameDialog(BuildContext context) {
    final nomeController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 10))]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(12)), child: Icon(Icons.edit_outlined, color: Colors.indigo[700], size: 22)),
                const SizedBox(width: 12),
                Text('Renomear Orçamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.indigo[900])),
              ]),
              const SizedBox(height: 20),
              TextFormField(
                controller: nomeController,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Novo nome do orçamento',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.label_outline, color: Colors.indigo[400], size: 20),
                  filled: true, fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.indigo[400]!, width: 1.5)),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!))),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Cancelar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo[700], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  onPressed: () async {
                    if (nomeController.text.isNotEmpty) { await _renomearOrcamento(nomeController.text); Navigator.of(context).pop(); }
                  },
                  child: const Text('Salvar', style: TextStyle(fontWeight: FontWeight.w700)),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGraficoCategorias() {
    return FutureBuilder<Map<String, double>>(
      future: _spendingData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: OrcamentosLoading(message: 'Carregando o Gŕafico...'));
        if (snapshot.hasError) return InfoStateWidget(buttonForegroundColor: Colors.red, buttonBackgroundColor: Colors.white, icon: Icons.error, iconColor: Colors.red, message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido');
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyGrafico();
        return _GraficoContainer(child: GraficoGastoCategorias(categoryData: snapshot.data!, height: kIsWeb ? 420 : 380, barWidth: kIsWeb ? 28 : 20, title: 'Gastos por Categoria'));
      },
    );
  }

  Widget _buildEmptyGrafico() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.indigo[50], shape: BoxShape.circle), child: Icon(Icons.pie_chart_outline_rounded, size: 40, color: Colors.indigo[300])),
        const SizedBox(height: 16),
        Text('Sem gastos para exibir', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Text('Adicione gastos fixos ou variados para ver o gráfico', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.4)),
  );

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  String get _dateLabel {
    if (_isEncerrado && _dataEncerramento != null) {
      return 'Encerrado em ${_formatDate(_dataEncerramento!)}';
    }
    if (_dataCriacao != null) return 'Criado em ${_formatDate(_dataCriacao!)}';
    return '';
  }

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
        if (!_isEncerrado) _menuItem('rename', Icons.edit_outlined, 'Renomear', Colors.indigo[700]!),
        if (!_isEncerrado) _menuItem('encerrar', Icons.lock_outline_rounded, 'Encerrar orçamento', const Color(0xFF546E7A)),
        if (_isEncerrado) _menuItem('reativar', Icons.lock_open_rounded, 'Reativar orçamento', const Color(0xFF43A047)),
        if (!_isEncerrado) _menuItem('apagar', Icons.delete_outline_rounded, 'Apagar orçamento', const Color(0xFFE53935), isDanger: true),
      ],
    ).then((value) {
      switch (value) {
        case 'rename':
          _showRenameDialog(context);
          break;
        case 'encerrar':
          ConfirmationDialog.confirmAction(
            context: context, title: 'Confirmar Encerramento',
            message: 'Deseja encerrar este orçamento?', actionText: 'Encerrar',
            action: () async { await _encerrarOrcamento(); setState(() {}); },
          );
          break;
        case 'reativar':
          ConfirmationDialog.confirmAction(
            context: context, title: 'Confirmar Reativação',
            message: 'Deseja reativar este orçamento?', actionText: 'Reativar',
            action: () async { await _reativarOrcamento(); setState(() {}); },
          );
          break;
        case 'apagar':
          ConfirmationDialog.confirmAction(
            context: context, title: 'Confirmar Exclusão',
            message: 'Deseja apagar este orçamento?', actionText: 'Apagar',
            action: () async { await _deleteOrcamento(); setState(() {}); },
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
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDanger ? color : const Color(0xFF1A1F36))),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          SharedAppBar(
            title: _nomeOrcamento.isEmpty ? 'Detalhes' : _nomeOrcamento,
            subtitle: 'Detalhes do orçamento',
            mainIcon: Icons.account_balance_wallet_rounded,
            gradientColors: const [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
            showBackButton: true,
            onBack: () => Navigator.of(context).pop(),
            bottomContent: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  leading: PulseDot.variant(_isEncerrado ? PulseVariant.negative : PulseVariant.positive),
                  text: _isEncerrado ? 'Encerrado' : 'Ativo',
                ),
                if (_dateLabel.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      _dateLabel,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 9),
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ],
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

          // ── Corpo ─────────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _orcamentoDetalhes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return Center(child: OrcamentosLoading(message: 'Carregando o Orçamento...'));
                }
                if (snapshot.hasError) {
                  return InfoStateWidget(buttonForegroundColor: Colors.red, buttonBackgroundColor: Colors.white, icon: Icons.error, iconColor: Colors.red, message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido', buttonText: 'Tentar novamente', onPressed: _loadOrcamentoData);
                }
                if (!snapshot.hasData) {
                  return InfoStateWidget(buttonForegroundColor: Colors.orange, buttonBackgroundColor: Colors.white, icon: Icons.warning_amber, iconColor: Colors.orange, message: 'Nenhum dado encontrado');
                }

                final data = snapshot.data!;
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(kIsWeb ? 24 : 16, 16, kIsWeb ? 24 : 16, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Métricas'),
                      _buildDashboardCards(data),
                      const SizedBox(height: 24),
                      _sectionLabel('GASTOS POR CATEGORIA'),
                      _buildGraficoCategorias(),
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

class _GraficoContainer extends StatelessWidget {
  final Widget child;
  const _GraficoContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}
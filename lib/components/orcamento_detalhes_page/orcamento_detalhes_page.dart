import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/form_orcamento_valor_inicial_page/form_orcamento_valor_inicial_page.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/components/common/grafico_gasto_categorias.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/info_state_widget.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/utils/graphql.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';

class OrcamentoDetalhesPage extends StatefulWidget {
  final int orcamentoId;
  const OrcamentoDetalhesPage({super.key, required this.orcamentoId});

  @override
  _OrcamentoDetalhesPageState createState() => _OrcamentoDetalhesPageState();
}

class _OrcamentoDetalhesPageState extends State<OrcamentoDetalhesPage>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _orcamentoDetalhes;
  late Future<Map<String, double>> _spendingData;
  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  // Estado extraído do orçamento para o header
  String _nomeOrcamento = '';
  bool _isEncerrado = false;
  String? _dataCriacao;
  String? _dataEncerramento;

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

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
      _spendingData = _consolidarTotaisPorCategoria(_auth.apiToken, widget.orcamentoId);
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
    final graphql = await MyGraphQLClient.create(token: _auth.apiToken);
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

  Future<void> _navigateToEditValorInicial(double valorInicial) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => FormOrcamentoValorInicialPage(apiToken: _auth.apiToken, orcamentoId: widget.orcamentoId, valorInicial: valorInicial)));
    _loadOrcamentoData();
  }

  Future<void> _navigateToGastosFixos() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GastosFixosPage(apiToken: _auth.apiToken, orcamentoId: widget.orcamentoId)));
    _loadOrcamentoData();
  }

  Future<void> _navigateToGastosVariados() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => GastosVariadosPage(apiToken: _auth.apiToken, orcamentoId: widget.orcamentoId)));
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10))]),
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

  Widget _buildDashboardCards(Map<String, dynamic> orcamento) {
    final isEncerrado = orcamento['data_encerramento'] != null;
    final valorInicial = double.parse(orcamento['valor_inicial'] ?? '0.0');
    final valorAtual = double.parse(orcamento['valor_atual'] ?? '0.0');
    final valorLivre = double.parse(orcamento['valor_livre'] ?? '0.0');
    final gastosVencidos = int.parse(orcamento['gastos_vencidos']);

    final cardDefs = [
      _MetricCardDef(title: 'Valor Inicial', value: formatarValorDouble(valorInicial), color: const Color(0xFF3949AB), icon: Icons.account_balance_rounded, onTap: isEncerrado ? null : () => _navigateToEditValorInicial(valorInicial)),
      _MetricCardDef(title: 'Valor Atual', value: formatarValorDouble(valorAtual), color: const Color(0xFF00897B), icon: Icons.bar_chart_rounded),
      _MetricCardDef(title: 'Valor Livre', value: formatarValorDouble(valorLivre), color: const Color(0xFF43A047), icon: Icons.account_balance_wallet_rounded),
      _MetricCardDef(title: 'Gastos Fixos', value: '${orcamento['gastos_fixos']} itens', color: const Color(0xFF1E88E5), icon: Icons.receipt_long_rounded, onTap: _navigateToGastosFixos),
      _MetricCardDef(title: 'Gastos Variados', value: '${orcamento['gastos_variados']} itens', color: const Color(0xFF5E35B1), icon: Icons.trending_up_rounded, onTap: _navigateToGastosVariados),
      _MetricCardDef(title: 'Vencidos', value: '$gastosVencidos itens', color: gastosVencidos > 0 ? const Color(0xFFE53935) : const Color(0xFF43A047), icon: gastosVencidos > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final isWide = constraints.maxWidth > 800;
      if (isWide) {
        return SizedBox(
          height: 150,
          child: Row(
            children: cardDefs.asMap().entries.map((e) => Expanded(
              child: Padding(padding: EdgeInsets.only(left: e.key == 0 ? 0 : 10), child: _MetricCard(def: e.value)),
            )).toList(),
          ),
        );
      }
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
        crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.35,
        children: cardDefs.map((def) => _MetricCard(def: def)).toList(),
      );
    });
  }

  Widget _buildGraficoCategorias() {
    return FutureBuilder<Map<String, double>>(
      future: _spendingData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Colors.indigo[700], strokeWidth: 2.5));
        if (snapshot.hasError) return InfoStateWidget(buttonForegroundColor: Colors.red, buttonBackgroundColor: Colors.white, icon: Icons.error, iconColor: Colors.red, message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido');
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildEmptyGrafico();
        return _GraficoContainer(child: GraficoGastoCategorias(categoryData: snapshot.data!, height: kIsWeb ? 420 : 380, barWidth: kIsWeb ? 28 : 20, title: 'Gastos por Categoria'));
      },
    );
  }

  Widget _buildEmptyGrafico() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header com tudo integrado ─────────────────────────────────────
          _DetalhesHeader(
            nome: _nomeOrcamento.isEmpty ? 'Detalhes' : _nomeOrcamento,
            isEncerrado: _isEncerrado,
            dataCriacao: _dataCriacao,
            dataEncerramento: _dataEncerramento,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onBack: () => Navigator.of(context).pop(),
            auth: _auth,
            onRenomear: _isEncerrado ? null : () => _showRenameDialog(context),
            onEncerrar: _isEncerrado ? null : () => ConfirmationDialog.confirmAction(
              context: context, title: 'Confirmar Encerramento',
              message: 'Deseja encerrar este orçamento?', actionText: 'Encerrar',
              action: () async { await _encerrarOrcamento(); setState(() {}); },
            ),
            onApagar: _isEncerrado ? null : () => ConfirmationDialog.confirmAction(
              context: context, title: 'Confirmar Exclusão',
              message: 'Deseja apagar este orçamento?', actionText: 'Apagar',
              action: () async { await _deleteOrcamento(); setState(() {}); },
            ),
            onReativar: _isEncerrado ? () => ConfirmationDialog.confirmAction(
              context: context, title: 'Confirmar Reativação',
              message: 'Deseja reativar este orçamento?', actionText: 'Reativar',
              action: () async { await _reativarOrcamento(); setState(() {}); },
            ) : null,
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _orcamentoDetalhes,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                  return Center(child: CircularProgressIndicator(color: Colors.indigo[700], strokeWidth: 2.5));
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
                      _sectionLabel('MÉTRICAS'),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Header com nome, data, 3 pontinhos e refresh — tudo integrado
// ═══════════════════════════════════════════════════════════════════════════════
class _DetalhesHeader extends StatelessWidget {
  final String nome;
  final bool isEncerrado;
  final String? dataCriacao;
  final String? dataEncerramento;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback? onRenomear;
  final VoidCallback? onEncerrar;
  final VoidCallback? onApagar;
  final VoidCallback? onReativar;
  final AuthProvider auth;

  const _DetalhesHeader({
    required this.nome,
    required this.isEncerrado,
    this.dataCriacao,
    this.dataEncerramento,
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onBack,
    required this.auth,
    this.onRenomear,
    this.onEncerrar,
    this.onApagar,
    this.onReativar,
  });

  String _formatDate(String iso) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  String get _dateLabel {
    if (isEncerrado && dataEncerramento != null) {
      return 'Encerrado em ${_formatDate(dataEncerramento!)}';
    }
    if (dataCriacao != null) return 'Criado em ${_formatDate(dataCriacao!)}';
    return '';
  }

  void _showMenu(BuildContext context, GlobalKey key) {
    final renderBox = key.currentContext!.findRenderObject() as RenderBox;
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
        if (onRenomear != null) _menuItem('rename', Icons.edit_outlined, 'Renomear', Colors.indigo[700]!),
        if (onEncerrar != null) _menuItem('encerrar', Icons.lock_outline_rounded, 'Encerrar orçamento', const Color(0xFF546E7A)),
        if (onReativar != null) _menuItem('reativar', Icons.lock_open_rounded, 'Reativar orçamento', const Color(0xFF43A047)),
        if (onApagar != null) _menuItem('apagar', Icons.delete_outline_rounded, 'Apagar orçamento', const Color(0xFFE53935), isDanger: true),
      ],
    ).then((value) {
      switch (value) {
        case 'rename': onRenomear?.call(); break;
        case 'encerrar': onEncerrar?.call(); break;
        case 'reativar': onReativar?.call(); break;
        case 'apagar': onApagar?.call(); break;
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
          Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDanger ? color : const Color(0xFF1A1F36))),
        ]),
      ),
    );
  }

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
    final menuKey = GlobalKey();

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [BoxShadow(color: Color(0x551A237E), blurRadius: 24, offset: Offset(0, 8))],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Linha 1: voltar + ícone + nome + avatar ───────────────────────
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
                child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Detalhes do orçamento',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Avatar
              _buildAvatar(),
            ],
          ),

          const SizedBox(height: 14),

          // ── Linha 2: badge status + data + 3 pontinhos + refresh ──────────
          Row(
            children: [
              // Badge status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.13), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6, height: 6,
                    decoration: BoxDecoration(
                      color: isEncerrado ? Colors.grey[400] : const Color(0xFF69F0AE),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(isEncerrado ? 'Encerrado' : 'Ativo',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ]),
              ),

              // Data
              if (_dateLabel.isNotEmpty) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _dateLabel,
                    style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ] else
                const Spacer(),

              // 3 pontinhos
              _HeaderButton(
                onTap: onRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(Icons.refresh_rounded, color: Colors.white.withOpacity(isRefreshing ? 1.0 : 0.9), size: 18),
                ),
              ),
              const SizedBox(width: 8),
              // Refresh
              _HeaderButton(
                key: menuKey,
                onTap: () => _showMenu(context, menuKey),
                tooltip: 'Opções',
                isSquare: true,
                child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 18),
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

  const _HeaderButton({super.key, required this.child, required this.onTap, required this.tooltip, this.isSquare = false});

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

// ═══════════════════════════════════════════════════════════════════════════════
// _MetricCardDef
// ═══════════════════════════════════════════════════════════════════════════════
class _MetricCardDef {
  final String title;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
  const _MetricCardDef({required this.title, required this.value, required this.color, required this.icon, this.onTap});
}

// ═══════════════════════════════════════════════════════════════════════════════
// _MetricCard
// ═══════════════════════════════════════════════════════════════════════════════
class _MetricCard extends StatefulWidget {
  final _MetricCardDef def;
  const _MetricCard({required this.def});

  @override
  State<_MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<_MetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.def.color;
    final hasAction = widget.def.onTap != null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _hovered ? color.withOpacity(0.18) : Colors.black.withOpacity(0.05), blurRadius: _hovered ? 18 : 8, offset: const Offset(0, 3))]),
        child: Material(
          color: Colors.transparent, borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.def.onTap, borderRadius: BorderRadius.circular(16),
            splashColor: color.withOpacity(0.08), highlightColor: color.withOpacity(0.04),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(widget.def.icon, color: color, size: 18)),
                    if (hasAction) Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.grey[400]),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.def.value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36), letterSpacing: -0.3), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(widget.def.title, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// _GraficoContainer
// ═══════════════════════════════════════════════════════════════════════════════
class _GraficoContainer extends StatelessWidget {
  final Widget child;
  const _GraficoContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}
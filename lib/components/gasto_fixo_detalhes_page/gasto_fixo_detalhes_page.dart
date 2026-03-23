import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';

class DetalhesGastoFixoPage extends StatefulWidget {
  final int gastoId;
  final int orcamentoId;
  final String apiToken;

  const DetalhesGastoFixoPage({
    super.key,
    required this.orcamentoId,
    required this.gastoId,
    required this.apiToken,
  });

  @override
  _DetalhesGastoFixoPageState createState() => _DetalhesGastoFixoPageState();
}

class _DetalhesGastoFixoPageState extends State<DetalhesGastoFixoPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> gasto = {};
  Map<String, dynamic> orcamento = {};
  List<Map<String, dynamic>> _categorias = [];
  int? _categoriaIdSelecionada;

  final _valorCtrl = TextEditingController();
  final _dataCtrl = TextEditingController();
  final _obsCtrl = TextEditingController();

  late AnimationController _refreshCtrl;
  bool _isRefreshing = false;

  final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _refreshCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _loadAll();
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _dataCtrl.dispose();
    _obsCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([_getGasto(), _getOrcamento(), _getCategorias()]);
  }

  void _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    _refreshCtrl.repeat();
    await _loadAll();
    _refreshCtrl.stop();
    _refreshCtrl.reset();
    if (mounted) setState(() => _isRefreshing = false);
  }

  Future<void> _getGasto() async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'orcamentos/${widget.orcamentoId}/gastos-fixos/${widget.gastoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (r.statusCode >= 200 && r.statusCode <= 299) {
      if (mounted) setState(() => gasto = jsonDecode(r.body));
    }
  }

  Future<void> _getOrcamento() async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (r.statusCode >= 200 && r.statusCode <= 299) {
      if (mounted) setState(() => orcamento = jsonDecode(r.body));
    }
  }

  Future<void> _getCategorias() async {
    final client = await MyHttpClient.create();
    final r = await client.get(
      'categorias-gastos',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (r.statusCode >= 200 && r.statusCode <= 299) {
      final List<dynamic> json = jsonDecode(r.body);
      if (mounted) {
        setState(() => _categorias =
            json.map((c) => {'id': c['id'], 'nome': c['nome']}).toList());
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  bool get _isPago => gasto['valor'] != null;
  bool get _isOrcamentoAtivo => orcamento['data_encerramento'] == null;

  String _fmtDate(String? iso) {
    if (iso == null) return 'Não informado';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return 'Data inválida';
    }
  }

  String _formatarInput(String v) {
    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';
    return _fmt.format(double.parse(cleaned) / 100);
  }

  String _toNumeric(String f) =>
      f.replaceAll('R\$', '').trim().replaceAll('.', '').replaceAll(',', '.');

  // ─── Patch ───────────────────────────────────────────────────────────────────
  Future<void> _patch(Map<String, dynamic> body, String msg) async {
    final client = await MyHttpClient.create();
    final r = await client.patch(
      'orcamentos/${widget.orcamentoId}/gastos-fixos/${widget.gastoId}',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode(body),
    );
    if (r.statusCode >= 200 && r.statusCode <= 299) {
      OrcamentosSnackBar.success(context: context, message: msg);
      await _getGasto();
    } else {
      OrcamentosSnackBar.error(context: context, message: 'Falha ao atualizar.');
    }
  }

  Future<void> _delete() async {
    final client = await MyHttpClient.create();
    final r = await client.delete(
      'orcamentos/${widget.orcamentoId}/gastos-fixos/${widget.gastoId}',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    if (r.statusCode == 200) {
      OrcamentosSnackBar.success(
          context: context, message: 'Gasto fixo apagado com sucesso!');
      Navigator.pop(context, true);
    } else {
      OrcamentosSnackBar.error(context: context, message: 'Falha ao apagar.');
    }
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────────
  void _showEditDialog({
    required String title,
    required IconData icon,
    required Widget content,
    required GlobalKey<FormState> formKey,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.blue.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
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
                    decoration: BoxDecoration(
                        color: const Color(0xFF1A237E).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: const Color(0xFF1A237E), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A237E))),
                  ),
                ]),
                const SizedBox(height: 20),
                content,
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
                      onPressed: () => Navigator.of(context).pop(),
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
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        if (formKey.currentState?.validate() ?? false) {
                          Navigator.of(context).pop();
                          onConfirm();
                        }
                      },
                      child: const Text('Salvar',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
    prefixIcon:
    Icon(icon, color: const Color(0xFF3949AB), size: 20),
    filled: true,
    fillColor: Colors.grey[50],
    contentPadding:
    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[200]!)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
        const BorderSide(color: Color(0xFF3949AB), width: 1.5)),
  );

  void _editNome() {
    final ctrl = TextEditingController(text: gasto['descricao']?.toString() ?? '');
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Editar Nome',
      icon: Icons.label_outline_rounded,
      formKey: fk,
      content: TextFormField(
        controller: ctrl,
        autofocus: true,
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('Nome do gasto', Icons.label_outline_rounded),
        validator: (v) => (v == null || v.trim().isEmpty) ? 'Insira um nome' : null,
      ),
      onConfirm: () => _patch({'descricao': ctrl.text.trim()}, 'Nome atualizado!'),
    );
  }

  void _editValorPrevisto() {
    _valorCtrl.clear();
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Valor Previsto',
      icon: Icons.attach_money_rounded,
      formKey: fk,
      content: TextFormField(
        controller: _valorCtrl,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('R\$ 0,00', Icons.attach_money_rounded),
        onChanged: (v) {
          final f = _formatarInput(v);
          _valorCtrl.value =
              TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
        },
        validator: (v) => (v == null || v.isEmpty) ? 'Insira um valor' : null,
      ),
      onConfirm: () =>
          _patch({'previsto': _toNumeric(_valorCtrl.text)}, 'Valor previsto atualizado!'),
    );
  }

  void _editValorPago() {
    _valorCtrl.clear();
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Valor Pago',
      icon: Icons.check_circle_outline_rounded,
      formKey: fk,
      content: TextFormField(
        controller: _valorCtrl,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('R\$ 0,00', Icons.check_circle_outline_rounded),
        onChanged: (v) {
          final f = _formatarInput(v);
          _valorCtrl.value =
              TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
        },
        validator: (v) => (v == null || v.isEmpty) ? 'Insira um valor' : null,
      ),
      onConfirm: () =>
          _patch({'valor': _toNumeric(_valorCtrl.text)}, 'Valor pago atualizado!'),
    );
  }

  void _editDataPagamento() {
    _dataCtrl.clear();
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Data de Pagamento',
      icon: Icons.calendar_today_rounded,
      formKey: fk,
      content: TextFormField(
        controller: _dataCtrl,
        readOnly: true,
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('Selecione a data', Icons.calendar_today_rounded),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1A237E))),
              child: child!,
            ),
          );
          if (picked != null) {
            _dataCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
          }
        },
        validator: (v) =>
        (v == null || v.isEmpty) ? 'Selecione uma data' : null,
      ),
      onConfirm: () async {
        final parsed = DateFormat('dd/MM/yyyy').parse(_dataCtrl.text);
        await _patch({'data_pgto': parsed.toIso8601String()}, 'Data de pagamento atualizada!');
      },
    );
  }

  void _editDataVencimento() {
    _dataCtrl.clear();
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Data de Vencimento',
      icon: Icons.event_rounded,
      formKey: fk,
      content: TextFormField(
        controller: _dataCtrl,
        readOnly: true,
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('Selecione a data', Icons.event_rounded),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (ctx, child) => Theme(
              data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(
                      primary: Color(0xFF1A237E))),
              child: child!,
            ),
          );
          if (picked != null) {
            _dataCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
          }
        },
        validator: (v) =>
        (v == null || v.isEmpty) ? 'Selecione uma data' : null,
      ),
      onConfirm: () async {
        final parsed = DateFormat('dd/MM/yyyy').parse(_dataCtrl.text);
        await _patch({'data_venc': parsed.toIso8601String()}, 'Vencimento atualizado!');
      },
    );
  }

  void _editCategoria() {
    _categoriaIdSelecionada = null;
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Categoria',
      icon: Icons.category_rounded,
      formKey: fk,
      content: StatefulBuilder(builder: (context, setLocal) {
        return _categorias.isEmpty
            ? Center(
            child: CircularProgressIndicator(
                color: const Color(0xFF1A237E)))
            : DropdownButtonFormField<int>(
          value: _categoriaIdSelecionada,
          isExpanded: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(
                vertical: 14, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                    color: Color(0xFF3949AB), width: 1.5)),
          ),
          items: _categorias
              .map((c) => DropdownMenuItem<int>(
              value: c['id'],
              child: Text(c['nome'],
                  overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) =>
              setLocal(() => _categoriaIdSelecionada = v),
          validator: (v) =>
          v == null ? 'Selecione uma categoria' : null,
        );
      }),
      onConfirm: () =>
          _patch({'categoria_id': _categoriaIdSelecionada}, 'Categoria atualizada!'),
    );
  }

  void _editObservacoes() {
    _obsCtrl.text = gasto['observacoes'] ?? '';
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Observações',
      icon: Icons.notes_rounded,
      formKey: fk,
      content: TextFormField(
        controller: _obsCtrl,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(fontSize: 15),
        decoration: _inputDec('Escreva uma observação…', Icons.notes_rounded),
        validator: (v) =>
        (v == null || v.isEmpty) ? 'Insira uma observação' : null,
      ),
      onConfirm: () =>
          _patch({'observacoes': _obsCtrl.text}, 'Observação salva!'),
    );
  }

  // Dialog de pagamento (valor + data juntos)
  void _registrarPagamento() {
    _valorCtrl.clear();
    _dataCtrl.clear();
    final fk = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Registrar Pagamento',
      icon: Icons.payments_rounded,
      formKey: fk,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: _valorCtrl,
            autofocus: true,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 15),
            decoration: _inputDec('R\$ 0,00', Icons.attach_money_rounded),
            onChanged: (v) {
              final f = _formatarInput(v);
              _valorCtrl.value = TextEditingValue(
                  text: f,
                  selection: TextSelection.collapsed(offset: f.length));
            },
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Insira o valor pago' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dataCtrl,
            readOnly: true,
            style: const TextStyle(fontSize: 15),
            decoration: _inputDec('Data do pagamento', Icons.calendar_today_rounded),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2101),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                          primary: Color(0xFF1A237E))),
                  child: child!,
                ),
              );
              if (picked != null) {
                _dataCtrl.text = DateFormat('dd/MM/yyyy').format(picked);
              }
            },
            validator: (v) =>
            (v == null || v.isEmpty) ? 'Selecione a data' : null,
          ),
        ],
      ),
      onConfirm: () async {
        final parsed = DateFormat('dd/MM/yyyy').parse(_dataCtrl.text);
        await _patch({
          'valor': _toNumeric(_valorCtrl.text),
          'data_pgto': parsed.toIso8601String(),
        }, 'Pagamento registrado!');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final descricao = gasto['descricao']?.toString() ?? 'Gasto Fixo';
    final categoriaNome =
        gasto['categoriaGasto']?['nome']?.toString() ?? 'Sem categoria';

    // Vencimento com alerta de atraso
    final dataVencStr = gasto['data_venc'];
    bool isVencido = false;
    if (dataVencStr != null && !_isPago) {
      try {
        isVencido = DateTime.parse(dataVencStr).isBefore(DateTime.now());
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          _FixoHeader(
            descricao: descricao,
            isPago: _isPago,
            isOrcamentoAtivo: _isOrcamentoAtivo,
            isVencido: isVencido,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onBack: () => Navigator.of(context).pop(),
            onDelete: _isOrcamentoAtivo
                ? () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Apagar Gasto',
              message: 'Deseja realmente apagar este gasto fixo?',
              actionText: 'Apagar',
              action: _delete,
            )
                : null,
          ),

          // ── Conteúdo ───────────────────────────────────────────────────────
          Expanded(
            child: gasto.isEmpty || orcamento.isEmpty
                ? Center(
                child: CircularProgressIndicator(
                    color: const Color(0xFF1A237E), strokeWidth: 2.5))
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card de destaque ──────────────────────────────────
                  _ValorDestaque(
                    previsto: gasto['previsto'],
                    valorPago: gasto['valor'],
                    diferenca: gasto['diferenca'],
                    dataPgto: gasto['data_pgto'],
                    dataVenc: gasto['data_venc'],
                    categoriaNome: categoriaNome,
                    isVencido: isVencido,
                  ),

                  // Botão pagar — destaque quando não pago e ativo
                  if (!_isPago && _isOrcamentoAtivo) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _registrarPagamento,
                        icon: const Icon(Icons.payments_rounded, size: 18),
                        label: const Text('Registrar Pagamento',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF43A047),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // ── Detalhes ──────────────────────────────────────────
                  _sectionLabel('DETALHES'),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.label_outline_rounded,
                      color: const Color(0xFF3949AB),
                      label: 'Nome',
                      value: descricao,
                      isFirst: true,
                      onTap: _isOrcamentoAtivo ? _editNome : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.attach_money_rounded,
                      color: const Color(0xFF1E88E5),
                      label: 'Valor previsto',
                      value: gasto['previsto'] != null
                          ? formatarValorDynamic(gasto['previsto'])
                          : 'Não informado',
                      onTap: _isOrcamentoAtivo ? _editValorPrevisto : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: _isPago
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _isPago
                          ? const Color(0xFF43A047)
                          : Colors.grey,
                      label: 'Valor pago',
                      value: _isPago
                          ? formatarValorDynamic(gasto['valor'])
                          : 'Não pago',
                      onTap: _isPago && _isOrcamentoAtivo
                          ? _editValorPago
                          : null,
                    ),
                    if (_isPago) ...[
                      _Divider(),
                      _InfoRow(
                        icon: Icons.calendar_today_rounded,
                        color: const Color(0xFF00897B),
                        label: 'Data de pagamento',
                        value: _fmtDate(gasto['data_pgto']),
                        onTap: _isOrcamentoAtivo ? _editDataPagamento : null,
                      ),
                    ],
                    if (gasto['diferenca'] != null) ...[
                      _Divider(),
                      _InfoRow(
                        icon: Icons.compare_arrows_rounded,
                        color: const Color(0xFFF4511E),
                        label: 'Diferença',
                        value: formatarValorDynamic(gasto['diferenca']),
                      ),
                    ],
                    _Divider(),
                    _InfoRow(
                      icon: Icons.event_rounded,
                      color: isVencido
                          ? const Color(0xFFE53935)
                          : const Color(0xFF546E7A),
                      label: 'Vencimento',
                      value: _fmtDate(gasto['data_venc']),
                      badge: isVencido ? 'Vencido' : null,
                      onTap: _isOrcamentoAtivo ? _editDataVencimento : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.category_rounded,
                      color: const Color(0xFF5E35B1),
                      label: 'Categoria',
                      value: categoriaNome,
                      onTap: _isOrcamentoAtivo ? _editCategoria : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      color: const Color(0xFF039BE5),
                      label: 'Observações',
                      value: gasto['observacoes'] ?? 'Nenhuma observação',
                      isLast: true,
                      onTap: _isOrcamentoAtivo ? _editObservacoes : null,
                    ),
                  ]),

                  if (_isOrcamentoAtivo) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('Toque em um campo para editar',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400])),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 0.8)),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════════════
class _FixoHeader extends StatelessWidget {
  final String descricao;
  final bool isPago;
  final bool isOrcamentoAtivo;
  final bool isVencido;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  const _FixoHeader({
    required this.descricao,
    required this.isPago,
    required this.isOrcamentoAtivo,
    required this.isVencido,
    required this.isRefreshing,
    required this.refreshCtrl,
    required this.onRefresh,
    required this.onBack,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final canPop = Navigator.of(context).canPop();

    // Cor do header muda conforme o estado
    final colors = isVencido && !isPago
        ? [const Color(0xFF8B0000), const Color(0xFFC62828), const Color(0xFFE53935)]
        : isPago
        ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32), const Color(0xFF388E3C)]
        : [const Color(0xFF1A237E), const Color(0xFF283593), const Color(0xFF3949AB)];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors),
        boxShadow: [
          BoxShadow(
              color: colors[0].withOpacity(0.45),
              blurRadius: 24,
              offset: const Offset(0, 8)),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                child: Icon(
                    isPago
                        ? Icons.check_circle_rounded
                        : isVencido
                        ? Icons.warning_amber_rounded
                        : Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(descricao,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.1),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text('Gasto fixo',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              // Badge de status do pagamento
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isPago
                          ? const Color(0xFF69F0AE)
                          : isVencido
                          ? const Color(0xFFFF6E40)
                          : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isPago
                        ? 'Pago'
                        : isVencido
                        ? 'Vencido'
                        : 'Pendente',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
              ),

              const Spacer(),

              if (onDelete != null) ...[
                _HeaderButton(
                  onTap: onDelete!,
                  tooltip: 'Apagar gasto',
                  isSquare: true,
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
              ],

              _HeaderButton(
                onTap: onRefresh,
                tooltip: 'Recarregar',
                isSquare: true,
                child: RotationTransition(
                  turns: refreshCtrl,
                  child: Icon(Icons.refresh_rounded,
                      color:
                      Colors.white.withOpacity(isRefreshing ? 1.0 : 0.9),
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

// ═══════════════════════════════════════════════════════════════════════════════
// Card de destaque do valor
// ═══════════════════════════════════════════════════════════════════════════════
class _ValorDestaque extends StatelessWidget {
  final dynamic previsto;
  final dynamic valorPago;
  final dynamic diferenca;
  final String? dataPgto;
  final String? dataVenc;
  final String categoriaNome;
  final bool isVencido;

  const _ValorDestaque({
    required this.previsto,
    required this.valorPago,
    required this.diferenca,
    required this.dataPgto,
    required this.dataVenc,
    required this.categoriaNome,
    required this.isVencido,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final isPago = valorPago != null;
    final valorDouble =
        double.tryParse((isPago ? valorPago : previsto)?.toString() ?? '0') ?? 0.0;

    final gradientColors = isPago
        ? [const Color(0xFF2E7D32), const Color(0xFF43A047)]
        : isVencido
        ? [const Color(0xFFC62828), const Color(0xFFE57373)]
        : [const Color(0xFF1A237E), const Color(0xFF3949AB)];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: gradientColors[0].withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isPago ? 'Valor pago' : isVencido ? 'Valor previsto (vencido)' : 'Valor previsto',
            style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(valorDouble),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Categoria
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(categoriaNome,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              // Data
              if (dataPgto != null || dataVenc != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    isPago
                        ? 'Pago em ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dataPgto!))}'
                        : dataVenc != null
                        ? 'Vence em ${DateFormat('dd/MM/yyyy').format(DateTime.parse(dataVenc!))}'
                        : '',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11),
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
// Componentes reutilizáveis
// ═══════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? badge;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.badge,
    this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(18) : Radius.zero,
      bottom: isLast ? const Radius.circular(18) : Radius.zero,
    );

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        splashColor: color.withOpacity(0.06),
        highlightColor: color.withOpacity(0.03),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              16, isFirst ? 16 : 12, 16, isLast ? 16 : 12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(value,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1F36))),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(badge!,
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.edit_outlined,
                    size: 15, color: Colors.grey[300]),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 68),
    child: Container(height: 1, color: Colors.grey[100]),
  );
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
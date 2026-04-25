import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';

class DetalhesGastoVariadoPage extends StatefulWidget {
  final int gastoId;
  final int orcamentoId;
  final String apiToken;

  const DetalhesGastoVariadoPage({
    super.key,
    required this.orcamentoId,
    required this.gastoId,
    required this.apiToken,
  });

  @override
  _DetalhesGastoVariadoPageState createState() =>
      _DetalhesGastoVariadoPageState();
}

class _DetalhesGastoVariadoPageState extends State<DetalhesGastoVariadoPage>
    with SingleTickerProviderStateMixin {
  Map<String, dynamic> gasto = {};
  Map<String, dynamic> orcamento = {};
  List<Map<String, dynamic>> _categorias = [];

  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _obsController = TextEditingController();
  int? _categoriaIdSelecionada;

  final _formValorKey = GlobalKey<FormState>();
  final _formCategoriaKey = GlobalKey<FormState>();
  final _formDataKey = GlobalKey<FormState>();
  final _formObsKey = GlobalKey<FormState>();

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
    _valorController.dispose();
    _dataController.dispose();
    _obsController.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _getGasto(),
      _getOrcamento(),
      _obterCategorias(),
    ]);
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
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}/gastos-variados/${widget.gastoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      if (mounted) setState(() => gasto = jsonDecode(response.body));
    }
  }

  Future<void> _getOrcamento() async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      if (mounted) setState(() => orcamento = jsonDecode(response.body));
    }
  }

  Future<void> _obterCategorias() async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'categorias-gastos',
      headers: {'Authorization': 'Bearer ${widget.apiToken}'},
    );
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      final List<dynamic> json = jsonDecode(response.body);
      if (mounted) {
        setState(() => _categorias =
            json.map((c) => {'id': c['id'], 'nome': c['nome']}).toList());
      }
    }
  }

  // ─── Updates ────────────────────────────────────────────────────────────────
  Future<void> _patch(Map<String, dynamic> body, String msg) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/${widget.orcamentoId}/gastos-variados/${widget.gastoId}',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      OrcamentosSnackBar.success(context: context, message: msg);
      await _getGasto();
    } else {
      OrcamentosSnackBar.error(context: context, message: 'Falha ao atualizar.');
    }
  }

  Future<void> _delete() async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'orcamentos/${widget.orcamentoId}/gastos-variados/${widget.gastoId}',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
          context: context, message: 'Gasto apagado com sucesso!');
      Navigator.pop(context, true);
    } else {
      OrcamentosSnackBar.error(context: context, message: 'Falha ao apagar.');
    }
  }

  // ─── Formatação ──────────────────────────────────────────────────────────────
  String _formatarValorInput(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return '';
    return _fmt.format(double.parse(cleaned) / 100);
  }

  String _toNumeric(String formatted) => formatted
      .replaceAll('R\$', '')
      .trim()
      .replaceAll('.', '')
      .replaceAll(',', '.');

  String _formatDate(String? iso) {
    if (iso == null) return 'Não informado';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return 'Data inválida';
    }
  }

  // ─── Dialogs estilizados ─────────────────────────────────────────────────────
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
                  color: Colors.purple.withOpacity(0.15),
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
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(icon, color: Colors.purple[700], size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(title,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.purple[900])),
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
                        backgroundColor: Colors.purple[700],
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

  InputDecoration _inputDecoration(String hint, IconData prefixIcon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: Colors.purple[400], size: 20),
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
          BorderSide(color: Colors.purple[400]!, width: 1.5)),
    );
  }

  void _editNome() {
    final nomeController = TextEditingController(
        text: gasto['descricao']?.toString() ?? '');
    final formKey = GlobalKey<FormState>();
    _showEditDialog(
      title: 'Editar Nome',
      icon: Icons.label_outline_rounded,
      formKey: formKey,
      content: TextFormField(
        controller: nomeController,
        autofocus: true,
        style: const TextStyle(fontSize: 15),
        decoration:
        _inputDecoration('Nome do gasto', Icons.label_outline_rounded),
        validator: (v) =>
        (v == null || v.trim().isEmpty) ? 'Insira um nome' : null,
      ),
      onConfirm: () =>
          _patch({'descricao': nomeController.text.trim()}, 'Nome atualizado!'),
    );
  }

  void _editValor() {
    _valorController.clear();
    _showEditDialog(
      title: 'Editar Valor',
      icon: Icons.attach_money_rounded,
      formKey: _formValorKey,
      content: TextFormField(
        controller: _valorController,
        autofocus: true,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 15),
        decoration: _inputDecoration('R\$ 0,00', Icons.attach_money_rounded),
        onChanged: (v) {
          final formatted = _formatarValorInput(v);
          _valorController.value = TextEditingValue(
              text: formatted,
              selection:
              TextSelection.collapsed(offset: formatted.length));
        },
        validator: (v) {
          if (v == null || v.isEmpty) return 'Insira um valor';
          return null;
        },
      ),
      onConfirm: () =>
          _patch({'valor': _toNumeric(_valorController.text)}, 'Valor atualizado!'),
    );
  }

  void _editData() {
    _dataController.clear();
    _showEditDialog(
      title: 'Data de Pagamento',
      icon: Icons.calendar_today_rounded,
      formKey: _formDataKey,
      content: TextFormField(
        controller: _dataController,
        readOnly: true,
        style: const TextStyle(fontSize: 15),
        decoration:
        _inputDecoration('Selecione a data', Icons.calendar_today_rounded),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2101),
            builder: (context, child) => Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(primary: Colors.purple[700]!),
              ),
              child: child!,
            ),
          );
          if (picked != null) {
            _dataController.text = DateFormat('dd/MM/yyyy').format(picked);
          }
        },
        validator: (v) => (v == null || v.isEmpty) ? 'Selecione uma data' : null,
      ),
      onConfirm: () async {
        final parsed = DateFormat('dd/MM/yyyy').parse(_dataController.text);
        await _patch(
            {'data_pgto': parsed.toIso8601String()}, 'Data atualizada!');
      },
    );
  }

  void _editCategoria() {
    _categoriaIdSelecionada = null;
    _showEditDialog(
      title: 'Categoria',
      icon: Icons.category_rounded,
      formKey: _formCategoriaKey,
      content: StatefulBuilder(builder: (context, setLocal) {
        return _categorias.isEmpty
            ? Center(
            child: CircularProgressIndicator(color: Colors.purple[700]))
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
                borderSide: BorderSide(
                    color: Colors.purple[400]!, width: 1.5)),
          ),
          items: _categorias
              .map((c) => DropdownMenuItem<int>(
              value: c['id'],
              child: Text(c['nome'],
                  overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: (v) => setLocal(
                  () => _categoriaIdSelecionada = v),
          validator: (v) =>
          v == null ? 'Selecione uma categoria' : null,
        );
      }),
      onConfirm: () =>
          _patch({'categoria_id': _categoriaIdSelecionada}, 'Categoria atualizada!'),
    );
  }

  void _editObservacoes() {
    _obsController.text = gasto['observacoes'] ?? '';
    _showEditDialog(
      title: 'Observações',
      icon: Icons.notes_rounded,
      formKey: _formObsKey,
      content: TextFormField(
        controller: _obsController,
        autofocus: true,
        maxLines: 3,
        style: const TextStyle(fontSize: 15),
        decoration:
        _inputDecoration('Escreva uma observação…', Icons.notes_rounded),
        validator: (v) =>
        (v == null || v.isEmpty) ? 'Insira uma observação' : null,
      ),
      onConfirm: () =>
          _patch({'observacoes': _obsController.text}, 'Observação salva!'),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isAtivo = orcamento['data_encerramento'] == null;
    final descricao = gasto['descricao']?.toString() ?? 'Gasto Variado';
    final categoriaNome =
        gasto['categoriaGasto']?['nome']?.toString() ?? 'Sem categoria';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      body: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────────
          _GastoHeader(
            descricao: descricao,
            isAtivo: isAtivo,
            isRefreshing: _isRefreshing,
            refreshCtrl: _refreshCtrl,
            onRefresh: _handleRefresh,
            onBack: () => Navigator.of(context).pop(),
            onDelete: isAtivo
                ? () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Apagar Gasto',
              message:
              'Deseja realmente apagar este gasto variado?',
              actionText: 'Apagar',
              action: _delete,
            )
                : null,
          ),

          // ── Conteúdo ──────────────────────────────────────────────────────────
          Expanded(
            child: gasto.isEmpty || orcamento.isEmpty
                ? Center(
                child: OrcamentosLoading(message: 'Carregando...'))
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card de valor em destaque ───────────────────────
                  _ValorDestaque(
                    valor: gasto['valor'],
                    dataPgto: gasto['data_pgto'],
                    categoriaNome: categoriaNome,
                  ),
                  const SizedBox(height: 20),

                  // ── Seção de detalhes ───────────────────────────────
                  _sectionLabel('DETALHES'),
                  _InfoCard(children: [
                    _InfoRow(
                      icon: Icons.label_outline_rounded,
                      color: const Color(0xFF8E24AA),
                      label: 'Nome',
                      value: gasto['descricao']?.toString() ?? 'Sem nome',
                      isFirst: true,
                      onTap: isAtivo ? _editNome : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.attach_money_rounded,
                      color: const Color(0xFF7B1FA2),
                      label: 'Valor',
                      value: gasto['valor'] != null
                          ? formatarValorDynamic(gasto['valor'])
                          : 'Não informado',
                      onTap: isAtivo ? _editValor : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.calendar_today_rounded,
                      color: const Color(0xFF6A1B9A),
                      label: 'Data de pagamento',
                      value: _formatDate(gasto['data_pgto']),
                      onTap: isAtivo ? _editData : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.category_rounded,
                      color: const Color(0xFF4A148C),
                      label: 'Categoria',
                      value: categoriaNome,
                      onTap: isAtivo ? _editCategoria : null,
                    ),
                    _Divider(),
                    _InfoRow(
                      icon: Icons.notes_rounded,
                      color: const Color(0xFF039BE5),
                      label: 'Observações',
                      value: gasto['observacoes'] ?? 'Nenhuma observação',
                      isLast: true,
                      onTap: isAtivo ? _editObservacoes : null,
                    ),
                  ]),

                  // ── Dica de toque ────────────────────────────────────
                  if (isAtivo) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_rounded,
                            size: 13, color: Colors.grey[400]),
                        const SizedBox(width: 4),
                        Text('Toque em um campo para editar',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[400])),
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
// Header moderno roxo
// ═══════════════════════════════════════════════════════════════════════════════
class _GastoHeader extends StatelessWidget {
  final String descricao;
  final bool isAtivo;
  final bool isRefreshing;
  final AnimationController refreshCtrl;
  final VoidCallback onRefresh;
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  const _GastoHeader({
    required this.descricao,
    required this.isAtivo,
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
                child: const Icon(Icons.receipt_long_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      descricao,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text('Gasto variado',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Linha 2: status + lixo + refresh ─────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isAtivo
                          ? const Color(0xFF69F0AE)
                          : Colors.grey[400],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAtivo ? 'Orçamento ativo' : 'Orçamento encerrado',
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
// Destaque do valor
// ═══════════════════════════════════════════════════════════════════════════════
class _ValorDestaque extends StatelessWidget {
  final dynamic valor;
  final String? dataPgto;
  final String categoriaNome;

  const _ValorDestaque({
    required this.valor,
    required this.dataPgto,
    required this.categoriaNome,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final valorDouble = double.tryParse(valor?.toString() ?? '0') ?? 0.0;
    final dataStr = dataPgto != null
        ? DateFormat("d 'de' MMMM 'de' yyyy", 'pt_BR')
        .format(DateTime.parse(dataPgto!))
        : 'Sem data';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple[700]!,
            Colors.purple[500]!,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.purple[700]!.withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Valor pago',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 6),
          Text(
            fmt.format(valorDouble),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20)),
            child: Text(categoriaNome,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 12, height: 12,),
          Text(dataStr,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card de info com linhas
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
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
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
                    Text(value,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36))),
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
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(height: 1, color: Colors.grey[100]),
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
            border: Border.all(
                color: Colors.white.withOpacity(0.2), width: 1),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
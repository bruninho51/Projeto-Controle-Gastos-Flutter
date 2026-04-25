import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';
import 'package:orcamentos_app/components/common/status_badge.dart';

class CriacaoGastoVariadoPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const CriacaoGastoVariadoPage({
    super.key,
    required this.orcamentoId,
    required this.apiToken,
  });

  @override
  State<CriacaoGastoVariadoPage> createState() => _CriacaoGastoVariadoPageState();
}

class _CriacaoGastoVariadoPageState extends State<CriacaoGastoVariadoPage> {
  final _formKey               = GlobalKey<FormState>();
  final _descricaoController   = TextEditingController();
  final _valorController       = TextEditingController();
  final _dataController        = TextEditingController();
  final _observacoesController = TextEditingController();
  final _descricaoFocus        = FocusNode();
  final _valorFocus            = FocusNode();
  final _observacoesFocus      = FocusNode();

  int? _categoriaIdSelecionada;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading           = false;
  bool _isLoadingCategories = false;

  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _light  = Color(0xFF3949AB);
  static const _accent = Color(0xFF7986CB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  final _formatador  = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat  = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _obterCategoriasGastos();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorController.dispose();
    _dataController.dispose();
    _observacoesController.dispose();
    _descricaoFocus.dispose();
    _valorFocus.dispose();
    _observacoesFocus.dispose();
    super.dispose();
  }

  String _formatarValor(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isNotEmpty) {
      final parsed = (double.tryParse(cleaned) ?? 0) / 100;
      return _formatador.format(parsed);
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

  Future<void> _obterCategoriasGastos() async {
    setState(() => _isLoadingCategories = true);
    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'categorias-gastos',
        headers: {'Authorization': 'Bearer ${widget.apiToken}'},
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _categorias = data.map((c) => {'id': c['id'], 'nome': c['nome']}).toList();
        });
      } else {
        throw Exception('Falha ao carregar categorias');
      }
    } catch (e) {
      OrcamentosSnackBar.error(context: context, message: 'Erro ao carregar categorias: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _salvarGastoVariado() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      final valor      = _converterParaFormatoNumerico(_valorController.text);
      final parsedDate = _dateFormat.parse(_dataController.text);
      final client     = await MyHttpClient.create();
      final response   = await client.post(
        'orcamentos/${widget.orcamentoId}/gastos-variados',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'descricao':    _descricaoController.text,
          'valor':        valor,
          'data_pgto':    parsedDate.toIso8601String(),
          'categoria_id': _categoriaIdSelecionada,
          'observacoes':  _observacoesController.text,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(context: context, message: 'Gasto variado criado com sucesso!');
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao criar gasto variado: ${response.statusCode}');
      }
    } catch (e) {
      OrcamentosSnackBar.error(context: context, message: 'Erro: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              _buildCard(children: [
                _buildField(
                  controller: _descricaoController,
                  focusNode: _descricaoFocus,
                  nextFocus: _valorFocus,
                  label: 'Descrição',
                  icon: Icons.description_outlined,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.isEmpty) ? 'Insira uma descrição' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _valorController,
                  focusNode: _valorFocus,
                  nextFocus: _observacoesFocus,
                  label: 'Valor',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  action: TextInputAction.next,
                  onChanged: (v) {
                    final formatted = _formatarValor(v);
                    _valorController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Insira o valor';
                    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (double.tryParse(cleaned) == null || cleaned.length < 2) {
                      return 'Insira um valor válido';
                    }
                    return null;
                  },
                ),
              ]),
              const SizedBox(height: 16),
              _buildCard(children: [
                _buildCategoriaField(),
                const SizedBox(height: 16),
                _buildDataField(),
              ]),
              const SizedBox(height: 16),
              _buildCard(children: [
                _buildField(
                  controller: _observacoesController,
                  focusNode: _observacoesFocus,
                  label: 'Observações (opcional)',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                  action: TextInputAction.done,
                ),
              ]),
              const SizedBox(height: 32),
              _buildSaveButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return SharedAppBar(
      title: 'Novo Gasto Variado',
      subtitle: 'Preencha as informações abaixo',
      mainIcon: Icons.shopping_bag_outlined,
      gradientColors: _gradientColors,
      bottomContent: StatusBadge(
        leading: const Icon(Icons.receipt_long_outlined, size: 12, color: Colors.white),
        text: 'Orçamento #${widget.orcamentoId}',
      ),
    );
  }

  // ── Card agrupador ────────────────────────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _dark.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  // ── Campo genérico ────────────────────────────────────

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    FocusNode? focusNode,
    FocusNode? nextFocus,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    int maxLines = 1,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textInputAction: action,
      maxLines: maxLines,
      onChanged: onChanged,
      onFieldSubmitted: (_) {
        if (nextFocus != null) FocusScope.of(context).requestFocus(nextFocus);
      },
      validator: validator,
      style: const TextStyle(fontSize: 15, color: _dark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: _accent, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _light, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Categoria ─────────────────────────────────────────

  Widget _buildCategoriaField() {
    if (_isLoadingCategories) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return DropdownButtonFormField<int>(
      value: _categoriaIdSelecionada,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
      style: const TextStyle(fontSize: 15, color: _dark),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: 'Categoria',
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: const Icon(Icons.category_outlined, color: _accent, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _light, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      items: _categorias.map((c) {
        return DropdownMenuItem<int>(
          value: c['id'],
          child: Text(c['nome'], overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (v) => setState(() => _categoriaIdSelecionada = v),
      validator: (v) => v == null ? 'Selecione uma categoria' : null,
    );
  }

  // ── Data de Pagamento ─────────────────────────────────

  Widget _buildDataField() {
    return TextFormField(
      controller: _dataController,
      readOnly: true,
      style: const TextStyle(fontSize: 15, color: _dark),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2101),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: _mid,
                onPrimary: Colors.white,
                surface: Colors.white,
                onSurface: _dark,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() => _dataController.text = _dateFormat.format(picked));
        }
      },
      validator: (v) => (v == null || v.isEmpty) ? 'Selecione uma data' : null,
      decoration: InputDecoration(
        labelText: 'Data de Pagamento',
        labelStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: const Icon(Icons.calendar_today_outlined, color: _accent, size: 20),
        suffixIcon: _dataController.text.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, color: _accent, size: 18),
          onPressed: () => setState(() => _dataController.clear()),
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF8F9FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _light, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Botão salvar ──────────────────────────────────────

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _salvarGastoVariado,
      style: ElevatedButton.styleFrom(
        backgroundColor: _mid,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _accent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      )
          : const Text(
        'Salvar gasto variado',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}
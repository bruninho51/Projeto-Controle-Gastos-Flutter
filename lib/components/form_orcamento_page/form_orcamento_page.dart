import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/common/shared_appbar.dart';

class FormularioOrcamentoPage extends StatefulWidget {
  final String apiToken;

  const FormularioOrcamentoPage({super.key, required this.apiToken});

  @override
  State<FormularioOrcamentoPage> createState() => _FormularioOrcamentoPageState();
}

class _FormularioOrcamentoPageState extends State<FormularioOrcamentoPage> {
  final _formKey              = GlobalKey<FormState>();
  final _nomeController       = TextEditingController();
  final _valorInicialController = TextEditingController();
  final _nomeFocus            = FocusNode();
  final _valorFocus           = FocusNode();

  bool _isLoading = false;

  static const _dark   = Color(0xFF1A237E);
  static const _mid    = Color(0xFF283593);
  static const _light  = Color(0xFF3949AB);
  static const _accent = Color(0xFF7986CB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void dispose() {
    _nomeController.dispose();
    _valorInicialController.dispose();
    _nomeFocus.dispose();
    _valorFocus.dispose();
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

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final client   = await MyHttpClient.create();
      final response = await client.post(
        'orcamentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'nome':          _nomeController.text,
          'valor_inicial': _converterParaFormatoNumerico(_valorInicialController.text),
        }),
      );
      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(context: context, message: 'Orçamento salvo com sucesso!');
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao salvar: ${response.statusCode}');
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
      appBar: SharedAppBar(
        title: 'Novo Orçamento',
        subtitle: 'Preencha as informações abaixo',
        mainIcon: Icons.account_balance_wallet_outlined,
        gradientColors: _gradientColors,
      ),
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
                  controller: _nomeController,
                  focusNode: _nomeFocus,
                  nextFocus: _valorFocus,
                  label: 'Nome do orçamento',
                  icon: Icons.description_outlined,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.isEmpty) ? 'Insira o nome do orçamento' : null,
                ),
                const SizedBox(height: 16),
                _buildField(
                  controller: _valorInicialController,
                  focusNode: _valorFocus,
                  label: 'Valor inicial',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  action: TextInputAction.done,
                  onChanged: (v) {
                    final formatted = _formatarValor(v);
                    _valorInicialController.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Insira o valor inicial';
                    final cleaned = v.replaceAll(RegExp(r'[^0-9]'), '');
                    if (double.tryParse(cleaned) == null || cleaned.length < 2) {
                      return 'Insira um valor válido';
                    }
                    return null;
                  },
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

  // ── Botão salvar ──────────────────────────────────────

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _saveForm,
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
        'Salvar orçamento',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    );
  }
}
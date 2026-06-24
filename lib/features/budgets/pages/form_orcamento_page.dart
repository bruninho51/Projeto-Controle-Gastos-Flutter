import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/utils/formatters.dart';

import '../components/orcamento_form_field.dart';

class FormularioOrcamentoPage extends StatefulWidget {
  const FormularioOrcamentoPage({super.key});

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
  static const _accent = Color(0xFF7986CB);

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  @override
  void dispose() {
    _nomeController.dispose();
    _valorInicialController.dispose();
    _nomeFocus.dispose();
    _valorFocus.dispose();
    super.dispose();
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await _api.createOrcamento(
        OrcamentoCreateDto(
          nome: _nomeController.text,
          valorInicial: converterValorParaNumerico(_valorInicialController.text),
        ),
      );

      if (!mounted) return;
      OrcamentosSnackBar.success(context: context, message: 'Orçamento salvo com sucesso!');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) OrcamentosSnackBar.error(context: context, message: 'Erro: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                OrcamentoFormField(
                  controller: _nomeController,
                  focusNode: _nomeFocus,
                  nextFocus: _valorFocus,
                  label: 'Nome do orçamento',
                  icon: Icons.description_outlined,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.isEmpty) ? 'Insira o nome do orçamento' : null,
                ),
                const SizedBox(height: 16),
                OrcamentoFormField(
                  controller: _valorInicialController,
                  focusNode: _valorFocus,
                  label: 'Valor inicial',
                  icon: Icons.attach_money_outlined,
                  keyboardType: TextInputType.number,
                  action: TextInputAction.done,
                  onChanged: (v) {
                    final formatted = formatarValorInput(v);
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
            color: _dark.withValues(alpha: 0.06),
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

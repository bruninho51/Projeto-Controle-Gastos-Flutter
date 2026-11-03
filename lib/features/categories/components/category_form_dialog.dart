import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/features/categories/components/category_tipo_style.dart';

/// Abre o formulário de categoria. Sem [categoria] cria uma nova; com
/// [categoria] edita a existente, já preenchida.
Future<void> showCategoryFormDialog({
  required BuildContext context,
  CategoriaGastoResponseDto? categoria,
  required Future<void> Function(String nome, TipoCategoriaGasto tipo)
      onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) =>
        _CategoryFormDialog(categoria: categoria, onConfirm: onConfirm),
  );
}

class _CategoryFormDialog extends StatefulWidget {
  final CategoriaGastoResponseDto? categoria;
  final Future<void> Function(String nome, TipoCategoriaGasto tipo) onConfirm;

  const _CategoryFormDialog({required this.categoria, required this.onConfirm});

  @override
  State<_CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<_CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late TipoCategoriaGasto _tipo;
  bool _isLoading = false;

  bool get _isEdicao => widget.categoria != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.categoria?.nome ?? '');
    _tipo = widget.categoria?.tipo ?? TipoCategoriaGasto.despesa;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isLoading = true);
    try {
      await widget.onConfirm(_controller.text.trim(), _tipo);
    } catch (_) {
      // O chamador já informa o erro ao usuário; aqui só destravamos o botão.
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // SingleChildScrollView com reverse:true ancora o conteúdo na base.
    // Quando o teclado sobe, o scroll absorve o deslocamento naturalmente,
    // sem nenhum cálculo manual de viewInsets e sem overflow.
    return SingleChildScrollView(
      reverse: true,
      child: Padding(
        // Padding manual garante espaço entre o dialog e as bordas da tela
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          // Zeramos o insetPadding pois o Padding externo já cuida disso
          insetPadding: EdgeInsets.zero,
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
                // ── Header ────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                          _isEdicao
                              ? Icons.edit_outlined
                              : Icons.add_circle_outline,
                          color: Colors.indigo[700],
                          size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isEdicao ? 'Editar Categoria' : 'Nova Categoria',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.indigo[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Campo de texto ─────────────────────────────────────
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _controller,
                    autofocus: true,
                    enabled: !_isLoading,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'Ex: Alimentação, Transporte…',
                      hintStyle:
                          TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.label_outline,
                          color: Colors.indigo[400], size: 20),
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
                              color: Colors.indigo[400]!, width: 1.5)),
                      errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Colors.redAccent, width: 1)),
                      disabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'O nome não pode ser vazio!';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // ── Tipo ───────────────────────────────────────────────
                Text(
                  'Tipo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TipoCategoriaGasto>(
                    showSelectedIcon: false,
                    segments: [
                      for (final tipo in TipoCategoriaGasto.values)
                        ButtonSegment(
                          value: tipo,
                          label: Text(tipo.label),
                          icon: Icon(tipo.icon, size: 18),
                        ),
                    ],
                    selected: {_tipo},
                    onSelectionChanged: _isLoading
                        ? null
                        : (selecao) => setState(() => _tipo = selecao.first),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _tipo.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),

                // ── Botões ─────────────────────────────────────────────
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
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600),
                        ),
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
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Salvar',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

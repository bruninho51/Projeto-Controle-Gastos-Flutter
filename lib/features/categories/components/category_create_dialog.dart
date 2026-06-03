import 'package:flutter/material.dart';

Future<void> showCategoryCreateDialog({
  required BuildContext context,
  required Future<void> Function(String nome) onConfirm,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _CategoryCreateDialog(onConfirm: onConfirm),
  );
}

class _CategoryCreateDialog extends StatefulWidget {
  final Future<void> Function(String nome) onConfirm;

  const _CategoryCreateDialog({required this.onConfirm});

  @override
  State<_CategoryCreateDialog> createState() => _CategoryCreateDialogState();
}

class _CategoryCreateDialogState extends State<_CategoryCreateDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
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
      await widget.onConfirm(_controller.text.trim());
    } catch (_) {
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
                      child: Icon(Icons.add_circle_outline,
                          color: Colors.indigo[700], size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Nova Categoria',
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
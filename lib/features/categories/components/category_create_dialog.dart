import 'package:flutter/material.dart';

Future<void> showCategoryCreateDialog({
  required BuildContext context,
  required Future<void> Function(String nome) onConfirm,
}) async {
  final formKey = GlobalKey<FormState>();
  final controller = TextEditingController();

  await showDialog<void>(
    context: context,
    builder: (_) => _CategoryCreateDialog(
      formKey: formKey,
      controller: controller,
      onConfirm: onConfirm,
    ),
  );

  controller.dispose();
}

class _CategoryCreateDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final Future<void> Function(String nome) onConfirm;

  const _CategoryCreateDialog({
    required this.formKey,
    required this.controller,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                color: Colors.indigo.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.add_circle_outline,
                      color: Colors.indigo[700], size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Nova Categoria',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.indigo[900]),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: TextFormField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Ex: Alimentação, Transporte…',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon:
                      Icon(Icons.label_outline, color: Colors.indigo[400], size: 20),
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
                          BorderSide(color: Colors.indigo[400]!, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.redAccent, width: 1)),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'O nome não pode ser vazio!';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
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
                      backgroundColor: Colors.indigo[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      if (formKey.currentState?.validate() ?? false) {
                        onConfirm(controller.text);
                      }
                    },
                    child: const Text('Salvar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/refatorado/orcamentos_snackbar.dart';

class FormularioOrcamentoPage extends StatefulWidget {
  final String apiToken;

  const FormularioOrcamentoPage({Key? key, required this.apiToken}) : super(key: key);

  @override
  _FormularioOrcamentoPageState createState() => _FormularioOrcamentoPageState();
}

class _FormularioOrcamentoPageState extends State<FormularioOrcamentoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _valorInicialController = TextEditingController();
  final _focusNode = FocusNode();
  bool _isLoading = false;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void dispose() {
    _nomeController.dispose();
    _valorInicialController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _formatarValor(String value) {
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100;
      return _formatador.format(parsedValue);
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
      final client = await MyHttpClient.create();
      final response = await client.post(
        'orcamentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'nome': _nomeController.text,
          'valor_inicial': _converterParaFormatoNumerico(_valorInicialController.text),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Orçamento salvo com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao salvar: ${response.statusCode}');
      }
    } catch (e) {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro: ${e.toString()}',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[400]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.indigo, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'Novo Orçamento',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.indigo[700],
          iconTheme: const IconThemeData(color: Colors.white),
          toolbarTextStyle: const TextStyle(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  'Preencha os dados do novo orçamento',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _nomeController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Orçamento',
                    prefixIcon: Icon(Icons.description),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_focusNode),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o nome do orçamento';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Valor Inicial',
                    prefixIcon: Icon(Icons.attach_money),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  controller: _valorInicialController,
                  focusNode: _focusNode,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o valor inicial';
                    }
                    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (double.tryParse(cleanedValue) == null || cleanedValue.length < 2) {
                      return 'Por favor, insira um valor válido';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    String formattedValue = _formatarValor(value);
                    _valorInicialController.value = TextEditingValue(
                      text: formattedValue,
                      selection: TextSelection.collapsed(offset: formattedValue.length),
                    );
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'SALVAR ORÇAMENTO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/refatorado/orcamentos_snackbar.dart';

class CriacaoGastoVariadoPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const CriacaoGastoVariadoPage({
    Key? key,
    required this.orcamentoId,
    required this.apiToken,
  }) : super(key: key);

  @override
  _CriacaoGastoVariadoPageState createState() => _CriacaoGastoVariadoPageState();
}

class _CriacaoGastoVariadoPageState extends State<CriacaoGastoVariadoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorController = TextEditingController();
  final _dataController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _descricaoFocusNode = FocusNode();
  final _valorFocusNode = FocusNode();
  final _dataFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();

  int? _categoriaIdSelecionada;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  bool _isLoadingCategories = false;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final _dateFormat = DateFormat('dd/MM/yyyy');

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
    _descricaoFocusNode.dispose();
    _valorFocusNode.dispose();
    _dataFocusNode.dispose();
    _observacoesFocusNode.dispose();
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

  Future<void> _obterCategoriasGastos() async {
    setState(() => _isLoadingCategories = true);
    
    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'categorias-gastos',
        headers: {
          'Authorization': 'Bearer ${widget.apiToken}',
        },
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        final List<dynamic> categoriasJson = jsonDecode(response.body);

        setState(() {
          _categorias = categoriasJson.map((categoria) {
            return {
              'id': categoria['id'],
              'nome': categoria['nome'],
            };
          }).toList();
          _isLoadingCategories = false;
        });
      } else {
        throw Exception('Falha ao carregar categorias de gastos');
      }
    } catch (e) {
      setState(() => _isLoadingCategories = false);
      OrcamentosSnackBar.error(
        context: context,
        message: 'Erro ao carregar categorias: ${e.toString()}',
      );
    }
  }

  Future<void> _salvarGastoVariado() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    
    try {
      final valor = _converterParaFormatoNumerico(_valorController.text);
      final parsedDate = _dateFormat.parse(_dataController.text);

      final client = await MyHttpClient.create();
      final response = await client.post(
        'orcamentos/${widget.orcamentoId}/gastos-variados',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'descricao': _descricaoController.text,
          'valor': valor,
          'data_pgto': parsedDate.toIso8601String(),
          'categoria_id': _categoriaIdSelecionada,
          'observacoes': _observacoesController.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Gasto variado criado com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao criar gasto variado: ${response.statusCode}');
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
            'Novo Gasto Variado',
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
                  'Preencha os dados do novo gasto variado',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                
                // Campo Descrição
                TextFormField(
                  controller: _descricaoController,
                  focusNode: _descricaoFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Descrição',
                    prefixIcon: Icon(Icons.description),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_valorFocusNode),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma descrição';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Valor
                TextFormField(
                  controller: _valorController,
                  focusNode: _valorFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    prefixIcon: Icon(Icons.attach_money),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_dataFocusNode),
                  onChanged: (value) {
                    String formattedValue = _formatarValor(value);
                    _valorController.value = TextEditingValue(
                      text: formattedValue,
                      selection: TextSelection.collapsed(offset: formattedValue.length),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o valor';
                    }
                    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (double.tryParse(cleanedValue) == null || cleanedValue.length < 2) {
                      return 'Por favor, insira um valor válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Data
                TextFormField(
                  controller: _dataController,
                  focusNode: _dataFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Data de Pagamento',
                    prefixIcon: Icon(Icons.calendar_today),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  readOnly: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_observacoesFocusNode),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, selecione uma data';
                    }
                    return null;
                  },
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Colors.indigo,
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Colors.black,
                            ),
                            dialogBackgroundColor: Colors.white,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (pickedDate != null) {
                      setState(() {
                        _dataController.text = _dateFormat.format(pickedDate);
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),
                
                // Campo Categoria
                _isLoadingCategories
                    ? const Center(child: CircularProgressIndicator())
                    : DropdownButtonFormField<int>(
                        value: _categoriaIdSelecionada,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category),
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                        ),
                        items: _categorias.map((categoria) {
                          return DropdownMenuItem<int>(
                            value: categoria['id'],
                            child: Text(
                              categoria['nome'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _categoriaIdSelecionada = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Por favor, selecione uma categoria';
                          }
                          return null;
                        },
                      ),
                const SizedBox(height: 20),
                
                // Campo Observações
                TextFormField(
                  controller: _observacoesController,
                  focusNode: _observacoesFocusNode,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações (Opcional)',
                    prefixIcon: Icon(Icons.note),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 40),
                
                // Botão de Salvar
                ElevatedButton(
                  onPressed: _isLoading ? null : _salvarGastoVariado,
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
                          'SALVAR GASTO VARIADO',
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
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';

class CriacaoGastoFixoPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const CriacaoGastoFixoPage({
    Key? key,
    required this.orcamentoId,
    required this.apiToken,
  }) : super(key: key);

  @override
  _CriacaoGastoFixoPageState createState() => _CriacaoGastoFixoPageState();
}

class _CriacaoGastoFixoPageState extends State<CriacaoGastoFixoPage> {
  final _formKey = GlobalKey<FormState>();
  final _descricaoController = TextEditingController();
  final _valorPrevistoController = TextEditingController();
  final _observacoesController = TextEditingController();
  final _descricaoFocusNode = FocusNode();
  final _valorFocusNode = FocusNode();
  final _observacoesFocusNode = FocusNode();
  final _dataVencimentoController = TextEditingController();

  int? _categoriaIdSelecionada;
  List<Map<String, dynamic>> _categorias = [];
  bool _isLoading = false;
  bool _isLoadingCategories = false;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _obterCategoriasGastos();
  }

  @override
  void dispose() {
    _descricaoController.dispose();
    _valorPrevistoController.dispose();
    _observacoesController.dispose();
    _descricaoFocusNode.dispose();
    _valorFocusNode.dispose();
    _observacoesFocusNode.dispose();
    _dataVencimentoController.dispose();
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

  Future<void> _salvarGastoFixo() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    
    try {
      final valorPrevisto = _converterParaFormatoNumerico(_valorPrevistoController.text);

      final client = await MyHttpClient.create();
      final response = await client.post(
        'orcamentos/${widget.orcamentoId}/gastos-fixos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'descricao': _descricaoController.text,
          'previsto': valorPrevisto,
          'categoria_id': _categoriaIdSelecionada,
          'observacoes': _observacoesController.text,
          'data_venc': _dataVencimentoController.text.isNotEmpty
              ? DateFormat('dd/MM/yyyy').parse(_dataVencimentoController.text).toIso8601String()
              : null,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Gasto fixo criado com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao criar gasto fixo: ${response.statusCode}');
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
            'Novo Gasto Fixo',
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
                  'Preencha os dados do novo gasto fixo',
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
                
                // Campo Valor Previsto
                TextFormField(
                  controller: _valorPrevistoController,
                  focusNode: _valorFocusNode,
                  decoration: const InputDecoration(
                    labelText: 'Valor Previsto',
                    prefixIcon: Icon(Icons.attach_money),
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                  ),
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => FocusScope.of(context).requestFocus(_observacoesFocusNode),
                  onChanged: (value) {
                    String formattedValue = _formatarValor(value);
                    _valorPrevistoController.value = TextEditingValue(
                      text: formattedValue,
                      selection: TextSelection.collapsed(offset: formattedValue.length),
                    );
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o valor previsto';
                    }
                    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                    if (double.tryParse(cleanedValue) == null || cleanedValue.length < 2) {
                      return 'Por favor, insira um valor válido';
                    }
                    return null;
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
                          border: OutlineInputBorder(),
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
                const SizedBox(height: 20),

                TextFormField(
                  controller: _dataVencimentoController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Vencimento (Opcional)',
                    border: OutlineInputBorder(),
                  ),
                  readOnly: true,
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      _dataVencimentoController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                    }
                  },
                ),
                const SizedBox(height: 40),
                
                // Botão de Salvar
                ElevatedButton(
                  onPressed: _isLoading ? null : _salvarGastoFixo,
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
                          'SALVAR GASTO FIXO',
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
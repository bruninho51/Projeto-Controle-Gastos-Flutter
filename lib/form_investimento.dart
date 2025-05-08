import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/refatorado/orcamentos_snackbar.dart';

class FormularioInvestimentoPage extends StatefulWidget {
  final String apiToken;

  const FormularioInvestimentoPage({Key? key, required this.apiToken}) : super(key: key);

  @override
  _FormularioInvestimentoPageState createState() => _FormularioInvestimentoPageState();
}

class _FormularioInvestimentoPageState extends State<FormularioInvestimentoPage> {
  final _formKey = GlobalKey<FormState>();
  String _nome = '';
  String _descricao = '';
  final _valorInicialController = TextEditingController();

  int? _categoriaIdSelecionada;
  String? _categoriaSelecionada;
  List<Map<String, dynamic>> _categorias = [];

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  Future<void> _obterCategoriasGastos() async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'categorias-investimentos',
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
      });
    } else {
      throw Exception('Falha ao carregar categorias de investimentos');
    }
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

  String converterParaFormatoNumerico(String valorFormatado) {
    String valorSemSimbolo = valorFormatado.replaceAll('R\$', '').trim();

    String valorComPonto = valorSemSimbolo.replaceAll('.', '').replaceAll(',', '.');

    return valorComPonto;
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      final client = await MyHttpClient.create();
      final response = await client.post(
        'investimentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'nome': _nome,
          'descricao': _descricao,
          'valor_inicial': converterParaFormatoNumerico(_valorInicialController.text),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Orçamento salvo com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
        print(response.body.toString());
        OrcamentosSnackBar.error(
          context: context,
          message: 'Falha ao salvar o orçamento.',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Formulário de Orçamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do Investimento',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do investimento';
                  }
                  return null;
                },
                onSaved: (value) {
                  _nome = value ?? '';
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                ),
                onSaved: (value) {
                  _descricao = value ?? '';
                },
              ),
              const SizedBox(height: 16),

              _categorias.isEmpty
                  ? const CircularProgressIndicator()
                  : DropdownButtonFormField<int>(
                      value: _categoriaIdSelecionada,
                      isExpanded: true,
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria['id'],
                          child: Text(
                            categoria['nome'],
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _categoriaIdSelecionada = value;
                          _categoriaSelecionada = _categorias.firstWhere(
                            (categoria) => categoria['id'] == value,
                          )['nome'];
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                      ),
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecione uma categoria';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),
              
              TextFormField(
              decoration: const InputDecoration(
                labelText: 'Valor Inicial',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              controller: _valorInicialController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, insira o valor inicial';
                }
                String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (double.tryParse(cleanedValue) == null) {
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
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveForm,
                child: const Text('Salvar Investimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

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

  int? _categoriaIdSelecionada;  // Para armazenar o ID da categoria
  String? _categoriaSelecionada;
  List<Map<String, dynamic>> _categorias = []; // Lista de categorias (id e nome)

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Método para obter as categorias de gasto da API
  Future<void> _obterCategoriasGastos() async {
    final url = 'http://192.168.73.103:3000/api/v1/categorias-investimentos'; // URL da sua API
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      // Parseia o corpo da resposta para um formato JSON
      final List<dynamic> categoriasJson = jsonDecode(response.body);

      // Converte para uma lista de Map<String, dynamic> (contendo id e nome)
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
    // Remove todos os caracteres não numéricos, exceto o ponto
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    // Converte para double e formata
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100; // Converte centavos para reais
      return _formatador.format(parsedValue);
    }
    return '';
  }

  String converterParaFormatoNumerico(String valorFormatado) {
    // Remove o símbolo da moeda (R$) e espaços em branco
    String valorSemSimbolo = valorFormatado.replaceAll('R\$', '').trim();

    // Substitui a vírgula (separador decimal) por ponto
    String valorComPonto = valorSemSimbolo.replaceAll('.', '').replaceAll(',', '.');

    return valorComPonto;
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final url = 'http://192.168.73.103:3000/api/v1/investimentos';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',  // Certifique-se de que o apiToken não é nulo
        },
        body: jsonEncode({
          'nome': _nome,
          'descricao': _descricao,
          'valor_inicial': converterParaFormatoNumerico(_valorInicialController.text),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Se o orçamento for salvo com sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento salvo com sucesso!')),
        );
        Navigator.pop(context, true); // Retorna à tela anterior
      } else {
        Navigator.pop(context, false);
        print(response.body.toString());
        // Se a requisição falhar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao salvar o orçamento')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulário de Orçamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Campo Nome
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

              // Campo Descrição
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

              // Categoria (Dropdown)
              _categorias.isEmpty
                  ? const CircularProgressIndicator() // Exibe um carregando enquanto as categorias são carregadas
                  : DropdownButtonFormField<int>(
                      value: _categoriaIdSelecionada,
                      isExpanded: true,  // Garante que o campo do dropdown ocupe toda a largura disponível
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria['id'],
                          child: Text(
                            categoria['nome'],
                            overflow: TextOverflow.ellipsis,  // Caso o nome da categoria seja muito longo, ele será truncado
                            softWrap: true,  // Permite que o texto quebre em várias linhas, se necessário
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
              
              // Campo Valor Inicial
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
                // Remove a formatação para validar o número
                String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (double.tryParse(cleanedValue) == null) {
                  return 'Por favor, insira um valor válido';
                }
                return null;
              },
              onChanged: (value) {
                // Formata o valor enquanto o usuário digita
                String formattedValue = _formatarValor(value);
                _valorInicialController.value = TextEditingValue(
                  text: formattedValue,
                  selection: TextSelection.collapsed(offset: formattedValue.length),
                );
              },
            ),
              const SizedBox(height: 20),

              // Botão de Salvar
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

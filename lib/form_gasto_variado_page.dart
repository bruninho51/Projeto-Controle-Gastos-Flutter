import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';

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
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorController = TextEditingController();
  TextEditingController _dataController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

  String? _categoriaSelecionada;
  int? _categoriaIdSelecionada;  // Para armazenar o ID da categoria
  List<Map<String, dynamic>> _categorias = []; // Lista de categorias (id e nome)

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Formata o valor inserido pelo usuário
  String _formatarValor(String value) {
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), ''); // Remove caracteres não numéricos
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100; // Converte centavos para reais
      return _formatador.format(parsedValue);
    }
    return '';
  }

  // Converte o valor formatado para o formato numérico
  String converterParaFormatoNumerico(String valorFormatado) {
    String valorSemSimbolo = valorFormatado.replaceAll('R\$', '').trim();
    String valorComPonto = valorSemSimbolo.replaceAll('.', '').replaceAll(',', '.');
    return valorComPonto;
  }

  // Método para obter as categorias de gasto da API
  Future<void> _obterCategoriasGastos() async {
    final client = await MyHttpClient.create();
    
    final response = await client.get(
      'categorias-gastos',
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
      throw Exception('Falha ao carregar categorias de gastos');
    }
  }

  // Método para salvar o gasto variado
  Future<void> _salvarGastoVariado() async {
    if (_formKey.currentState?.validate() ?? false) {
      final valor = converterParaFormatoNumerico(_valorController.text);

      DateFormat inputFormat = DateFormat('dd/MM/yyyy');
      DateTime parsedDate = inputFormat.parse(_dataController.text);

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
          'categoria_id': _categoriaIdSelecionada,  // Usando o id da categoria selecionada
          'observacoes': _observacoesController.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Se o gasto variado for salvo com sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto variado criado com sucesso!')),
        );
        Navigator.pop(context, true); // Volta para a tela anterior
      } else {
        // Se a requisição falhar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao criar o gasto variado')),
        );
        print(response.body.toString());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _obterCategoriasGastos(); // Carrega as categorias assim que a tela é aberta
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: Text('Criar Gasto Variado'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Descrição
              TextFormField(
                controller: _descricaoController,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira uma descrição';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Valor
              TextFormField(
                controller: _valorController,
                decoration: const InputDecoration(
                  labelText: 'Valor',
                ),
                keyboardType: TextInputType.number,
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
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                  controller: _dataController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Pagamento',
                  ),
                  readOnly: true,
                  validator: (value) {
                    print('valor data: $value');
                    if (value != null && value.isEmpty) {
                      return 'Por favor, selecione uma data';
                    }
                    return null;
                  },
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      _dataController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
                    }
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

              // Observações (opcional)
              TextFormField(
                controller: _observacoesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Observações (Opcional)',
                ),
              ),
              const SizedBox(height: 32),

              // Botão de envio
              ElevatedButton(
                onPressed: _salvarGastoVariado,
                child: const Text('Criar Gasto Variado'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

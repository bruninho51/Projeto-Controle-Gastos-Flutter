import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
  final TextEditingController _descricaoController = TextEditingController();
  final TextEditingController _valorPrevistoController = TextEditingController();
  final TextEditingController _observacoesController = TextEditingController();

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
    final url = 'http://192.168.73.103:3000/api/v1/categorias-gastos'; // URL da sua API
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
      throw Exception('Falha ao carregar categorias de gastos');
    }
  }

  // Método para salvar o gasto fixo
  Future<void> _salvarGastoFixo() async {
    if (_formKey.currentState?.validate() ?? false) {
      final valorPrevisto = converterParaFormatoNumerico(_valorPrevistoController.text);

      final url = 'http://192.168.73.103:3000/api/v1/orcamentos/${widget.orcamentoId}/gastos-fixos';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({
          'descricao': _descricaoController.text,
          'previsto': valorPrevisto,
          'categoria_id': _categoriaIdSelecionada,  // Usando o id da categoria selecionada
          'observacoes': _observacoesController.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        // Se o gasto fixo for salvo com sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gasto fixo criado com sucesso!')),
        );
        Navigator.pop(context, true); // Volta para a tela anterior
      } else {
        // Se a requisição falhar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao criar o gasto fixo')),
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
      appBar: AppBar(
        title: Text('Criar Gasto Fixo'),
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

              // Valor Previsto
              TextFormField(
                controller: _valorPrevistoController,
                decoration: const InputDecoration(
                  labelText: 'Valor Previsto',
                ),
                keyboardType: TextInputType.number,
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
                  return null;
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
                onPressed: _salvarGastoFixo,
                child: const Text('Criar Gasto Fixo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

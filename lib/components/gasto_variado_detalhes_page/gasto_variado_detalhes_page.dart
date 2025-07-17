import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';

class DetalhesGastoVariadoPage extends StatefulWidget {
  final int gastoId;
  final int orcamentoId;
  final String apiToken;

  const DetalhesGastoVariadoPage({
    super.key,
    required this.orcamentoId,
    required this.gastoId,
    required this.apiToken,
  });

  @override
  _DetalhesGastoVariadoPageState createState() => _DetalhesGastoVariadoPageState();
}

class _DetalhesGastoVariadoPageState extends State<DetalhesGastoVariadoPage> {
  Map<String, dynamic> gasto = {}; // Inicializa com um mapa vazio
  Map<String, dynamic> orcamento = {}; 
  bool isLoading = true; // Controla o estado de carregamento

  final TextEditingController _valorController = TextEditingController();
  final TextEditingController _dataController = TextEditingController();

  int? _categoriaIdSelecionada;  // Para armazenar o ID da categoria
  List<Map<String, dynamic>> _categorias = []; // Lista de categorias (id e nome)

  final _updateValorFormKey = GlobalKey<FormState>();
  final _updateCategoriaFormKey = GlobalKey<FormState>();
  final _updateDataPagamentoFormKey = GlobalKey<FormState>();
  final _updateObservacoesFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _getGasto(widget.gastoId);
    _obterCategoriasGastos();
    _getOrcamento(widget.orcamentoId);
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

  Future<void> deleteGastoVariado(int gastoVariadoId) async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'orcamentos/${widget.orcamentoId}/gastos-variados/$gastoVariadoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      // Apagar foi bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gasto variado apagado com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna à tela anterior
    } else {
      throw Exception('Falha ao apagar o gasto variado');
    }
  }

  Future<void> _getOrcamento(int orcamentoId) async {
final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      Map<String, dynamic> result = jsonDecode(response.body);
      setState(() {
        print('orcamento ${result}');
        orcamento = result; 
      });
    } else {
      print('orcamento: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar os dados do gasto.')),
      );
      
    }
  }


  // Função para buscar o gasto atualizado via API
  Future<void> _getGasto(int gastoId) async {
final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}/gastos-variados/${widget.gastoId}',
      headers: {
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      setState(() {
        gasto = jsonDecode(response.body); 
        _valorController.text = gasto['observacoes'] ?? '';
        print('gasto: ${gasto.isNotEmpty}');
        
      });
    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar os dados do gasto.')),
      );
      
    }
  }

  // Método para formatar a data no formato DD/MM/YYYY
  String formatDate(String isoDate) {
    print('iso date string: ${isoDate}');
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String _formatarValor(String value) {
    // Remove todos os caracteres não numéricos, exceto o ponto
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');

    print('cleaned value: $cleanedValue');

    // Converte para double e formata
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;

      print('parsed value: ${parsedValue}');

      parsedValue = parsedValue / 100; // Converte centavos para reais
      final formated = _formatador.format(parsedValue);

      print('formated: $formated');

      return formated;
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

  Future<void> _updateObservacoes(int gastoId, String observacoes) async {
    final orcamentoId = widget.orcamentoId;

final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId/gastos-variados/$gastoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode({
        'observacoes': observacoes,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento atualizado com sucesso!')),
      );

      _getGasto(gastoId);

    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar o pagamento.')),
      );
    }
  }


  Future<void> _updateCategoria(int gastoId, int categoriaId) async {
    final orcamentoId = widget.orcamentoId;

final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId/gastos-variados/$gastoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode({
        'categoria_id': categoriaId,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento atualizado com sucesso!')),
      );

      _getGasto(gastoId);

    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar o pagamento.')),
      );
    }
  }

  Future<void> _updateValor(int gastoId, String valor) async {
    final orcamentoId = widget.orcamentoId;

final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId/gastos-variados/$gastoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode({
        'valor': valor,
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento atualizado com sucesso!')),
      );

      _getGasto(gastoId);

    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar o pagamento.')),
      );
    }
  }

  Future<void> _updateDataPagamento(int gastoId, String dataPgto) async {
    final orcamentoId = widget.orcamentoId;

    DateFormat inputFormat = DateFormat('dd/MM/yyyy');
    DateTime parsedDate = inputFormat.parse(dataPgto);

final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId/gastos-variados/$gastoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode({
        'data_pgto': parsedDate.toIso8601String(),
      }),
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento atualizado com sucesso!')),
      );

      _getGasto(gastoId);

    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao atualizar o pagamento.')),
      );
    }
  }

  void _openValorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Valor'),
          content: Form(
            key: _updateValorFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de valor
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    print('rodando o validator');
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira o valor';
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
                    _valorController.value = TextEditingValue(
                      text: formattedValue,
                      selection: TextSelection.collapsed(offset: formattedValue.length),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                String valor = converterParaFormatoNumerico(_valorController.text);
                  if (_updateValorFormKey.currentState?.validate() ?? false) {
                    _updateValor(gasto['id'], valor);
                    _getGasto(widget.gastoId);

                    _valorController.text = '';

                    Navigator.pop(context, true);
                  }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                _valorController.text = '';
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _openCategoriaDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Categoria'),
          content: Form(
            key: _updateCategoriaFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _categorias.isEmpty
                  ? const CircularProgressIndicator() // Exibe um carregando enquanto as categorias são carregadas
                  : DropdownButtonFormField<int>(
                      value: _categoriaIdSelecionada,
                      isExpanded: true,  // Faz o DropdownButton ocupar toda a largura disponível
                      items: _categorias.map((categoria) {
                        return DropdownMenuItem<int>(
                          value: categoria['id'],
                          child: Text(
                            categoria['nome'],
                            overflow: TextOverflow.ellipsis,  // Adiciona elipses se o texto for muito grande
                            softWrap: true,  // Permite que o texto quebre para a linha seguinte se necessário
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                if (_updateCategoriaFormKey.currentState?.validate() ?? false) {
                  _updateCategoria(gasto['id'], _categoriaIdSelecionada ?? 0);
                  _categoriaIdSelecionada = null;
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                _categoriaIdSelecionada = null;
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _openDataPagamentoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Data de Pagamento'),
          content: Form(
            key: _updateDataPagamentoFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Campo de data
                TextFormField(
                  controller: _dataController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Pagamento',
                    border: OutlineInputBorder(),
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
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                String dataPgto = _dataController.text;

                if (_updateDataPagamentoFormKey.currentState?.validate() ?? false) {
                  _updateDataPagamento(gasto['id'], dataPgto);
                  _getGasto(widget.gastoId);
                  _dataController.text = '';
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _dataController.text = '';
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _openObservacoesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Observações'),
          content: Form(
            key: _updateObservacoesFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Campo de valor
                TextFormField(
                  controller: _valorController,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Observações',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira a observação';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _valorController.value = TextEditingValue(
                      text: value,
                      selection: TextSelection.collapsed(offset: value.length),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                String observacoes = _valorController.text;
                if (_updateObservacoesFormKey.currentState?.validate() ?? false) {
                  _updateObservacoes(gasto['id'], observacoes);
                  _getGasto(widget.gastoId);
                  _valorController.text = '';
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Confirmar'),
            ),
            TextButton(
              onPressed: () {
                _valorController.text = '';
                Navigator.pop(context);
              },
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: Text(gasto.isNotEmpty && gasto['descricao'] != null ? gasto['descricao'] : 'Não especificado'),
      ),
      body: gasto.isEmpty || orcamento.isEmpty
          ? const Center(child: CircularProgressIndicator()) // Exibe o progress bar se estiver carregando
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Linha com dois cards (Valor Previsto e Valor Pago)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            title: 'Valor Pago',
                            value: gasto['valor'] != null
                                ? formatarValorDynamic(gasto['valor'])
                                : 'Não pago',
                            color: gasto['valor'] != null ? Colors.black : Colors.red,
                            icon: gasto['valor'] != null ? Icons.check_circle : Icons.cancel,
                            onTap: gasto['valor'] != null && orcamento['data_encerramento'] == null ? () {
                                _openValorDialog(context);
                            } : null
                          ),
                        ),
                      ],
                    ),


                    

                    const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: _buildDetailCard(
                              title: 'Pago em',
                              value: formatDate(gasto['data_pgto']),
                              color: Colors.blueGrey,
                              icon: Icons.calendar_today,
                              onTap: orcamento['data_encerramento'] == null ? () {
                                _openDataPagamentoDialog(context);
                              } : null
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    // Card para Categoria (com largura total e ícone)
                    _buildDetailCard(
                      title: 'Categoria',
                      value: gasto['categoriaGasto']['nome'],
                      color: Colors.deepPurple,
                      icon: Icons.category,
                      onTap: orcamento['data_encerramento'] == null ? () {
                        _openCategoriaDialog(context);
                      }: null
                    ),

                    const SizedBox(height: 20),
                    // Card para Observações
                    _buildDetailCard(
                      title: 'Observações',
                      value: gasto['observacoes'] ?? 'Nenhuma observação',
                      color: Colors.grey,
                      icon: Icons.note,
                      onTap: orcamento['data_encerramento'] == null ? () {
                        _openObservacoesDialog(context);
                      } : null
                    ),

                    orcamento['data_encerramento'] == null ? Column(
                      children: [
                        const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Exclusão'),
                            content: const Text('Você tem certeza que deseja apagar este gasto variado?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, false); // Não apaga
                                },
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context, true); // Apaga o orçamento
                                },
                                child: const Text('Apagar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await deleteGastoVariado(widget.gastoId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Cor vermelha
                        padding: const EdgeInsets.symmetric(vertical: 15), // Maior altura
                        minimumSize: Size(double.infinity, 50), // Ocupa toda a largura
                      ),
                      child: const Text(
                        'Apagar Gasto Variado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                      ],
                    ) : Container(),

                    
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap, // Novo parâmetro para definir uma ação ao tocar no card
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap, // Dispara a ação quando o card é tocado
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10.0),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      style: TextStyle(fontSize: title == 'Pago em' ? 12 : 14, fontWeight: FontWeight.w500, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

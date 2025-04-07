import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orcamentos_app/form_investimento.dart';
import 'package:orcamentos_app/http.dart';
import 'dart:convert';
import 'orcamento_detalhes_page.dart';

class InvestimentosPage extends StatefulWidget {
  final String apiToken;

  const InvestimentosPage({super.key, required this.apiToken});

  @override
  _InvestimentosPageState createState() => _InvestimentosPageState();
}

class _InvestimentosPageState extends State<InvestimentosPage> {
  List<dynamic> _investimentos = [];
  bool _isLoading = false;
  String _apiToken = '';
  bool _isMenuOpen = false; // Controla se os botões secundários estão visíveis

  @override
  void initState() {
    super.initState();
    _apiToken = widget.apiToken;
    if (_apiToken != '') {
      _fetchApiData();
    }
  }

  Future<void> _fetchApiData() async {
    setState(() {
      _isLoading = true;
    });
final client = await MyHttpClient.create();
    final response = await client.get(
      'investimentos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      setState(() {
        _investimentos = json.decode(response.body);
        _isLoading = false;
      });
    } else {
      print("erro na api de investimentos ${response.statusCode}");
    }
  }

  void _addNewInvestimento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioInvestimentoPage(apiToken: widget.apiToken),
      ),
    );

    if (result == true) {
      _fetchApiData();
    }
  }

  void _addNewCategoria() async {
    /*await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasDeGastoPage(apiToken: widget.apiToken),  // Supondo que você tenha uma página para adicionar categoria
      ),
    );*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: const Text('Investimentos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchApiData,  // Função de reload
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()  // Indicador de progresso
            : _investimentos.isEmpty
                ? const Text('Nenhum investimento encontrado')  // Caso não haja investimentos
                : ListView.builder(
                    itemCount: _investimentos.length,
                    itemBuilder: (context, index) {
                      final investimento = _investimentos[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: InkWell(
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrcamentoDetalhesPage(
                                  orcamentoId: investimento['id'],
                                  apiToken: widget.apiToken,
                                ),
                              ),
                            );

                            if (result == true) {
                              _fetchApiData();  // Recarrega os dados se o investimento for excluído
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, size: 30, color: Colors.green),  // Alterando para um ícone financeiro
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        investimento['nome'] ?? 'Sem nome',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Valor Atual: R\$ ${investimento['valor_atual']}',
                                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: Stack(
        children: [
          // Botão principal (abre os outros botões)
          Positioned(
            bottom: 0,
            right: 0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isMenuOpen = !_isMenuOpen;
                });
              },
              backgroundColor: Colors.blue,
              child: Icon(
                _isMenuOpen ? Icons.close : Icons.add,
                color: Colors.white,
              ),
            ),
          ),
          
          // Botão para adicionar um novo investimento (aparece quando _isMenuOpen for true)
          _isMenuOpen
              ? Positioned(
                  width: 230,
                  bottom: 70,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _addNewInvestimento,
                    backgroundColor: Colors.green,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Novo Investimento               ',  // Texto ao lado do ícone
                          style: TextStyle(
                            color: Colors.white,  // Cor do texto
                            fontSize: 14,  // Tamanho da fonte
                          ),
                        ),
                        const SizedBox(width: 8),  // Espaçamento entre o ícone e o texto
                        const Icon(Icons.trending_up, color: Colors.white),
                      ],
                    ), 
                  ),
                )
              : Container(),

          // Botão para adicionar uma nova categoria de investimento
          _isMenuOpen
              ? Positioned(
                  width: 230,
                  bottom: 134,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _addNewCategoria,
                    backgroundColor: Colors.orange,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Categorias de Investimento',  // Texto ao lado do ícone
                          style: TextStyle(
                            color: Colors.white,  // Cor do texto
                            fontSize: 14,  // Tamanho da fonte
                          ),
                        ),
                        const SizedBox(width: 8),  // Espaçamento entre o ícone e o texto
                        const Icon(Icons.category, color: Colors.white),
                      ],
                    ),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}

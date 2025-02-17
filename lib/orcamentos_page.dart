import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orcamentos_app/categorias_gastos_page.dart';
import 'package:orcamentos_app/orcamentos_encerrados_page.dart';
import 'dart:convert';
import 'orcamento_detalhes_page.dart';
import 'form_orcamento.dart';

class OrcamentosPage extends StatefulWidget {
  final String apiToken;

  const OrcamentosPage({super.key, required this.apiToken});

  @override
  _OrcamentosPageState createState() => _OrcamentosPageState();
}

class _OrcamentosPageState extends State<OrcamentosPage> {
  List<dynamic> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false; // Controla se os botões secundários estão visíveis
  String _apiToken = '';

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

    final response = await http.get(
      Uri.parse('http://192.168.73.103:3000/api/v1/orcamentos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      setState(() {
        _orcamentos = (json.decode(response.body) as List)
          .where((orcamento) => orcamento['data_encerramento'] == null)
          .toList();
        _isLoading = false;
      });
    } else {
      print("erro na api de orcamentos ${response.statusCode}");
    }
  }

  void _addNewOrcamento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioOrcamentoPage(apiToken: widget.apiToken),
      ),
    );

    if (result == true) {
      _fetchApiData();
    }
  }

  void _addNewCategoria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasDeGastoPage(apiToken: widget.apiToken),  // Supondo que você tenha uma página para adicionar categoria
      ),
    );
  }

  void _navigateToArquivados() async {
    print('Navigating to Arquivados...');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrcamentosEncerradosPage(
          apiToken: widget.apiToken,
        ),
      ),
    );
    _fetchApiData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
        actions: [
          // Botão Arquivados
          IconButton(
            icon: const Icon(Icons.archive),
            onPressed: _navigateToArquivados, // Aqui você pode direcionar para a tela de arquivados
          ),
          // Botão de recarregar
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchApiData,
          ),
        ],
      ),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _orcamentos.isEmpty
                ? const Text('Nenhum orçamento encontrado')
                : ListView.builder(
                    itemCount: _orcamentos.length,
                    itemBuilder: (context, index) {
                      final orcamento = _orcamentos[index];
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
                                  orcamentoId: orcamento['id'],
                                  apiToken: widget.apiToken,
                                ),
                              ),
                            );
                            _fetchApiData();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet, size: 30, color: Colors.blue),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        orcamento['nome'] ?? 'Sem nome',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Valor Atual: R\$ ${orcamento['valor_atual']}',
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
          
          // Botão para adicionar um novo orçamento (aparece quando _isMenuOpen for true)
          _isMenuOpen
              ? Positioned(
                  width: 180,
                  bottom: 70,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _addNewOrcamento,
                    backgroundColor: Colors.green,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Novo Orçamento     ',  // Texto ao lado do ícone
                          style: TextStyle(
                            color: Colors.white,  // Cor do texto
                            fontSize: 14,  // Tamanho da fonte
                          ),
                        ),
                        const SizedBox(width: 8),  // Espaçamento entre o ícone e o texto
                        const Icon(Icons.account_balance_wallet, color: Colors.white),
                      ],
                    ), 
                  ),
                )
              : Container(),

          // Botão para adicionar uma nova categoria de gasto
          _isMenuOpen
              ? Positioned(
                  width: 180,
                  bottom: 134,
                  right: 0,
                  child: FloatingActionButton(
                    onPressed: _addNewCategoria,
                    backgroundColor: Colors.orange,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Categorias de Gasto',  // Texto ao lado do ícone
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

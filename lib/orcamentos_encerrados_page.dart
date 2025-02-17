import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'orcamento_detalhes_page.dart';
import 'form_orcamento.dart';

class OrcamentosEncerradosPage extends StatefulWidget {
  final String apiToken;

  const OrcamentosEncerradosPage({super.key, required this.apiToken});

  @override
  _OrcamentosEncerradosPageState createState() => _OrcamentosEncerradosPageState();
}

class _OrcamentosEncerradosPageState extends State<OrcamentosEncerradosPage> {
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
          .where((orcamento) => orcamento['data_encerramento'] != null)
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
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioOrcamentoPage(apiToken: widget.apiToken),  // Supondo que você tenha uma página para adicionar categoria
      ),
    );

    if (result == true) {
      // Atualize a lista de categorias ou faça algum outro processamento necessário
    }
  }

  void _navigateToArquivados() {
    // Função que será chamada ao clicar no botão Arquivados
    print('Navigating to Arquivados...');
    // Aqui você pode implementar a navegação para a tela de orçamentos arquivados
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos Encerrados'),
        actions: [
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
                ? const Text('Nenhum orçamento encerrado encontrado')
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
    );
  }
}

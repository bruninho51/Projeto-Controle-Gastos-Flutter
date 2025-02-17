// investimentos_page.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
      Uri.parse('http://192.168.73.103:3000/api/v1/investimentos'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
    );
  }
}

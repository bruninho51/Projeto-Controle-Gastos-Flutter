import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GastosVariaveisPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosVariaveisPage({super.key, required this.orcamentoId, required this.apiToken});

  @override
  _GastosVariaveisPageState createState() => _GastosVariaveisPageState();
}

class _GastosVariaveisPageState extends State<GastosVariaveisPage> {
  late Future<List<Map<String, dynamic>>> _gastosVariaveis;

  @override
  void initState() {
    super.initState();
    _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
  }

  Future<List<Map<String, dynamic>>> fetchGastosVariaveis(int orcamentoId) async {
    final url = 'http://192.168.1.147:3000/api/v1/orcamentos/$orcamentoId/gastos-variados';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => item as Map<String, dynamic>).toList();
    } else {
      throw Exception('Falha ao carregar os gastos variados');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Variados'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gastosVariaveis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum gasto variado encontrado'));
          } else {
            List<Map<String, dynamic>> _gastosVariaveis = snapshot.data!;

            return ListView.builder(
              itemCount: _gastosVariaveis.length,
              itemBuilder: (context, index) {
                final gasto = _gastosVariaveis[index];
                return Card(
                  elevation: 5.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        // Container com o ícone
                        Container(
                          padding: const EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1), // Cor de fundo do ícone
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.attach_money,
                            color: Colors.blue,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        // Descrição e valor do gasto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                gasto['descricao'],
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('R\$ ${gasto['valor']}'),
                            ],
                          ),
                        ),
                        // Status do pagamento
                        Text(
                          'PAGO',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:orcamentos_app/form_gasto_fixo_page.dart';
import 'package:orcamentos_app/gasto_fixo_detalhes_page.dart';
import 'dart:convert';

class GastosFixosPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosFixosPage({super.key, required this.orcamentoId, required this.apiToken});

  @override
  _GastosFixosPageState createState() => _GastosFixosPageState();
}

class _GastosFixosPageState extends State<GastosFixosPage> {
  late Future<List<Map<String, dynamic>>> _gastosFixos;

  @override
  void initState() {
    super.initState();
    _gastosFixos = fetchGastosFixos(widget.orcamentoId);
  }

   Future<Map<String, dynamic>> _getOrcamento(int orcamentoId) async {
    final url =
        'http://192.168.1.147:3000/api/v1/orcamentos/${widget.orcamentoId}';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      Map<String, dynamic> result = jsonDecode(response.body);
      return result;
    } else {
      print(response.body.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar os dados do gasto.')),
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchGastosFixos(int orcamentoId) async {
    final url = 'http://192.168.1.147:3000/api/v1/orcamentos/$orcamentoId/gastos-fixos';

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
      throw Exception('Falha ao carregar os gastos fixos');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gastos Fixos'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gastosFixos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum gasto fixo encontrado'));
          } else {
            List<Map<String, dynamic>> gastosFixos = snapshot.data!;

            return ListView.builder(
              itemCount: gastosFixos.length,
              itemBuilder: (context, index) {
                final gasto = gastosFixos[index];

                return GestureDetector(
                  onTap: () async {
                    // Navegar para a tela de detalhes do gasto fixo
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesGastoPage(gastoId: gasto['id'], orcamentoId: gasto['orcamento_id'], apiToken: widget.apiToken,),
                      ),
                    );

                    setState(() {
                      _gastosFixos = fetchGastosFixos(widget.orcamentoId);
                    });
                  },
                  child: Card(
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
                                Text('R\$ ${gasto['previsto']}'),
                              ],
                            ),
                          ),
                          // Status do pagamento
                          Text(
                            gasto['valor'] != null ? 'PAGO' : 'NÃO PAGO',
                            style: TextStyle(
                              color: gasto['valor'] != null ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
      // Floating Action Button
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
  future: _getOrcamento(widget.orcamentoId), // Supondo que fetchOrcamento() seja o método que retorna o Future com o seu orçamento
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      // Exibe um indicador de carregamento enquanto o Future não é resolvido
      return CircularProgressIndicator();
    }

    if (snapshot.hasError) {
      // Lida com erros, se necessário
      return Icon(Icons.error);
    }

    if (snapshot.hasData) {
      // Agora podemos acessar os dados do orçamento
      Map<String, dynamic> _orcamento = snapshot.data!;

      return _orcamento['data_encerramento'] == null
          ? FloatingActionButton(
              onPressed: () async {
                // Navegar para a tela de criação de gasto fixo
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CriacaoGastoFixoPage(
                      orcamentoId: widget.orcamentoId,
                      apiToken: widget.apiToken,
                    ),
                  ),
                );

                setState(() {
                  _gastosFixos = fetchGastosFixos(widget.orcamentoId);
                });
              },
              tooltip: 'Adicionar Gasto Fixo',
              child: const Icon(Icons.add),
            )
          : Container(); // Retorna um container vazio caso 'data_encerramento' não seja nulo
    }

    return Container(); // Caso o Future ainda não tenha dados, você pode exibir um container vazio ou outro conteúdo
  },
),
    );
  }
}

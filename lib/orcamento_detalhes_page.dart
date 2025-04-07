import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/form_orcamento_valor_inicial.dart';
import 'package:orcamentos_app/gastos_fixos_page.dart';
import 'package:orcamentos_app/gastos_variaveis_page.dart';
import 'package:orcamentos_app/http.dart';
import 'formatters.dart';

class OrcamentoDetalhesPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const OrcamentoDetalhesPage({super.key, required this.orcamentoId, required this.apiToken});

  @override
  _OrcamentoDetalhesPageState createState() => _OrcamentoDetalhesPageState();
}

class _OrcamentoDetalhesPageState extends State<OrcamentoDetalhesPage> {
  late Future<Map<String, dynamic>> _orcamentoDetalhes;

  @override
  void initState() {
    super.initState();
    _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId); // Chama a função para buscar os dados inicialmente
  }

  Future<Map<String, dynamic>> fetchOrcamentoDetalhes(int orcamentoId) async {
    
final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      var detalhes = jsonDecode(response.body);

      detalhes['gastos_fixos'] = (await fetchQtdGastosFixos(orcamentoId)).toString();
      detalhes['gastos_variados'] = (await fetchQtdGastosVariados(orcamentoId)).toString();

      return detalhes;
    } else {
      throw Exception('Falha ao carregar os detalhes do orçamento');
    }
  }

  Future<int> fetchQtdGastosFixos(int orcamentoId) async {
final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      print("qtd: ${jsonDecode(response.body).length}");
      return jsonDecode(response.body).length;
    } else {
      throw Exception('Falha ao carregar a quantidade de gastos fixos');
    }
  }

  Future<int> fetchQtdGastosVariados(int orcamentoId) async {
final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body).length;
    } else {
      throw Exception('Falha ao carregar a quantidade de gastos variados');
    }
  }

  Future<void> encerrarOrcamento(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
      body: jsonEncode({
        'data_encerramento': DateTime.now().toIso8601String(),
      }),
    );

    if (response.statusCode == 200) {
      // Apagar foi bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento encerrado com sucesso!')),
      );
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao encerrar o orçamento');
    }
  }

  Future<void> reativarOrcamento(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
      body: jsonEncode({
        'data_encerramento': null,
      }),
    );

    if (response.statusCode == 200) {
      // Apagar foi bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento reativado com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna à tela anterior
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao reativar o orçamento');
    }
  }

  // Função para apagar o orçamento
  Future<void> deleteOrcamento(int orcamentoId) async {
    
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken ?? ''}',
      },
    );

    if (response.statusCode == 200) {
      // Apagar foi bem-sucedido
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento apagado com sucesso!')),
      );
      Navigator.pop(context, true); // Retorna à tela anterior
    } else {
      throw Exception('Falha ao apagar o orçamento');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50], // Cor da AppBar
      appBar: AppBar(
        backgroundColor: Colors.blue[50], // Cor da AppBar
        title: const Text('Detalhes do Orçamento'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId); // Recarrega os dados
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _orcamentoDetalhes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            } else if (!snapshot.hasData) {
              return const Center(child: Text('Nenhum dado encontrado'));
            } else {
              final orcamento = snapshot.data!;
              final valorInicial = orcamento['valor_inicial'] ?? '0.0';
              final valorAtual = orcamento['valor_atual'] ?? '0.0';
              final valorLivre = orcamento['valor_livre'] ?? '0.0';
              final gastosFixos = orcamento['gastos_fixos'];
              final gastosVariados = orcamento['gastos_variados'];
              final dataCriacao = orcamento['data_criacao'] != null
                  ? formatDate(orcamento['data_criacao'])
                  : 'Desconhecida';

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nome do Orçamento
                    Text(
                      '${orcamento['nome']}',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),

                    // Grid de Cards
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 colunas
                        crossAxisSpacing: 10.0,
                        mainAxisSpacing: 10.0,
                        childAspectRatio: 1.0, // Faz os cards quadrados
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        switch (index) {
                          case 0:
                            return GestureDetector(
                              onTap: orcamento['data_encerramento'] == null ? () async {
                                // Ao clicar no "Valor Inicial", navega para a nova tela
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormOrcamentoValorInicialPage(apiToken: widget.apiToken, orcamentoId: orcamento['id'], valorInicial: double.parse(valorInicial),),
                                  ),
                                );

                                setState(() {
                                  _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId); // Recarrega os dados
                                });
                              } : null,
                              child: _buildDashboardCard(
                                'Valor Inicial',
                                formatarValor(valorInicial),
                                Colors.blue,
                                Icons.monetization_on,
                              ),
                            );
                          case 1:
                            return _buildDashboardCard(
                              'Valor Atual',
                              formatarValor(valorAtual),
                              Colors.green,
                              Icons.paid,
                            );
                          case 2:
                            return _buildDashboardCard(
                              'Valor Livre',
                              formatarValor(valorLivre),
                              Colors.orange,
                              Icons.account_balance_wallet,
                            );
                          case 3:
                             return GestureDetector(
                                onTap: () async {
                                  // Ao clicar no "Gastos Fixos", navega para a nova tela de gastos fixos
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GastosFixosPage(
                                        apiToken: widget.apiToken,
                                        orcamentoId: widget.orcamentoId,
                                      ),
                                    ),
                                  );

                                  setState(() {
                                    _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId); // Recarrega os dados
                                  });
                                },
                                child: _buildDashboardCard(
                                  'Gastos Fixos',
                                  '$gastosFixos itens',
                                  Colors.blue,
                                  Icons.attach_money,
                                ),
                            );
                          case 4:
                            return GestureDetector(
                                onTap: () async {
                                  // Ao clicar no "Gastos Fixos", navega para a nova tela de gastos fixos
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GastosVariaveisPage(
                                        apiToken: widget.apiToken,
                                        orcamentoId: widget.orcamentoId,
                                      ),
                                    ),
                                  );

                                  setState(() {
                                    _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId); // Recarrega os dados
                                  });
                                },
                                child: _buildDashboardCard(
                                  'Gastos Variados',
                                  '$gastosVariados itens',
                                  Colors.purple,
                                  Icons.change_circle,
                                ),
                            );
                          case 5:
                            return _buildDashboardCard(
                              'Data de Criação',
                              dataCriacao,
                              Colors.grey,
                              Icons.calendar_today,
                            );
                          default:
                            return Container();
                        }
                      },
                    ),

                    orcamento['data_encerramento'] == null ? Column(
                      children: [
                        const SizedBox(height: 20),
                    // Botão Apagar Orçamento
                    ElevatedButton(
                      onPressed: () async {
                        bool? confirmEncerramento = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Encerramento'),
                            content: const Text('Você tem certeza que deseja encerrar este orçamento?'),
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
                                child: const Text('Encerrar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmEncerramento == true) {
                          await encerrarOrcamento(widget.orcamentoId);

                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey, // Cor vermelha
                        padding: const EdgeInsets.symmetric(vertical: 15), // Maior altura
                        minimumSize: Size(double.infinity, 50), // Ocupa toda a largura
                      ),
                      child: const Text(
                        'Encerrar Orçamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                      ],
                    ) : Container(),

                    orcamento['data_encerramento'] == null ? Column(
                      children: [
                        const SizedBox(height: 20),
                    // Botão Apagar Orçamento
                    ElevatedButton(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Exclusão'),
                            content: const Text('Você tem certeza que deseja apagar este orçamento?'),
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
                          await deleteOrcamento(widget.orcamentoId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Cor vermelha
                        padding: const EdgeInsets.symmetric(vertical: 15), // Maior altura
                        minimumSize: Size(double.infinity, 50), // Ocupa toda a largura
                      ),
                      child: const Text(
                        'Apagar Orçamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                      ],
                    ) : Container(),

                    orcamento['data_encerramento'] != null ? Column(
                      children: [
                        const SizedBox(height: 20),
                        ElevatedButton(
                      onPressed: () async {
                        bool? confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Reativação'),
                            content: const Text('Você tem certeza que deseja reativar este orçamento?'),
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
                                child: const Text('Reativar'),
                              ),
                            ],
                          ),
                        );

                        if (confirmDelete == true) {
                          await reativarOrcamento(widget.orcamentoId);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange, // Cor vermelha
                        padding: const EdgeInsets.symmetric(vertical: 15), // Maior altura
                        minimumSize: Size(double.infinity, 50), // Ocupa toda a largura
                      ),
                      child: const Text(
                        'Reativar Orcaçmento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )

                      ],
                    ) : Container(),
                    

                    
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  // Método para formatar a data no formato DD/MM/YYYY
  String formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  // Método para criar os cards de forma reutilizável com ícones
  Widget _buildDashboardCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1), // Cor de fundo do ícone
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                fontSize: title == 'Data de Criação' ? 12 : 18,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

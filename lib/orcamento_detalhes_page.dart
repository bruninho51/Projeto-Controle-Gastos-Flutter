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
    _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento encerrado com sucesso!')),
      );
      setState(() {
        _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId);
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento reativado com sucesso!')),
      );
      setState(() {
        _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId);
      });
    } else {
      throw Exception('Falha ao reativar o orçamento');
    }
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento apagado com sucesso!')),
      );
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o orçamento');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        title: const Text('Detalhes do Orçamento', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              setState(() {
                _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId);
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _orcamentoDetalhes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 50, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Erro: ${snapshot.error}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _orcamentoDetalhes = fetchOrcamentoDetalhes(widget.orcamentoId);
                        });
                      },
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.warning_amber, size: 50, color: Colors.orange),
                    SizedBox(height: 16),
                    Text('Nenhum dado encontrado', style: TextStyle(fontSize: 16)),
                  ],
                ),
              );
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
              final isEncerrado = orcamento['data_encerramento'] != null;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabeçalho com nome e status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${orcamento['nome']}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isEncerrado
                                            ? Colors.grey[200]
                                            : Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isEncerrado ? 'ENCERRADO' : 'ATIVO',
                                        style: TextStyle(
                                          color: isEncerrado
                                              ? Colors.grey[800]
                                              : Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    if (isEncerrado) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        'Encerrado em ${formatDate(orcamento['data_encerramento'])}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isEncerrado)
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.indigo),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FormOrcamentoValorInicialPage(
                                      apiToken: widget.apiToken,
                                      orcamentoId: orcamento['id'],
                                      valorInicial: double.parse(valorInicial),
                                    ),
                                  ),
                                );
                                setState(() {
                                  _orcamentoDetalhes =
                                      fetchOrcamentoDetalhes(widget.orcamentoId);
                                });
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Grid de Cards
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        childAspectRatio: 1.2,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        switch (index) {
                          case 0:
                            return _buildDashboardCard(
                              'Valor Inicial',
                              formatarValor(valorInicial),
                              Colors.indigo,
                              Icons.account_balance,
                              onTap: isEncerrado
                                  ? null
                                  : () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FormOrcamentoValorInicialPage(
                                            apiToken: widget.apiToken,
                                            orcamentoId: orcamento['id'],
                                            valorInicial:
                                                double.parse(valorInicial),
                                          ),
                                        ),
                                      );
                                      setState(() {
                                        _orcamentoDetalhes =
                                            fetchOrcamentoDetalhes(
                                                widget.orcamentoId);
                                      });
                                    },
                            );
                          case 1:
                            return _buildDashboardCard(
                              'Valor Atual',
                              formatarValor(valorAtual),
                              Colors.teal,
                              Icons.bar_chart,
                            );
                          case 2:
                            return _buildDashboardCard(
                              'Valor Livre',
                              formatarValor(valorLivre),
                              Colors.orange,
                              Icons.account_balance_wallet,
                            );
                          case 3:
                            return _buildDashboardCard(
                              'Gastos Fixos',
                              '$gastosFixos itens',
                              Colors.blue,
                              Icons.attach_money,
                              onTap: () async {
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
                                  _orcamentoDetalhes =
                                      fetchOrcamentoDetalhes(widget.orcamentoId);
                                });
                              },
                            );
                          case 4:
                            return _buildDashboardCard(
                              'Gastos Variados',
                              '$gastosVariados itens',
                              Colors.purple,
                              Icons.shopping_cart,
                              onTap: () async {
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
                                  _orcamentoDetalhes =
                                      fetchOrcamentoDetalhes(widget.orcamentoId);
                                });
                              },
                            );
                          case 5:
                            return _buildDashboardCard(
                              'Criado em',
                              dataCriacao,
                              Colors.grey,
                              Icons.calendar_today,
                            );
                          default:
                            return Container();
                        }
                      },
                    ),

                    const SizedBox(height: 24),

                    // Ações do orçamento
                    if (!isEncerrado) ...[
                      _buildActionButton(
                        'Encerrar Orçamento',
                        Icons.lock_clock,
                        Colors.blueGrey,
                        onPressed: () => _confirmAction(
                          'Confirmar Encerramento',
                          'Você tem certeza que deseja encerrar este orçamento?',
                          'Encerrar',
                          encerrarOrcamento,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildActionButton(
                        'Apagar Orçamento',
                        Icons.delete,
                        Colors.red,
                        onPressed: () => _confirmAction(
                          'Confirmar Exclusão',
                          'Você tem certeza que deseja apagar este orçamento?',
                          'Apagar',
                          deleteOrcamento,
                        ),
                      ),
                    ] else
                      _buildActionButton(
                        'Reativar Orçamento',
                        Icons.lock_open,
                        Colors.orange,
                        onPressed: () => _confirmAction(
                          'Confirmar Reativação',
                          'Você tem certeza que deseja reativar este orçamento?',
                          'Reativar',
                          reativarOrcamento,
                        ),
                      ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> _confirmAction(
    String title,
    String content,
    String actionText,
    Future<void> Function(int) action,
  ) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await action(widget.orcamentoId);
    }
  }

  String formatDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(dateTime);
  }

  Widget _buildDashboardCard(
    String title,
    String value,
    Color color,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (onTap != null)
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: title == 'Criado em' ? 14 : 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
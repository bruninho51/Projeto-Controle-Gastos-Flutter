import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DashboardPage extends StatefulWidget {
  final String apiToken;

  const DashboardPage({super.key, required this.apiToken});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inicialize o TabController aqui, usando o ticker provider.
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose(); // Certifique-se de limpar o TabController
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Métricas Orçamentos'),
            /*Tab(text: 'Métricas Investimentos'),*/
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Página de orçamentos
          FutureBuilder<Map<String, dynamic>>(
            future: _fetchDashboardData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Sem dados disponíveis'));
              }

              final data = snapshot.data!;

              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Duas colunas
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 8, // Número de métricas a serem exibidas
                  itemBuilder: (context, index) {
                    final metrics = [
                      {'label': 'Orçamentos Em Andamento', 'value': data['qtdOrcamentosAtivos'], 'icon': Icons.list, 'color': Colors.teal},
                      {'label': 'Orçamentos Encerrados', 'value': data['qtdOrcamentosEncerrados'], 'icon': Icons.done, 'color': Colors.orange},
                      {'label': 'Valor Total', 'value': 'R\$ ${data['valorInicialAtivos']}', 'icon': Icons.attach_money, 'color': Colors.green},
                      {'label': 'Valor Livre', 'value': 'R\$ ${data['valorLivreAtivos']}', 'icon': Icons.money_off, 'color': Colors.purple},
                      {'label': 'Valor Atual', 'value': 'R\$ ${data['valorAtualAtivos']}', 'icon': Icons.account_balance_wallet, 'color': Colors.blue},
                      {'label': 'Total Gastos Fixos', 'value': 'R\$ ${data['gastosFixosAtivos']}', 'icon': Icons.account_balance, 'color': Colors.red},
                      {'label': 'Total Gastos Variáveis', 'value': 'R\$ ${data['gastosVariaveisAtivos']}', 'icon': Icons.trending_up, 'color': Colors.amber},
                      {'label': 'Valor Poupado', 'value': 'R\$ ${data['gastosFixosValorPoupado']}', 'icon': Icons.pie_chart, 'color': Colors.indigo},
                    ];

                    return _buildDetailCard(
                      title: metrics[index]['label']!,
                      value: metrics[index]['value'].toString(),
                      color: metrics[index]['color']!,
                      icon: metrics[index]['icon'],
                      onTap: () {
                        // Ação ao tocar no card
                        print('Card Tocado: ${metrics[index]['label']}');
                      },
                    );
                  },
                ),
              );
            },
          ),

          // Página de investimentos
          /*FutureBuilder<List<dynamic>>(
            future: _fetchOrcamentos(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return const Center(child: Text('Sem orçamentos disponíveis'));
              }

              return ListView.builder(
                itemCount: 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Em breve!'),
                    
                  );
                },
              );
            },
          ),*/
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchOrcamentos() async {
    final response = await http.get(
      Uri.parse('http://192.168.73.103:3000/api/v1/orcamentos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return json.decode(response.body);
    } else {
      print("Erro na API de orçamentos: ${response.statusCode}");
      return [];
    }
  }

  Future<List<dynamic>> fetchGastosFixos(int orcamentoId) async {
    final url = 'http://192.168.73.103:3000/api/v1/orcamentos/$orcamentoId/gastos-fixos';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    } else {
      print("Erro na API de orçamentos: ${response.statusCode}");
      return [];
    }
  }

  Future<List<dynamic>> fetchGastosVariaveis(int orcamentoId) async {
    final url = 'http://192.168.73.103:3000/api/v1/orcamentos/$orcamentoId/gastos-variados';

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      var gastosVariaveis = jsonDecode(response.body);
      print('gastos variaveis orcamento: $gastosVariaveis');
      return gastosVariaveis;
    } else {
      print("Erro na API de orçamentos: ${response.statusCode}");
      return [];
    }
  }

  Future<int> _fetchOrcamentosAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

    return orcamentosAtivos.length;
  }

  Future<int> _fetchOrcamentosEncerrados() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] != null).toList();

    return orcamentosAtivos.length;
  }

  Future<double> _fetchValorInicialAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

     double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_inicial'].toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchValorLivreAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

     double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_livre'].toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchValorAtualAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

     double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_atual'].toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(orcamentoId);

    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse((element['valor'] ?? element['previsto']).toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchValorPoupadoGastosFixosOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(orcamentoId);

    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['diferenca'].toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchTotalGastosVariaveisOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosVariaveis(orcamentoId);

    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor'].toString()) ?? 0.0; // Garantindo que o valor seja um double
      return previousValue + valorTotal;
    });

    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamentosAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

    double totalValue = 0.0;

    print("ativos: ${orcamentosAtivos}");

    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchTotalGastosFixosOrcamento(orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }

    return totalValue;
  }

  Future<double> _fetchTotalGastosVariaveisOrcamentosAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

    double totalValue = 0.0;

    print("ativos: ${orcamentosAtivos}");

    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchTotalGastosVariaveisOrcamento(orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }

    return totalValue;
  }

  Future<double> _fetchValorPoupadoGastosFixosOrcamentosAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();

    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();

    double totalValue = 0.0;

    print("ativos: ${orcamentosAtivos}");

    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchValorPoupadoGastosFixosOrcamento(orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }

    return totalValue;
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
    // Simulando os dados para o momento
    Map<String, dynamic> data = {};
    data['qtdOrcamentosAtivos'] = await _fetchOrcamentosAtivos();
    data['qtdOrcamentosEncerrados'] = await _fetchOrcamentosEncerrados();
    data['valorInicialAtivos'] = await _fetchValorInicialAtivos();
    data['valorLivreAtivos'] = await _fetchValorLivreAtivos();
    data['valorAtualAtivos'] = await _fetchValorAtualAtivos();
    data['gastosFixosAtivos'] = await _fetchTotalGastosFixosOrcamentosAtivos();
    data['gastosVariaveisAtivos'] = await _fetchTotalGastosVariaveisOrcamentosAtivos();
    data['gastosFixosValorPoupado'] = await _fetchValorPoupadoGastosFixosOrcamentosAtivos();

    return data;
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const SizedBox(height: 15),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

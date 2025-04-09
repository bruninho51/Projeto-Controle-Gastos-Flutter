import 'package:flutter/material.dart';
import 'package:orcamentos_app/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';

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
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        elevation: 4,
        title: const Text(
          'Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.indigo[700],
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.amber[400],
              indicatorWeight: 4,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Métricas Orçamentos'),
                /*Tab(text: 'Métricas Investimentos'),*/
              ],
            ),
          ),
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo[700]!),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Carregando métricas...',
                        style: TextStyle(
                          color: Colors.indigo[700],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 50, color: Colors.red[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar dados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.red[600],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Tentar novamente', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.info_outline, size: 50, color: Colors.amber[600]),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum dado disponível',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.indigo[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data!;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.grey[100]!,
                      Colors.grey[200]!,
                    ],
                  ),
                ),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final metrics = [
                      {
                        'label': 'Orçamentos Ativos',
                        'value': data['qtdOrcamentosAtivos'],
                        'icon': Icons.list_alt_rounded,
                        'color': Colors.teal[600]!,
                        'bgColor': Colors.teal[50]!,
                      },
                      {
                        'label': 'Orçamentos Encerrados',
                        'value': data['qtdOrcamentosEncerrados'],
                        'icon': Icons.check_circle_outline,
                        'color': Colors.orange[600]!,
                        'bgColor': Colors.orange[50]!,
                      },
                      {
                        'label': 'Valor Total',
                        'value': formatarValor(data['valorInicialAtivos']),
                        'icon': Icons.attach_money_rounded,
                        'color': Colors.green[700]!,
                        'bgColor': Colors.green[50]!,
                      },
                      {
                        'label': 'Valor Livre',
                        'value': formatarValor(data['valorLivreAtivos']),
                        'icon': Icons.account_balance_wallet_rounded,
                        'color': Colors.purple[600]!,
                        'bgColor': Colors.purple[50]!,
                      },
                      {
                        'label': 'Valor Atual',
                        'value': formatarValor(data['valorAtualAtivos']),
                        'icon': Icons.pie_chart_rounded,
                        'color': Colors.blue[600]!,
                        'bgColor': Colors.blue[50]!,
                      },
                      {
                        'label': 'Gastos Fixos',
                        'value': formatarValor(data['gastosFixosAtivos']),
                        'icon': Icons.receipt_long_rounded,
                        'color': Colors.red[600]!,
                        'bgColor': Colors.red[50]!,
                      },
                      {
                        'label': 'Gastos Variáveis',
                        'value': formatarValor(data['gastosVariaveisAtivos']),
                        'icon': Icons.trending_up_rounded,
                        'color': Colors.amber[700]!,
                        'bgColor': Colors.amber[50]!,
                      },
                      {
                        'label': 'Valor Poupado',
                        'value': formatarValor(data['gastosFixosValorPoupado']),
                        'icon': Icons.savings_rounded,
                        'color': Colors.indigo[600]!,
                        'bgColor': Colors.indigo[50]!,
                      },
                    ];

                    return _buildMetricCard(
                      title: metrics[index]['label']!,
                      value: metrics[index]['value'].toString(),
                      color: metrics[index]['color'],
                      bgColor: metrics[index]['bgColor'],
                      icon: metrics[index]['icon'],
                    );
                  },
                ),
              );
            },
          ),

          // Página de investimentos (comentada)
          /*Container(
            alignment: Alignment.center,
            child: const Text('Em desenvolvimento', style: TextStyle(fontSize: 18)),
          ),*/
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Todos os métodos de fetch permanecem EXATAMENTE como estavam
  Future<List<dynamic>> _fetchOrcamentos() async {
    final client = await MyHttpClient.create();
    
    final response = await client.get(
      'orcamentos',
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
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
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
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
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
      double valorTotal = double.tryParse(element['valor_inicial'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorLivreAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_livre'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorAtualAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_atual'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse((element['valor'] ?? element['previsto']).toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorPoupadoGastosFixosOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['diferenca'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosVariaveisOrcamento(orcamentoId) async {
    List<dynamic> gastos = await fetchGastosVariaveis(orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamentosAtivos() async {
    List<dynamic> orcamentos = await _fetchOrcamentos();
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = 0.0;
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
    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchValorPoupadoGastosFixosOrcamento(orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }
    return totalValue;
  }

  Future<Map<String, dynamic>> _fetchDashboardData() async {
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
}
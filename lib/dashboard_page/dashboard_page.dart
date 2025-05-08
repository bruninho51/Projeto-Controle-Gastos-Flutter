import 'package:flutter/material.dart';
import 'package:orcamentos_app/refatorado/orcamentos_loading.dart';
import 'package:orcamentos_app/formatters.dart';
import 'package:orcamentos_app/gastos_variados_page/auth_provider.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/info_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/orcamento_detalhes_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

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

  Widget _buildDashboardCards(Map<String, dynamic> data) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.2,
      children: [
        OrcamentoDetalhesCard(
            title: 'Orçamentos Ativos',
            value: data['qtdOrcamentosAtivos'].toString(),
            color: Colors.teal[600]!,
            icon: Icons.list_alt_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Orçamentos Encerrados',
            value: data['qtdOrcamentosEncerrados'].toString(),
            color: Colors.orange[600]!,
            icon: Icons.check_circle_outline,
          ),
          OrcamentoDetalhesCard(
            title: 'Valor Total',
            value: formatarValor(data['valorInicialAtivos']),
            color: Colors.green[700]!,
            icon: Icons.attach_money_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Valor Livre',
            value: formatarValor(data['valorLivreAtivos']),
            color: Colors.purple[600]!,
            icon: Icons.account_balance_wallet_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Valor Atual',
            value: formatarValor(data['valorAtualAtivos']),
            color: Colors.blue[600]!,
            icon: Icons.pie_chart_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Gastos Fixos',
            value: formatarValor(data['gastosFixosAtivos']),
            color: Colors.red[600]!,
            icon: Icons.receipt_long_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Gastos Variáveis',
            value: formatarValor(data['gastosVariaveisAtivos']),
            color: Colors.amber[700]!,
            icon: Icons.trending_up_rounded,
          ),
          OrcamentoDetalhesCard(
            title: 'Valor Poupado',
            value: formatarValor(data['gastosFixosValorPoupado']),
            color: Colors.indigo[600]!,
            icon: Icons.savings_rounded,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
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
            future: _fetchDashboardData(auth),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return OrcamentosLoading(message: 'Carregando métricas...');
              } else if (snapshot.hasError) {
                return InfoStateWidget(
                  buttonForegroundColor: Colors.red,
                  buttonBackgroundColor: Colors.white,
                  icon: Icons.error,
                  iconColor: Colors.red,
                  message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido',
                  buttonText: 'Tentar novamente',
                  onPressed: () => setState(() {}),
                );
              } else if (!snapshot.hasData) {
                return InfoStateWidget(
                  buttonForegroundColor: Colors.red,
                  buttonBackgroundColor: Colors.white,
                  icon: Icons.info_outline,
                  iconColor: Colors.amber[600]!,
                  message: 'Nenhum dado disponível',
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
                child: _buildDashboardCards(data)
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

  Future<List<dynamic>> _fetchOrcamentos(String apiToken) async {
    final client = await MyHttpClient.create();
    
    final response = await client.get(
      'orcamentos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return json.decode(response.body);
    } else {
      print("Erro na API de orçamentos: ${response.statusCode}");
      return [];
    }
  }

  Future<List<dynamic>> fetchGastosFixos(String apiToken, int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    } else {
      print("Erro na API de orçamentos: ${response.statusCode}");
      return [];
    }
  }

  Future<List<dynamic>> fetchGastosVariaveis(String apiToken, int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
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

  Future<int> _fetchOrcamentosAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    return orcamentosAtivos.length;
  }

  Future<int> _fetchOrcamentosEncerrados(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] != null).toList();
    return orcamentosAtivos.length;
  }

  Future<double> _fetchValorInicialAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_inicial'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorLivreAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_livre'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorAtualAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = orcamentosAtivos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor_atual'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamento(String apiToken, orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(apiToken, orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse((element['valor'] ?? element['previsto']).toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchValorPoupadoGastosFixosOrcamento(String apiToken, orcamentoId) async {
    List<dynamic> gastos = await fetchGastosFixos(apiToken, orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['diferenca'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosVariaveisOrcamento(String apiToken, orcamentoId) async {
    List<dynamic> gastos = await fetchGastosVariaveis(apiToken, orcamentoId);
    double totalValue = gastos.fold(0.0, (previousValue, element) {
      double valorTotal = double.tryParse(element['valor'].toString()) ?? 0.0;
      return previousValue + valorTotal;
    });
    return totalValue;
  }

  Future<double> _fetchTotalGastosFixosOrcamentosAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = 0.0;
    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchTotalGastosFixosOrcamento(apiToken, orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }
    return totalValue;
  }

  Future<double> _fetchTotalGastosVariaveisOrcamentosAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = 0.0;
    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchTotalGastosVariaveisOrcamento(apiToken, orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }
    return totalValue;
  }

  Future<double> _fetchValorPoupadoGastosFixosOrcamentosAtivos(String apiToken) async {
    List<dynamic> orcamentos = await _fetchOrcamentos(apiToken);
    List<dynamic> orcamentosAtivos = orcamentos.where((orcamento) => orcamento['data_encerramento'] == null).toList();
    double totalValue = 0.0;
    for (var orcamento in orcamentosAtivos) {
      double valorTotal = double.tryParse((await _fetchValorPoupadoGastosFixosOrcamento(apiToken, orcamento['id'])).toString()) ?? 0.0;
      totalValue += valorTotal;
    }
    return totalValue;
  }

  Future<Map<String, dynamic>> _fetchDashboardData(AuthProvider auth) async {
    Map<String, dynamic> data = {};
    data['qtdOrcamentosAtivos'] = await _fetchOrcamentosAtivos(auth.apiToken);
    data['qtdOrcamentosEncerrados'] = await _fetchOrcamentosEncerrados(auth.apiToken);
    data['valorInicialAtivos'] = await _fetchValorInicialAtivos(auth.apiToken);
    data['valorLivreAtivos'] = await _fetchValorLivreAtivos(auth.apiToken);
    data['valorAtualAtivos'] = await _fetchValorAtualAtivos(auth.apiToken);
    data['gastosFixosAtivos'] = await _fetchTotalGastosFixosOrcamentosAtivos(auth.apiToken);
    data['gastosVariaveisAtivos'] = await _fetchTotalGastosVariaveisOrcamentosAtivos(auth.apiToken);
    data['gastosFixosValorPoupado'] = await _fetchValorPoupadoGastosFixosOrcamentosAtivos(auth.apiToken);
    return data;
  }
}
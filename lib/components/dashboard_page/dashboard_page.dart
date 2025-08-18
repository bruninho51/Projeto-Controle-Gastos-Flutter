import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/common/orcamentos_loading.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/info_state_widget.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/orcamento_detalhes_card.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildDashboardCards(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Define o número de colunas baseado na largura da tela
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : 
                          constraints.maxWidth > 800 ? 3 : 2;
        
        // Define o aspect ratio dos cards
        double childAspectRatio = constraints.maxWidth > 800 ? 1.5 : 0.9;
        
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: childAspectRatio,
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
                  value: formatarValorDynamic(data['valorInicialAtivos']),
                  color: Colors.green[700]!,
                  icon: Icons.attach_money_rounded,
                ),
                OrcamentoDetalhesCard(
                  title: 'Valor Livre',
                  value: formatarValorDynamic(data['valorLivreAtivos']),
                  color: Colors.purple[600]!,
                  icon: Icons.account_balance_wallet_rounded,
                ),
                OrcamentoDetalhesCard(
                  title: 'Valor Atual',
                  value: formatarValorDynamic(data['valorAtualAtivos']),
                  color: Colors.blue[600]!,
                  icon: Icons.pie_chart_rounded,
                ),
                OrcamentoDetalhesCard(
                  title: 'Gastos Fixos',
                  value: formatarValorDynamic(data['gastosFixosAtivos']),
                  color: Colors.red[600]!,
                  icon: Icons.receipt_long_rounded,
                ),
                OrcamentoDetalhesCard(
                  title: 'Gastos Variáveis',
                  value: formatarValorDynamic(data['gastosVariaveisAtivos']),
                  color: Colors.amber[700]!,
                  icon: Icons.trending_up_rounded,
                ),
                OrcamentoDetalhesCard(
                  title: 'Valor Poupado',
                  value: formatarValorDynamic(data['gastosFixosValorPoupado']),
                  color: Colors.indigo[600]!,
                  icon: Icons.savings_rounded,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar() {
    if (!kIsWeb) {
      // AppBar original para mobile
      return AppBar(
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
                Tab(text: 'Métricas Investimentos'),
              ],
            ),
          ),
        ),
      );
    } else {
      // AppBar aprimorada para web
      final auth = Provider.of<AuthProvider>(context);
      return AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            children: [
              Text(
                'Orçamentos App',
                style: TextStyle(
                  color: Colors.indigo[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*_WebNavItem(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    isSelected: true,
                    onTap: () {},
                  ),
                  _WebNavItem(
                    icon: Icons.list_alt,
                    label: 'Orçamentos',
                    onTap: () {},
                  ),
                  _WebNavItem(
                    icon: Icons.trending_up,
                    label: 'Investimentos',
                    onTap: () {},
                  ),
                  _WebNavItem(
                    icon: Icons.settings,
                    label: 'Configurações',
                    onTap: () {},
                  ),*/
                ],
              ),
              const SizedBox(width: 24),
              CircleAvatar(
                backgroundColor: Colors.indigo[100],
                radius: 20, // Tamanho padrão recomendado
                child: ClipOval(
                  child: auth.user?.photoURL != null
                    ? Image.network(
                        auth.user!.photoURL!,
                        width: 40, // Dobro do radius para preencher todo o CircleAvatar
                        height: 40,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.person, color: Colors.indigo[700]);
                        },
                      )
                    : Icon(Icons.person, color: Colors.indigo[700]),
                ),
              )
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.indigo[700],
              unselectedLabelColor: Colors.grey[600],
              indicatorColor: Colors.indigo[700],
              indicatorWeight: 3,
              indicatorPadding: const EdgeInsets.symmetric(horizontal: 24),
              tabs: const [
                Tab(text: 'Métricas Orçamentos'),
                Tab(text: 'Métricas Investimentos'),
              ],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: _buildAppBar(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
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
                constraints: kIsWeb 
                    ? const BoxConstraints(maxWidth: 1400)
                    : null,
                child: _buildDashboardCards(data),
              );
            },
          ),
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 60, color: Colors.amber[600]),
                const SizedBox(height: 20),
                Text(
                  'Módulo em Desenvolvimento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Em breve você poderá acompanhar seus investimentos aqui',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
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

class _WebNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WebNavItem({
    required this.icon,
    required this.label,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  bottom: BorderSide(
                    color: Colors.indigo[700]!,
                    width: 2,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 20,
                color: isSelected ? Colors.indigo[700] : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.indigo[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
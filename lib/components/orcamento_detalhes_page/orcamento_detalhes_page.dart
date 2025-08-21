import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:orcamentos_app/components/form_orcamento_valor_inicial_page/form_orcamento_valor_inicial_page.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/components/common/grafico_gasto_categorias.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/info_state_widget.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/orcamento_titulo.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/orcamento_detalhes_card.dart';
import 'package:orcamentos_app/components/orcamento_detalhes_page/action_button.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';
import 'package:orcamentos_app/components/common/orcamentos_appbar.dart';

class OrcamentoDetalhesPage extends StatefulWidget {
  final int orcamentoId;

  const OrcamentoDetalhesPage({super.key, required this.orcamentoId});

  @override
  _OrcamentoDetalhesPageState createState() => _OrcamentoDetalhesPageState();
}

class _OrcamentoDetalhesPageState extends State<OrcamentoDetalhesPage> {
  late Future<Map<String, dynamic>> _orcamentoDetalhes;
  late Future<Map<String, double>> _spendingData;
  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _loadOrcamentoData();
  }

  void _loadOrcamentoData() {
    _orcamentoDetalhes = _fetchOrcamentoDetalhes(widget.orcamentoId);
    _spendingData = _consolidarTotaisPorCategoria(_auth.apiToken, widget.orcamentoId);
  }

  Future<Map<String, dynamic>> _fetchOrcamentoDetalhes(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      var detalhes = jsonDecode(response.body);
      detalhes['gastos_fixos'] = (await _fetchQtdGastosFixos(orcamentoId)).toString();
      detalhes['gastos_variados'] = (await _fetchQtdGastosVariados(orcamentoId)).toString();

      return detalhes;
    } else {
      throw Exception('Falha ao carregar os detalhes do orçamento');
    }
  }

  Future<int> _fetchQtdGastosFixos(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
      headers: _buildHeaders(),
    );
    return _handleCountResponse(response, 'gastos fixos');
  }

  Future<int> _fetchQtdGastosVariados(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
      headers: _buildHeaders(),
    );
    return _handleCountResponse(response, 'gastos variados');
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_auth.apiToken}',
    };
  }

  int _handleCountResponse(response, String type) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body).length;
    } else {
      throw Exception('Falha ao carregar a quantidade de $type');
    }
  }

  Future<void> _encerrarOrcamento() async {
    await _updateOrcamento({
      'data_encerramento': DateTime.now().toIso8601String(),
    }, 'Orçamento encerrado com sucesso!');
  }

  Future<void> _reativarOrcamento() async {
    await _updateOrcamento({
      'data_encerramento': null,
    }, 'Orçamento reativado com sucesso!');
  }

  Future<void> _renomearOrcamento(String nome) async {
    await _updateOrcamento({
      'nome': nome,
    }, 'Orçamento atualizado com sucesso!');
  }

  Future<void> _updateOrcamento(Map<String, dynamic> data, String successMessage) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/${widget.orcamentoId}',
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: successMessage,
      );
      _loadOrcamentoData();
    } else {
      throw Exception('Falha ao atualizar o orçamento');
    }
  }

  Future<void> _deleteOrcamento() async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'orcamentos/${widget.orcamentoId}',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: 'Orçamento apagado com sucesso!',
      );
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o orçamento');
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

  Future<Map<String, double>> _consolidarTotaisPorCategoria(String apiToken, int orcamentoId) async {
    try {
      final results = await Future.wait([
        fetchGastosFixos(apiToken, orcamentoId),
        fetchGastosVariaveis(apiToken, orcamentoId),
      ]);

      final gastosFixos = results[0];
      final gastosVariaveis = results[1];

      final Map<String, double> totaisPorCategoria = {};

      void processarGasto(dynamic gasto) {
        if (gasto is Map<String, dynamic>) {
          final categoria = gasto['categoriaGasto']['nome']?.toString() ?? 'Sem Categoria';
          final valor = double.tryParse(gasto['valor']?.toString() ?? '0') ?? 0.0;
          
          totaisPorCategoria[categoria] = (totaisPorCategoria[categoria] ?? 0.0) + valor;
        }
      }

      gastosFixos.forEach(processarGasto);
      gastosVariaveis.forEach(processarGasto);

      return totaisPorCategoria;
    } catch (e) {
      print("Erro ao consolidar totais por categoria: $e");
      return {};
    }
  }

  Future<void> _navigateToEditValorInicial(double valorInicial) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormOrcamentoValorInicialPage(
          apiToken: _auth.apiToken,
          orcamentoId: widget.orcamentoId,
          valorInicial: valorInicial,
        ),
      ),
    );
    _loadOrcamentoData();
  }

  Future<void> _navigateToGastosFixos() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastosFixosPage(
          apiToken: _auth.apiToken,
          orcamentoId: widget.orcamentoId,
        ),
      ),
    );
    _loadOrcamentoData();
  }

  Future<void> _navigateToGastosVariados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GastosVariadosPage(
          apiToken: _auth.apiToken,
          orcamentoId: widget.orcamentoId,
        ),
      ),
    );
    _loadOrcamentoData();
  }

  void _showRenameDialog(BuildContext context) {
    final nomeController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Renomear Orçamento'),
          content: TextFormField(
            controller: nomeController,
            decoration: const InputDecoration(
              labelText: 'Novo nome',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira um nome';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nomeController.text.isNotEmpty) {
                  await _renomearOrcamento(nomeController.text);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final auth = Provider.of<AuthProvider>(context);

    return OrcamentosAppBar(
        appTitle: "Detalhes do Orçamento",
        isWeb: kIsWeb,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.indigo[700]),
            onPressed: _loadOrcamentoData,
          ),
        ],
        userAvatar: kIsWeb
            ? CircleAvatar(
                backgroundColor: Colors.indigo[100],
                radius: 20,
                child: auth.user?.photoURL != null
                    ? ClipOval(
                        child: Image.network(
                          auth.user!.photoURL!,
                          width: 40,
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
                        ),
                      )
                    : Icon(Icons.person, color: Colors.indigo[700]),
              )
            : null,
        webNavItems: []
      );
  }

  Widget _buildDashboardCards(Map<String, dynamic> orcamento) {
    final isEncerrado = orcamento['data_encerramento'] != null;
    final dataCriacao = DateTime.parse(orcamento['data_criacao']);
    final valorInicial = double.parse(orcamento['valor_inicial'] ?? '0.0');
    final valorAtual = double.parse(orcamento['valor_atual'] ?? '0.0');
    final valorLivre = double.parse(orcamento['valor_livre'] ?? '0.0');


    final cards = [
      Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Valor Inicial',
              value: formatarValorDouble(valorInicial),
              color: Colors.indigo,
              icon: Icons.account_balance,
              onTap: isEncerrado ? null : () => _navigateToEditValorInicial(valorInicial),
              margin: const EdgeInsets.only(right: 8.0),
            ),
          ),
          Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Valor Atual',
              value: formatarValorDouble(valorAtual),
              color: Colors.teal,
              icon: Icons.bar_chart,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
          ),
          Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Valor Livre',
              value: formatarValorDouble(valorLivre),
              color: Colors.orange,
              icon: Icons.account_balance_wallet,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
          ),
          Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Gastos Fixos',
              value: '${orcamento['gastos_fixos']} itens',
              color: Colors.blue,
              icon: Icons.attach_money,
              onTap: _navigateToGastosFixos,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
          ),
          Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Gastos Variados',
              value: '${orcamento['gastos_variados']} itens',
              color: Colors.purple,
              icon: Icons.shopping_cart,
              onTap: _navigateToGastosVariados,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
            ),
          ),
          Expanded(
            child: OrcamentoDetalhesCard(
              title: 'Criado em',
              value: orcamento['data_criacao'] != null 
                  ? formatarData(dataCriacao)
                  : 'Desconhecida',
              color: Colors.grey,
              icon: Icons.calendar_today,
              margin: const EdgeInsets.only(left: 8.0),
            ),
          ),
    ];

    return (kIsWeb && MediaQuery.of(context).size.width > 800)
      ? SizedBox(
          height: 180,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cards
          ),
        )
      : GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: kIsWeb ? 3 : 2, // 3 colunas na web, 2 no mobile
      crossAxisSpacing: kIsWeb ? 16.0 : 12.0,
      mainAxisSpacing: kIsWeb ? 16.0 : 12.0,
      childAspectRatio: kIsWeb ? 1.5 : 1.2, // Proporção ajustada para web
      children: cards
    );
  }

  Widget _buildGraficoCategorias() {
    return FutureBuilder<Map<String, double>>(
      future: _spendingData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return InfoStateWidget(
            buttonForegroundColor: Colors.red,
            buttonBackgroundColor: Colors.white,
            icon: Icons.error,
            iconColor: Colors.red,
            message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido',
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return InfoStateWidget(
            buttonForegroundColor: Colors.orange,
            buttonBackgroundColor: Colors.white,
            icon: Icons.warning_amber,
            iconColor: Colors.orange,
            message: 'Nenhum dado encontrado',
          );
        }
        return GraficoGastoCategorias(
          categoryData: snapshot.data!,
          height: kIsWeb ? 450 : 400, // Altura maior na web
          barWidth: kIsWeb ? 28 : 22, // Barras mais largas na web
          title: 'Gastos por Categoria',
        );
      },
    );
  }

  Widget _buildActionButtons(bool isEncerrado) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final shouldCenter = constraints.maxWidth > 800;
        final widget = Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (!isEncerrado) ...[
              SizedBox(
                width: shouldCenter ? 400 : null,
                child: ActionButton(
                  text: 'Encerrar Orçamento',
                  icon: Icons.lock_clock,
                  color: Colors.blueGrey,
                  onPressed: () => ConfirmationDialog.confirmAction(
                    context: context,
                    title: 'Confirmar Encerramento',
                    message: 'Você tem certeza que deseja encerrar este orçamento?',
                    actionText: 'Encerrar',
                    action: () async {
                      await _encerrarOrcamento();
                      setState(() {});
                    },
                  ),
                ),
              ),
              SizedBox(height: kIsWeb ? 16 : 12),
              SizedBox(
                width: shouldCenter ? 400 : null,
                child: ActionButton(
                  text: 'Apagar Orçamento',
                  icon: Icons.delete,
                  color: Colors.red,
                  onPressed: () => ConfirmationDialog.confirmAction(
                    context: context,
                    title: 'Confirmar Exclusão',
                    message: 'Você tem certeza que deseja apagar este orçamento?',
                    actionText: 'Apagar',
                    action: () async {
                      await _deleteOrcamento();
                      setState(() {});
                    },
                  ),
                ),
              ),
            ] else
              SizedBox(
                width: shouldCenter ? 400 : null,
                child: ActionButton(
                  text: 'Reativar Orçamento',
                  icon: Icons.lock_open,
                  color: Colors.orange,
                  onPressed: () => ConfirmationDialog.confirmAction(
                    context: context,
                    title: 'Confirmar Reativação',
                    message: 'Você tem certeza que deseja reativar este orçamento?',
                    actionText: 'Reativar',
                    action: () async {
                      await _reativarOrcamento();
                      setState(() {});
                    },
                  ),
                ),
              ),
          ],
        );

        return shouldCenter ? Center(child: widget) : widget;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0), // Padding maior na web
        child: FutureBuilder<Map<String, dynamic>>(
          future: _orcamentoDetalhes,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return InfoStateWidget(
                buttonForegroundColor: Colors.red,
                buttonBackgroundColor: Colors.white,
                icon: Icons.error,
                iconColor: Colors.red,
                message: snapshot.error is String ? snapshot.error as String : 'Erro desconhecido',
                buttonText: 'Tentar novamente',
                onPressed: _loadOrcamentoData,
              );
            } else if (!snapshot.hasData) {
              return InfoStateWidget(
                buttonForegroundColor: Colors.orange,
                buttonBackgroundColor: Colors.white,
                icon: Icons.warning_amber,
                iconColor: Colors.orange,
                message: 'Nenhum dado encontrado',
              );
            }

            final orcamento = snapshot.data!;
            final isEncerrado = orcamento['data_encerramento'] != null;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrcamentoTitulo(
                    nome: orcamento['nome'],
                    isEncerrado: isEncerrado,
                    dataEncerramento: orcamento['data_encerramento'],
                    onEditPressed: isEncerrado 
                      ? null 
                      : () => _showRenameDialog(context),
                  ),
                  SizedBox(height: kIsWeb ? 24 : 20),
                  _buildDashboardCards(orcamento),
                  SizedBox(height: kIsWeb ? 24 : 20),
                  _buildGraficoCategorias(),
                  SizedBox(height: kIsWeb ? 24 : 20),
                  _buildActionButtons(isEncerrado),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
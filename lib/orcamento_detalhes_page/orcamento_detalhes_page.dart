import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:orcamentos_app/form_orcamento_valor_inicial.dart';
import 'package:orcamentos_app/gastos_fixos_page.dart';
import 'package:orcamentos_app/gastos_variados_page/auth_provider.dart';
import 'package:orcamentos_app/gastos_variados_page/formatters.dart';
import 'package:orcamentos_app/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/info_state_widget.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/orcamento_titulo.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/orcamento_detalhes_card.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/action_button.dart';
import 'package:orcamentos_app/http.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/confirmation_dialog.dart';

class OrcamentoDetalhesPage extends StatefulWidget {
  final int orcamentoId;

  const OrcamentoDetalhesPage({super.key, required this.orcamentoId});

  @override
  _OrcamentoDetalhesPageState createState() => _OrcamentoDetalhesPageState();
}

class _OrcamentoDetalhesPageState extends State<OrcamentoDetalhesPage> {
  late Future<Map<String, dynamic>> _orcamentoDetalhes;
  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _loadOrcamentoData();
  }

  void _loadOrcamentoData() {
    _orcamentoDetalhes = _fetchOrcamentoDetalhes(widget.orcamentoId);
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
    await _updateOrcamentoStatus({
      'data_encerramento': DateTime.now().toIso8601String(),
    }, 'Orçamento encerrado com sucesso!');
  }

  Future<void> _reativarOrcamento() async {
    await _updateOrcamentoStatus({
      'data_encerramento': null,
    }, 'Orçamento reativado com sucesso!');
  }

  Future<void> _updateOrcamentoStatus(Map<String, dynamic> data, String successMessage) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/${widget.orcamentoId}',
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento apagado com sucesso!')),
      );
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o orçamento');
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.indigo[700],
      title: const Text('Detalhes do Orçamento', style: TextStyle(color: Colors.white)),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadOrcamentoData,
        ),
      ],
    );
  }

  Widget _buildDashboardCards(Map<String, dynamic> orcamento) {
    final isEncerrado = orcamento['data_encerramento'] != null;
    final dataCriacao = DateTime.parse(orcamento['data_criacao']);
    final valorInicial = double.parse(orcamento['valor_inicial'] ?? '0.0');
    final valorAtual = double.parse(orcamento['valor_atual'] ?? '0.0');
    final valorLivre = double.parse(orcamento['valor_livre'] ?? '0.0');

    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.2,
      children: [
        OrcamentoDetalhesCard(
          title: 'Valor Inicial',
          value: formatarValor(valorInicial),
          color: Colors.indigo,
          icon: Icons.account_balance,
          onTap: isEncerrado ? null : () => _navigateToEditValorInicial(valorInicial),
        ),
        OrcamentoDetalhesCard(
          title: 'Valor Atual',
          value: formatarValor(valorAtual),
          color: Colors.teal,
          icon: Icons.bar_chart,
        ),
        OrcamentoDetalhesCard(
          title: 'Valor Livre',
          value: formatarValor(valorLivre),
          color: Colors.orange,
          icon: Icons.account_balance_wallet,
        ),
        OrcamentoDetalhesCard(
          title: 'Gastos Fixos',
          value: '${orcamento['gastos_fixos']} itens',
          color: Colors.blue,
          icon: Icons.attach_money,
          onTap: _navigateToGastosFixos,
        ),
        OrcamentoDetalhesCard(
          title: 'Gastos Variados',
          value: '${orcamento['gastos_variados']} itens',
          color: Colors.purple,
          icon: Icons.shopping_cart,
          onTap: _navigateToGastosVariados,
        ),
        OrcamentoDetalhesCard(
          title: 'Criado em',
          value: orcamento['data_criacao'] != null 
              ? formatarData(dataCriacao)
              : 'Desconhecida',
          color: Colors.grey,
          icon: Icons.calendar_today,
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isEncerrado) {
    return Column(
      children: [
        if (!isEncerrado) ...[
          ActionButton(
            text: 'Encerrar Orçamento',
            icon: Icons.lock_clock,
            color: Colors.blueGrey,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Encerramento',
              message: 'Você tem certeza que deseja encerrar este orçamento?',
              actionText: 'Encerrar',
              action: _encerrarOrcamento,
            ),
          ),
          const SizedBox(height: 12),
          ActionButton(
            text: 'Apagar Orçamento',
            icon: Icons.delete,
            color: Colors.red,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Exclusão',
              message: 'Você tem certeza que deseja apagar este orçamento?',
              actionText: 'Apagar',
              action: _deleteOrcamento,
            ),
          ),
        ] else
          ActionButton(
            text: 'Reativar Orçamento',
            icon: Icons.lock_open,
            color: Colors.orange,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Reativação',
              message: 'Você tem certeza que deseja reativar este orçamento?',
              actionText: 'Reativar',
              action: _reativarOrcamento,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                        : () => _navigateToEditValorInicial(
                            double.parse(orcamento['valor_inicial'] ?? '0.0')),
                  ),
                  const SizedBox(height: 20),
                  _buildDashboardCards(orcamento),
                  const SizedBox(height: 24),
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
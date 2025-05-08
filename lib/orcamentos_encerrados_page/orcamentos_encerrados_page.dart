import 'package:flutter/material.dart';
import 'package:orcamentos_app/gastos_variados_page/auth_provider.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/orcamento_detalhes_page/info_state_widget.dart';
import 'package:orcamentos_app/orcamentos_encerrados_page/orcamento_encerrado_card.dart';
import 'package:orcamentos_app/refatorado/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:orcamentos_app/orcamento_detalhes_page/orcamento_detalhes_page.dart';
import 'package:orcamentos_app/gastos_variados_page/formatters.dart';

class OrcamentosEncerradosPage extends StatefulWidget {

  const OrcamentosEncerradosPage({super.key});

  @override
  _OrcamentosEncerradosPageState createState() => _OrcamentosEncerradosPageState();
}

class _OrcamentosEncerradosPageState extends State<OrcamentosEncerradosPage> {
  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);
  
  List<dynamic> _orcamentos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
      _fetchApiData();
  }

  Future<void> _fetchApiData() async {
    setState(() => _isLoading = true);

    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'orcamentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_auth.apiToken}',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _orcamentos = (json.decode(response.body) as List)
            .where((orcamento) => orcamento['data_encerramento'] != null)
            .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Falha ao carregar orçamentos: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      OrcamentosSnackBar.error(
        context: context,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  Future<void> _reativarOrcamento(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_auth.apiToken}',
      },
      body: jsonEncode({
        'data_encerramento': null,
      }),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: 'Orçamento reativado com sucesso!',
      );
      _fetchApiData();
    } else {
      throw Exception('Falha ao reativar o orçamento');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        title: const Text('Orçamentos Encerrados', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: _fetchApiData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_orcamentos.isEmpty) {
      return InfoStateWidget(
        icon: Icons.archive,
        iconColor: Colors.grey[400]!,
        message: 'Nenhum orçamento encerrado',
      );
    } else {
      return RefreshIndicator(
        onRefresh: _fetchApiData,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _orcamentos.length,
          itemBuilder: (context, index) => _buildOrcamentoCard(_orcamentos[index]),
        ),
      );
    }
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    final valorAtual = double.tryParse(orcamento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(orcamento['valor_inicial']?.toString() ?? '0') ?? 0;
    final dataEncerramento = orcamento['data_encerramento'] != null 
        ? formatarData(DateTime.parse(orcamento['data_encerramento']))
        : 'Data desconhecida';

    return OrcamentoEncerradoCard(
      id: orcamento['id'],
      nome: orcamento['nome'] ?? 'Sem nome',
      dataEncerramento: dataEncerramento,
      valorAtual: valorAtual,
      valorInicial: valorInicial,
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrcamentoDetalhesPage(
              orcamentoId: orcamento['id'],
            ),
          ),
        );
        await _fetchApiData();
      },
      onReativar: () async {
        await _reativarOrcamento(orcamento['id']);
        await _fetchApiData();
      },
    );
  }

}
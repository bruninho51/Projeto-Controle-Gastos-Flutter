import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/formatters.dart';
import 'package:orcamentos_app/http.dart';
import 'dart:convert';
import 'orcamento_detalhes_page/orcamento_detalhes_page.dart';

class OrcamentosEncerradosPage extends StatefulWidget {
  final String apiToken;

  const OrcamentosEncerradosPage({super.key, required this.apiToken});

  @override
  _OrcamentosEncerradosPageState createState() => _OrcamentosEncerradosPageState();
}

class _OrcamentosEncerradosPageState extends State<OrcamentosEncerradosPage> {
  List<dynamic> _orcamentos = [];
  bool _isLoading = false;
  String _apiToken = '';

  String _formatDate(String isoDate) {
    try {
      DateTime dateTime = DateTime.parse(isoDate);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'Data inválida';
    }
  }

  @override
  void initState() {
    super.initState();
    _apiToken = widget.apiToken;
    if (_apiToken != '') {
      _fetchApiData();
    }
  }

  Future<void> _fetchApiData() async {
    setState(() => _isLoading = true);

    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'orcamentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}')),
      );
    }
  }

  Future<void> _reativarOrcamento(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'orcamentos/$orcamentoId',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
      body: jsonEncode({
        'data_encerramento': null,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento reativado com sucesso!')),
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
    }

    if (_orcamentos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.archive, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum orçamento encerrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchApiData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orcamentos.length,
        itemBuilder: (context, index) => _buildOrcamentoCard(_orcamentos[index]),
      ),
    );
  }

  Widget _buildOrcamentoCard(Map<String, dynamic> orcamento) {
    final valorAtual = double.tryParse(orcamento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(orcamento['valor_inicial']?.toString() ?? '0') ?? 0;
    final dataEncerramento = orcamento['data_encerramento'] != null 
        ? _formatDate(orcamento['data_encerramento'])
        : 'Data desconhecida';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrcamentoDetalhesPage(
                orcamentoId: orcamento['id'],
              ),
            ),
          );
          _fetchApiData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.archive, color: Colors.grey[600], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orcamento['nome'] ?? 'Sem nome',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Encerrado em $dataEncerramento',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValor(valorAtual),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'de ${formatarValor(valorInicial)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saldo final',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    formatarValor(valorInicial - valorAtual),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getSaldoColor(valorInicial, valorAtual),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () => _confirmarReativacao(orcamento['id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo[50],
                  minimumSize: const Size(double.infinity, 40),
                ),
                child: Text(
                  'Reativar Orçamento',
                  style: TextStyle(color: Colors.indigo[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSaldoColor(double valorInicial, double valorAtual) {
    final saldo = valorInicial - valorAtual;
    if (saldo < 0) return Colors.red[700]!;
    if (saldo < valorInicial * 0.3) return Colors.orange[700]!;
    return Colors.green[700]!;
  }

  Future<void> _confirmarReativacao(int orcamentoId) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reativar Orçamento'),
        content: const Text('Deseja realmente reativar este orçamento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reativar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      await _reativarOrcamento(orcamentoId);
    }
  }
}
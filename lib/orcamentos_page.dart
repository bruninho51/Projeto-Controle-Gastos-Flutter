import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import
import 'package:orcamentos_app/categorias_gastos_page.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/orcamentos_encerrados_page.dart';
import 'dart:convert';
import 'orcamento_detalhes_page.dart';
import 'form_orcamento.dart';
import 'formatters.dart';

class OrcamentosPage extends StatefulWidget {
  final String apiToken;

  const OrcamentosPage({super.key, required this.apiToken});

  @override
  _OrcamentosPageState createState() => _OrcamentosPageState();
}

class _OrcamentosPageState extends State<OrcamentosPage> {
  List<dynamic> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false;
  String _apiToken = '';
  final _animationDuration = const Duration(milliseconds: 300);

  // Helper method to format dates
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
            .where((orcamento) => orcamento['data_encerramento'] == null)
            .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load budgets: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _addNewOrcamento() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioOrcamentoPage(apiToken: widget.apiToken),
      ),
    );
    if (result == true) _fetchApiData();
  }

  void _addNewCategoria() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasDeGastoPage(apiToken: widget.apiToken),
      ),
    );
  }

  void _navigateToArquivados() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrcamentosEncerradosPage(apiToken: widget.apiToken),
      ),
    );
    _fetchApiData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.indigo[700],
        title: const Text('Orçamentos', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white),
            tooltip: 'Orçamentos encerrados',
            onPressed: _navigateToArquivados,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: _fetchApiData,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButtons(),
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
            Icon(Icons.account_balance_wallet, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Nenhum orçamento encontrado',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addNewOrcamento,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[700],
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Criar Novo Orçamento', style: TextStyle(color: Colors.white)),
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
    final valorLivre = double.tryParse(orcamento['valor_livre']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(orcamento['valor_inicial']?.toString() ?? '0') ?? 0;
    final progresso = valorInicial > 0 ? ((valorInicial - valorAtual) / valorInicial).clamp(0.0, 1.0) : 0;

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
                apiToken: widget.apiToken,
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
                      color: Colors.indigo[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.account_balance_wallet, color: Colors.indigo[700], size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orcamento['nome'] ?? 'Sem nome',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Criado em ${_formatDate(orcamento['data_criacao'])}',
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getValorColor(valorAtual, valorInicial),
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
              LinearProgressIndicator(
                value: progresso.toDouble(),
                backgroundColor: Colors.grey[200],
                color: _getProgressColor(progresso.toDouble()),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progresso * 100).toStringAsFixed(1)}% utilizado',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  Text(
                    '${formatarValor(valorLivre)} livre',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
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

  Color _getProgressColor(double progress) {
    if (progress > 0.9) return Colors.red[400]!;
    if (progress > 0.7) return Colors.orange[400]!;
    return Colors.green[400]!;
  }

  Color _getValorColor(double valorAtual, double valorInicial) {
    if (valorInicial <= 0) return Colors.grey;
    final percentual = valorAtual / valorInicial;
    if (percentual > 0.9) return Colors.red[700]!;
    if (percentual > 0.7) return Colors.orange[700]!;
    return Colors.green[700]!;
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isMenuOpen)
          AnimatedOpacity(
            opacity: _isMenuOpen ? 1.0 : 0.0,
            duration: _animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: 'btnCategorias',
                onPressed: () {
                  setState(() => _isMenuOpen = false);
                  _addNewCategoria();
                },
                backgroundColor: Colors.orange[600],
                icon: const Icon(Icons.category, color: Colors.white),
                label: const Text('Categorias', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        if (_isMenuOpen)
          AnimatedOpacity(
            opacity: _isMenuOpen ? 1.0 : 0.0,
            duration: _animationDuration,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton.extended(
                heroTag: 'btnOrcamento',
                onPressed: () {
                  setState(() => _isMenuOpen = false);
                  _addNewOrcamento();
                },
                backgroundColor: Colors.indigo[600],
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text('Orçamento', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        FloatingActionButton(
          heroTag: 'btnMain',
          onPressed: () => setState(() => _isMenuOpen = !_isMenuOpen),
          backgroundColor: Colors.indigo[700],
          child: Icon(_isMenuOpen ? Icons.close : Icons.add, color: Colors.white),
        ),
      ],
    );
  }
}
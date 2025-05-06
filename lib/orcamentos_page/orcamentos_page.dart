import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orcamentos_app/categorias_gastos_page.dart';
import 'package:orcamentos_app/form_orcamento.dart';
import 'package:orcamentos_app/http.dart';
import 'package:orcamentos_app/orcamentos_page/orcamento_card.dart';
import 'package:orcamentos_app/orcamentos_page/orcamentos_page_empty_state.dart';
import 'package:orcamentos_app/orcamentos_encerrados_page.dart';
import 'package:orcamentos_app/gastos_variados_page/auth_provider.dart';
import 'package:orcamentos_app/orcamentos_page/orcamentos_fab.dart';

class OrcamentosPage extends StatefulWidget {
  const OrcamentosPage({super.key});

  @override
  State<OrcamentosPage> createState() => OrcamentosPageState();
}

class OrcamentosPageState extends State<OrcamentosPage> {
  List<dynamic> _orcamentos = [];
  bool _isLoading = false;
  bool _isMenuOpen = false;
  final _animationDuration = const Duration(milliseconds: 300);

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchApiData(_auth.apiToken);
      }
    });
  }

  Future<void> _fetchApiData(String apiToken) async {
    setState(() => _isLoading = true);

    try {
      final client = await MyHttpClient.create();
      final response = await client.get(
        'orcamentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
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

  void _addNewOrcamento(String apiToken) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioOrcamentoPage(apiToken: apiToken),
      ),
    );
    if (result == true) _fetchApiData(apiToken);
  }

  void _addNewCategoria(String apiToken) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasDeGastoPage(apiToken: apiToken),
      ),
    );
  }

  void _navigateToArquivados(String apiToken) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrcamentosEncerradosPage(apiToken: apiToken),
      ),
    );
    _fetchApiData(apiToken);
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
            onPressed: () => _navigateToArquivados(_auth.apiToken),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Recarregar',
            onPressed: () => _fetchApiData(_auth.apiToken),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orcamentos.isEmpty
              ? OrcamentosPageEmptyState(
                  onAddOrcamento: () => _addNewOrcamento(_auth.apiToken),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchApiData(_auth.apiToken),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orcamentos.length,
                    itemBuilder: (context, index) => OrcamentoCard(
                      orcamento: _orcamentos[index],
                      apiToken: _auth.apiToken,
                      onRefresh: () => _fetchApiData(_auth.apiToken),
                    ),
                  ),
                ),
      floatingActionButton: OrcamentosFAB(
        isMenuOpen: _isMenuOpen,
        animationDuration: _animationDuration,
        onToggle: () => setState(() => _isMenuOpen = !_isMenuOpen),
        onAddCategoria: () {
          setState(() => _isMenuOpen = false);
          _addNewCategoria(_auth.apiToken);
        },
        onAddOrcamento: () {
          setState(() => _isMenuOpen = false);
          _addNewOrcamento(_auth.apiToken);
        },
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // Adicionado
import 'package:orcamentos_app/components/categorias_investimentos_page/categorias_investimentos_page.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/form_investimento_page/form_investimento_page.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/investimentos_page/investimento_card.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page_empty_state.dart';
import 'package:orcamentos_app/components/orcamentos_encerrados_page/orcamentos_encerrados_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_fab.dart';

class InvestimentosPage extends StatefulWidget {
  const InvestimentosPage({super.key});

  @override
  State<InvestimentosPage> createState() => InvestimentosPageState();
}

class InvestimentosPageState extends State<InvestimentosPage> {
  List<dynamic> _investimentos = [];
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
        'investimentos',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _investimentos = (json.decode(response.body) as List)
              .where((investimento) => investimento['data_inatividade'] == null)
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load savings: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      OrcamentosSnackBar.error(
        context: context,
        message: 'Error: ${e.toString()}',
      );
    }
  }

  void _addNewInvestimento(String apiToken) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FormularioInvestimentoPage(apiToken: apiToken),
      ),
    );
    if (result == true) _fetchApiData(apiToken);
  }

  void _addNewCategoria(String apiToken) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoriasDeInvestimentoPage(apiToken: apiToken),
      ),
    );
  }

  void _navigateToArquivados(String apiToken) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrcamentosEncerradosPage(),
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
        title: const Text('Investimentos', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white),
            tooltip: 'Investimentos encerrados',
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
          : _investimentos.isEmpty
              ? InvestimentosPageEmptyState(
                  onAddInvestimento: () => _addNewInvestimento(_auth.apiToken),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchApiData(_auth.apiToken),
                  child: ListView.builder(
                    padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0), // Ajuste para web
                    itemCount: _investimentos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: kIsWeb ? 16.0 : 12.0, // Espaçamento maior na web
                        left: kIsWeb ? 24.0 : 0,    // Padding lateral na web
                        right: kIsWeb ? 24.0 : 0,
                      ),
                      child: InvestimentoCard(
                        investimento: _investimentos[index],
                        apiToken: _auth.apiToken,
                        onRefresh: () => _fetchApiData(_auth.apiToken),
                      ),
                    ),
                  ),
                ),
      floatingActionButton: InvestimentosFAB(
        isMenuOpen: _isMenuOpen,
        animationDuration: _animationDuration,
        onToggle: () => setState(() => _isMenuOpen = !_isMenuOpen),
        onAddCategoria: () {
          setState(() => _isMenuOpen = false);
          _addNewCategoria(_auth.apiToken);
        },
        onAddInvestimento: () {
          setState(() => _isMenuOpen = false);
          _addNewInvestimento(_auth.apiToken);
        },
      ),
    );
  }
}
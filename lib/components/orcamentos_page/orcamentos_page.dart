import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/categorias_gastos_page/categorias_gastos_page.dart';
import 'package:orcamentos_app/components/form_orcamento_page/form_orcamento_page.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamento_card.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_page_empty_state.dart';
import 'package:orcamentos_app/components/orcamentos_encerrados_page/orcamentos_encerrados_page.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamentos_fab.dart';
import 'package:orcamentos_app/components/common/orcamentos_appbar.dart';

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
      OrcamentosSnackBar.error(
        context: context,
        message: 'Error: ${e.toString()}',
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
        builder: (context) => OrcamentosEncerradosPage(),
      ),
    );
    _fetchApiData(apiToken);
  }

  PreferredSizeWidget _buildAppBar() {
    final auth = Provider.of<AuthProvider>(context);

    return OrcamentosAppBar(
        appTitle: "Orçamentos Ativos",
        isWeb: kIsWeb,
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
        actions: [
          IconButton(
            icon: Icon(Icons.archive, color: kIsWeb ? Colors.indigo[700] : Colors.white),
            tooltip: 'Orçamentos encerrados',
            onPressed: () => _navigateToArquivados(_auth.apiToken),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: kIsWeb ? Colors.indigo[700] : Colors.white),
            tooltip: 'Recarregar',
            onPressed: () => _fetchApiData(_auth.apiToken),
          ),
        ],
        webNavItems: []
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orcamentos.isEmpty
              ? OrcamentosPageEmptyState(
                  onAddOrcamento: () => _addNewOrcamento(_auth.apiToken),
                )
              : RefreshIndicator(
                  onRefresh: () => _fetchApiData(_auth.apiToken),
                  child: ListView.builder(
                    padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                    itemCount: _orcamentos.length,
                    itemBuilder: (context, index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: kIsWeb ? 16.0 : 12.0,
                        left: kIsWeb ? 24.0 : 0,
                        right: kIsWeb ? 24.0 : 0,
                      ),
                      child: OrcamentoCard(
                        orcamento: _orcamentos[index],
                        apiToken: _auth.apiToken,
                        onRefresh: () => _fetchApiData(_auth.apiToken),
                      ),
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
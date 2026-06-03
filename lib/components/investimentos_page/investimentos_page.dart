import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/categorias_investimentos_page/categorias_investimentos_page.dart';
import 'package:orcamentos_app/features/shared/components/orcamentos_snackbar.dart';
import 'package:orcamentos_app/features/shared/components/shared_appbar.dart';
import 'package:orcamentos_app/components/form_investimento_page/form_investimento_page.dart';
import 'package:provider/provider.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/investimentos_page/investimento_card.dart';
import 'package:orcamentos_app/components/investimentos_page/investimentos_page_empty_state.dart';
import 'package:orcamentos_app/features/auth/providers/auth_provider.dart';
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

  static const _gradientColors = [
    Color(0xFF1A237E),
    Color(0xFF283593),
    Color(0xFF3949AB),
  ];

  AuthState get _auth => Provider.of<AuthState>(context, listen: false);
  String get _token => _auth.apiToken!;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fetchApiData(_token);
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
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: SharedAppBar(
        title: 'Investimentos Ativos',
        subtitle: 'Acompanhe seus investimentos',
        mainIcon: Icons.savings_rounded,
        gradientColors: _gradientColors,
        actionButtons: [
          SharedAppBar.headerButton(
            child: const Icon(Icons.refresh_rounded, color: Colors.white),
            onTap: () => _fetchApiData(_token),
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _investimentos.isEmpty
          ? InvestimentosPageEmptyState(
        onAddInvestimento: () => _addNewInvestimento(_token),
      )
          : RefreshIndicator(
        onRefresh: () => _fetchApiData(_token),
        child: ListView.builder(
          padding: EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
          itemCount: _investimentos.length,
          itemBuilder: (context, index) => Padding(
            padding: EdgeInsets.only(
              bottom: kIsWeb ? 16.0 : 12.0,
              left: kIsWeb ? 24.0 : 0,
              right: kIsWeb ? 24.0 : 0,
            ),
            child: InvestimentoCard(
              investimento: _investimentos[index],
              apiToken: _token,
              onRefresh: () => _fetchApiData(_token),
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
          _addNewCategoria(_token);
        },
        onAddInvestimento: () {
          setState(() => _isMenuOpen = false);
          _addNewInvestimento(_token);
        },
      ),
    );
  }
}
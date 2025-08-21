import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/components/orcamentos_page/orcamento_acao_card.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/utils/http.dart';
import '../orcamento_detalhes_page/orcamento_detalhes_page.dart';
import 'dart:convert';

class OrcamentoCard extends StatefulWidget {
  final Map<String, dynamic> orcamento;
  final String apiToken;
  final VoidCallback onRefresh;
  
  const OrcamentoCard({
    super.key,
    required this.orcamento,
    required this.apiToken,
    required this.onRefresh,
  });

  @override
  State<OrcamentoCard> createState() => _OrcamentoCardState();
}

class _OrcamentoCardState extends State<OrcamentoCard> {
  late int _qtdGastosFixos = 0;
  late int _qtdGastosVariados = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGastosCount();
  }

  Future<void> _loadGastosCount() async {
    try {
      final fixos = await fetchQtdGastosFixos(widget.orcamento['id']);
      final variados = await fetchQtdGastosVariados(widget.orcamento['id']);
      
      setState(() {
        _qtdGastosFixos = fixos;
        _qtdGastosVariados = variados;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error as needed
    }
  }

  Future<int> fetchQtdGastosFixos(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    return _handleCountResponse(response, 'gastos fixos');
  }

  Future<int> fetchQtdGastosVariados(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );
    return _handleCountResponse(response, 'gastos variados');
  }

  int _handleCountResponse(response, String type) {
    if (response.statusCode == 200) {
      return jsonDecode(response.body).length;
    } else {
      throw Exception('Falha ao carregar a quantidade de $type');
    }
  }

  Widget _orcamentoCard(BuildContext context) {
    final valorAtual = double.tryParse(widget.orcamento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorLivre = double.tryParse(widget.orcamento['valor_livre']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(widget.orcamento['valor_inicial']?.toString() ?? '0') ?? 0;
    final progresso = valorInicial > 0 ? ((valorInicial - valorAtual) / valorInicial).clamp(0.0, 1.0) : 0;

    return Card(
      elevation: (kIsWeb && MediaQuery.of(context).size.width > 1024) ? 0 : 2,
      margin: EdgeInsets.only(bottom: kIsWeb ? 0 : 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrcamentoDetalhesPage(
                orcamentoId: widget.orcamento['id'],
              ),
            ),
          );
          widget.onRefresh();
        },
        child: Padding(
          padding: EdgeInsets.all(kIsWeb ? 20 : 16),
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
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.indigo[700],
                      size: kIsWeb ? 32 : 28,
                    ),
                  ),
                  SizedBox(width: kIsWeb ? 20 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.orcamento['nome'] ?? 'Sem nome',
                          style: TextStyle(
                            fontSize: kIsWeb ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: kIsWeb ? 6 : 4),
                        Text(
                          'Criado em ${formatarData(DateTime.parse(widget.orcamento['data_criacao']))}',
                          style: TextStyle(
                            fontSize: kIsWeb ? 13 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatarValorDouble(valorAtual),
                        style: TextStyle(
                          fontSize: kIsWeb ? 18 : 16,
                          fontWeight: FontWeight.bold,
                          color: getProgressColor(progresso.toDouble()),
                        ),
                      ),
                      Text(
                        'de ${formatarValorDouble(valorInicial)}',
                        style: TextStyle(
                          fontSize: kIsWeb ? 13 : 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: kIsWeb ? 16 : 12),
              LinearProgressIndicator(
                value: progresso.toDouble(),
                backgroundColor: Colors.grey[200],
                color: getProgressColor(progresso.toDouble()),
                minHeight: kIsWeb ? 8 : 6,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: kIsWeb ? 12 : 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progresso * 100).toStringAsFixed(1)}% utilizado',
                    style: TextStyle(
                      fontSize: kIsWeb ? 13 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${formatarValorDouble(valorLivre)} livre',
                    style: TextStyle(
                      fontSize: kIsWeb ? 16 : 12,
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

  Widget _orcamentoCardWeb(BuildContext context) {
    Future<void> navigateToGastosVariados() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GastosVariadosPage(
            apiToken: widget.apiToken,
            orcamentoId: widget.orcamento['id'],
          ),
        ),
      );
      await _loadGastosCount(); // Refresh counts after returning
    }

    Future<void> navigateToGastosFixos() async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GastosFixosPage(
            apiToken: widget.apiToken,
            orcamentoId: widget.orcamento['id'],
          ),
        ),
      );
      await _loadGastosCount(); // Refresh counts after returning
    }

    return Card(
      elevation: kIsWeb ? 4 : 2,
      margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Card(
          elevation: kIsWeb ? 0 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: 300,
                  child: _orcamentoCard(context),
                ),
              ),
              SizedBox(
                width: 20,
                height: 160,
                child: VerticalDivider(
                  thickness: 1,
                  color: Colors.grey[300],
                  endIndent: 12,
                  indent: 12,
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OrcamentoAcaoCard(
                        title: 'Gastos Fixos',
                        value: '$_qtdGastosFixos itens',
                        color: Colors.blue,
                        icon: Icons.attach_money,
                        onTap: navigateToGastosFixos,
                      ),
              ),
              SizedBox(
                width: 20,
                height: 180,
                child: VerticalDivider(
                  thickness: 1,
                  color: Colors.grey[300],
                  endIndent: 12,
                  indent: 12,
                ),
              ),
              SizedBox(
                width: 200,
                height: 180,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : OrcamentoAcaoCard(
                        title: 'Gastos Variados',
                        value: '$_qtdGastosVariados itens',
                        color: Colors.purple,
                        icon: Icons.shopping_cart,
                        onTap: navigateToGastosVariados,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1024;

    if (kIsWeb && !isSmallScreen) {
      return _orcamentoCardWeb(context);
    } else {
      return _orcamentoCard(context);
    }
  }

  Color getProgressColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.7) return Colors.orange;
    return Colors.red;
  }
}
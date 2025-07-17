import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:orcamentos_app/components/form_gasto_variado_page/form_gasto_variado_page.dart';
import 'package:orcamentos_app/components/gasto_variado_detalhes_page/gasto_variado_detalhes_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_page_empty_state.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gasto_variado_item_card.dart';
import 'package:orcamentos_app/components/gastos_variados_page/filtros_modal.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';

class GastosVariadosPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosVariadosPage({
    super.key, 
    required this.orcamentoId, 
    required this.apiToken
  });

  @override
  _GastosVariadosPageState createState() => _GastosVariadosPageState();
}

class _GastosVariadosPageState extends State<GastosVariadosPage> {
  late Future<List<Map<String, dynamic>>> _gastosVariaveis;
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;
  String _ordenacaoCampo = 'descricao';
  bool _ordenacaoAscendente = true;

  @override
  void initState() {
    super.initState();
    _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
  }

  Future<List<Map<String, dynamic>>> fetchGastosVariaveis(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-variados',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      List<Map<String, dynamic>> gastos = data.map((item) => item as Map<String, dynamic>).toList();
      _aplicarOrdenacao(gastos);
      return gastos;
    } else {
      throw Exception('Falha ao carregar os gastos variados');
    }
  }

  void _aplicarOrdenacao(List<Map<String, dynamic>> gastos) {
    gastos.sort((a, b) {
      int comparacao;
      
      if (_ordenacaoCampo == 'descricao') {
        comparacao = a['descricao'].toString().compareTo(b['descricao'].toString());
      } else {
        final dataA = a['data_pgto'] != null ? DateTime.tryParse(a['data_pgto']) : null;
        final dataB = b['data_pgto'] != null ? DateTime.tryParse(b['data_pgto']) : null;
        
        if (dataA == null && dataB == null) {
          comparacao = 0;
        } else if (dataA == null) {
          comparacao = 1;
        } else if (dataB == null) {
          comparacao = -1;
        } else {
          comparacao = dataA.compareTo(dataB);
        }
      }
      
      return _ordenacaoAscendente ? comparacao : -comparacao;
    });
  }

  List<Map<String, dynamic>> _filtrarGastos(List<Map<String, dynamic>> gastos) {
    return gastos.where((gasto) {
      final descricao = gasto['descricao'].toString().toLowerCase();
      final status = 'Pago';
      final dataPagamento = gasto['data_pgto'];

      final correspondeNome = descricao.contains(_filtroNome.toLowerCase());
      final correspondeStatus = _filtroStatus == null || _filtroStatus == status;
      final correspondeData = _filtroData == null ||
          (dataPagamento != null &&
              DateTime.tryParse(dataPagamento)?.day == _filtroData!.day &&
              DateTime.tryParse(dataPagamento)?.month == _filtroData!.month &&
              DateTime.tryParse(dataPagamento)?.year == _filtroData!.year);

      return correspondeNome && correspondeStatus && correspondeData;
    }).toList();
  }

  Future<Map<String, dynamic>> _getOrcamento(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/${widget.orcamentoId}',
      headers: {
        'Authorization': 'Bearer ${widget.apiToken}',
      },
    );

    if (response.statusCode >= 200 && response.statusCode <= 299) {
      return jsonDecode(response.body);
    } else {
      OrcamentosSnackBar.error(
        context: context,
        message: 'Falha ao carregar os dados do orçamento.',
      );
      return {};
    }
  }

  void _aplicarFiltros(String nome, String? status, DateTime? data, String ordenacaoCampo, bool ordenacaoAscendente) {
    setState(() {
      _filtroNome = nome;
      _filtroStatus = status;
      _filtroData = data;
      _ordenacaoCampo = ordenacaoCampo;
      _ordenacaoAscendente = ordenacaoAscendente;
      _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
    });
  }

  void _limparFiltros() {
    setState(() {
      _filtroNome = '';
      _filtroStatus = null;
      _filtroData = null;
      _ordenacaoCampo = 'descricao';
      _ordenacaoAscendente = true;
      _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.purple[700],
        title: const Text('Gastos Variados', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => FiltrosModal(
              nome: _filtroNome,
              status: _filtroStatus,
              data: _filtroData,
              ordenacaoCampo: _ordenacaoCampo,
              ordenacaoAscendente: _ordenacaoAscendente,
              onAplicarFiltros: _aplicarFiltros,
              onLimparFiltros: _limparFiltros,
            ),
          ),
            color: Colors.white,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gastosVariaveis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const GastosPageEmptyState();
          } else {
            List<Map<String, dynamic>> gastosFiltrados = _filtrarGastos(snapshot.data!);

            if (gastosFiltrados.isEmpty) {
              return GastosPageEmptyState(
                comFiltros: true,
                onLimparFiltros: _limparFiltros,
              );
            }

            return ListView.builder(
              itemCount: gastosFiltrados.length,
              itemBuilder: (context, index) {
                final gasto = gastosFiltrados[index];
                return GastoVariadoItemCard(
                  gasto: gasto,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesGastoVariadoPage(
                          gastoId: gasto['id'],
                          orcamentoId: gasto['orcamento_id'],
                          apiToken: widget.apiToken,
                        ),
                      ),
                    );
                    setState(() {
                      _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
                    });
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FutureBuilder<Map<String, dynamic>>(
        future: _getOrcamento(widget.orcamentoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasError) {
            return const SizedBox.shrink();
          }

          if (snapshot.hasData) {
            final orcamento = snapshot.data!;
            return orcamento['data_encerramento'] == null
                ? FloatingActionButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CriacaoGastoVariadoPage(
                            orcamentoId: widget.orcamentoId,
                            apiToken: widget.apiToken,
                          ),
                        ),
                      );
                      setState(() {
                        _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
                      });
                    },
                    backgroundColor: Colors.purple[700],
                    tooltip: 'Adicionar Gasto Variado',
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : const SizedBox.shrink();
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:orcamentos_app/form_gasto_variado_page.dart';
import 'dart:convert';
import 'package:orcamentos_app/gasto_variado_detalhes_page.dart';
import 'package:orcamentos_app/http.dart';
import 'formatters.dart';

class GastosVariaveisPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosVariaveisPage({super.key, required this.orcamentoId, required this.apiToken});

  @override
  _GastosVariaveisPageState createState() => _GastosVariaveisPageState();
}

class _GastosVariaveisPageState extends State<GastosVariaveisPage> {
  late Future<List<Map<String, dynamic>>> _gastosVariaveis;
  
  // Filtros ativos
  String _filtroNome = '';
  String? _filtroStatus;
  DateTime? _filtroData;

  // Filtros temporários (para o modal)
  String _tempFiltroNome = '';
  String? _tempFiltroStatus;
  DateTime? _tempFiltroData;

  @override
  void initState() {
    super.initState();
    _gastosVariaveis = fetchGastosVariaveis(widget.orcamentoId);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Falha ao carregar os dados do orçamento.')),
      );
      return {};
    }
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
      gastos.sort((a, b) => a['descricao'].toString().compareTo(b['descricao'].toString()));
      return gastos;
    } else {
      throw Exception('Falha ao carregar os gastos variados');
    }
  }

  void _abrirModalFiltros() {
    _tempFiltroNome = _filtroNome;
    _tempFiltroStatus = _filtroStatus;
    _tempFiltroData = _filtroData;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Filtros',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Buscar por nome',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        _tempFiltroNome = value;
                      },
                      controller: TextEditingController(text: _tempFiltroNome),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _tempFiltroStatus,
                      hint: const Text('Filtrar por status'),
                      isExpanded: true,
                      items: ['PAGO', 'NÃO PAGO'].map((status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setModalState(() {
                          _tempFiltroStatus = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _tempFiltroData == null
                                ? 'Filtrar por data de pagamento'
                                : 'Data: ${_tempFiltroData!.day.toString().padLeft(2, '0')}/${_tempFiltroData!.month.toString().padLeft(2, '0')}/${_tempFiltroData!.year}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _tempFiltroData ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _tempFiltroData = picked;
                              });
                            }
                          },
                          child: const Text('Selecionar Data'),
                        ),
                        if (_tempFiltroData != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setModalState(() {
                                _tempFiltroData = null;
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _filtroNome = '';
                              _filtroStatus = null;
                              _filtroData = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Limpar filtros'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filtroNome = _tempFiltroNome;
                              _filtroStatus = _tempFiltroStatus;
                              _filtroData = _tempFiltroData;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Aplicar filtros'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filtrarGastos(List<Map<String, dynamic>> gastos) {
    return gastos.where((gasto) {
      final descricao = gasto['descricao'].toString().toLowerCase();
      final status = gasto['valor'] != null ? 'PAGO' : 'NÃO PAGO';
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
            onPressed: _abrirModalFiltros,
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
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum gasto variado encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            List<Map<String, dynamic>> gastosFiltrados = _filtrarGastos(snapshot.data!);

            if (gastosFiltrados.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt_off, size: 50, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'Nenhum gasto encontrado com os filtros aplicados',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _filtroNome = '';
                          _filtroStatus = null;
                          _filtroData = null;
                        });
                      },
                      child: const Text('Limpar filtros'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: gastosFiltrados.length,
              itemBuilder: (context, index) {
                final gasto = gastosFiltrados[index];
                final isPago = gasto['valor'] != null;
                final dataPagamento = gasto['data_pgto'] != null 
                    ? DateTime.tryParse(gasto['data_pgto'])
                    : null;
                final valor = gasto['valor'] ?? 0.0;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Card(
                    elevation: 2.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: isPago 
                                  ? Colors.purple[50] 
                                  : Colors.deepOrange[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isPago ? Icons.shopping_bag : Icons.shopping_cart,
                              color: isPago ? Colors.purple : Colors.deepOrange,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto['descricao'],
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatarValor(valor),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (dataPagamento != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Pago em ${dataPagamento.day.toString().padLeft(2, '0')}/${dataPagamento.month.toString().padLeft(2, '0')}/${dataPagamento.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isPago
                                      ? Colors.purple[50]
                                      : Colors.deepOrange[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPago ? 'PAGO' : 'PENDENTE',
                                  style: TextStyle(
                                    color: isPago 
                                        ? Colors.purple[800] 
                                        : Colors.deepOrange[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (isPago)
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.purple[800],
                                  size: 20,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
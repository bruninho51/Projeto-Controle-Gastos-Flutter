import 'package:flutter/material.dart';
import 'package:orcamentos_app/form_gasto_fixo_page.dart';
import 'package:orcamentos_app/gasto_fixo_detalhes_page.dart';
import 'dart:convert';
import 'package:orcamentos_app/http.dart';
import 'formatters.dart';

class GastosFixosPage extends StatefulWidget {
  final int orcamentoId;
  final String apiToken;

  const GastosFixosPage({super.key, required this.orcamentoId, required this.apiToken});

  @override
  _GastosFixosPageState createState() => _GastosFixosPageState();
}

class _GastosFixosPageState extends State<GastosFixosPage> {
  late Future<List<Map<String, dynamic>>> _gastosFixos;

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
    _gastosFixos = fetchGastosFixos(widget.orcamentoId);
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
        const SnackBar(content: Text('Falha ao carregar os dados do gasto.')),
      );
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchGastosFixos(int orcamentoId) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'orcamentos/$orcamentoId/gastos-fixos',
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
      throw Exception('Falha ao carregar os gastos fixos');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[50],
        title: const Text('Gastos Fixos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _abrirModalFiltros,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _gastosFixos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhum gasto fixo encontrado'));
          } else {
            List<Map<String, dynamic>> gastosFixos = snapshot.data!;

            final gastosFiltrados = gastosFixos.where((gasto) {
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

            if (gastosFiltrados.isEmpty) {
              return const Center(child: Text('Nenhum gasto encontrado com os filtros aplicados.'));
            }

            return ListView.builder(
              itemCount: gastosFiltrados.length,
              itemBuilder: (context, index) {
                final gasto = gastosFiltrados[index];

                return GestureDetector(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalhesGastoFixoPage(
                          gastoId: gasto['id'],
                          orcamentoId: gasto['orcamento_id'],
                          apiToken: widget.apiToken,
                        ),
                      ),
                    );

                    setState(() {
                      _gastosFixos = fetchGastosFixos(widget.orcamentoId);
                    });
                  },
                  child: Card(
                    elevation: 5.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.attach_money,
                              color: Colors.blue,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gasto['descricao'],
                                  style: const TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(formatarValor(gasto['previsto'])),
                              ],
                            ),
                          ),
                          Text(
                            gasto['valor'] != null ? 'PAGO' : 'NÃO PAGO',
                            style: TextStyle(
                              color: gasto['valor'] != null ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
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
            return const CircularProgressIndicator();
          }

          if (snapshot.hasError) {
            return const Icon(Icons.error);
          }

          if (snapshot.hasData) {
            final orcamento = snapshot.data!;
            return orcamento['data_encerramento'] == null
                ? FloatingActionButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CriacaoGastoFixoPage(
                            orcamentoId: widget.orcamentoId,
                            apiToken: widget.apiToken,
                          ),
                        ),
                      );

                      setState(() {
                        _gastosFixos = fetchGastosFixos(widget.orcamentoId);
                      });
                    },
                    tooltip: 'Adicionar Gasto Fixo',
                    child: const Icon(Icons.add),
                  )
                : Container();
          }

          return Container();
        },
      ),
    );
  }
}

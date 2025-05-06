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

  // Ordenação
  String _ordenacaoCampo = 'descricao'; // 'descricao' ou 'data_pgto'
  bool _ordenacaoAscendente = true;

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
      _aplicarOrdenacao(gastos);
      return gastos;
    } else {
      throw Exception('Falha ao carregar os gastos fixos');
    }
  }

  void _aplicarOrdenacao(List<Map<String, dynamic>> gastos) {
    gastos.sort((a, b) {
      int comparacao;
      
      if (_ordenacaoCampo == 'descricao') {
        comparacao = a['descricao'].toString().compareTo(b['descricao'].toString());
      } else { // 'data_pgto'
        final dataA = a['data_pgto'] != null ? DateTime.tryParse(a['data_pgto']) : null;
        final dataB = b['data_pgto'] != null ? DateTime.tryParse(b['data_pgto']) : null;
        
        if (dataA == null && dataB == null) {
          comparacao = 0;
        } else if (dataA == null) {
          comparacao = 1; // Itens sem data vão para o final
        } else if (dataB == null) {
          comparacao = -1; // Itens sem data vão para o final
        } else {
          comparacao = dataA.compareTo(dataB);
        }
      }
      
      return _ordenacaoAscendente ? comparacao : -comparacao;
    });
  }

  void _alternarOrdenacao(String campo, StateSetter setModalState) {
    setModalState(() {
      if (_ordenacaoCampo == campo) {
        _ordenacaoAscendente = !_ordenacaoAscendente;
      } else {
        _ordenacaoCampo = campo;
        _ordenacaoAscendente = true;
      }
    });
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
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Ordenação',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('Nome'),
                            trailing: _ordenacaoCampo == 'descricao'
                                ? Icon(
                                    _ordenacaoAscendente
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.blue,
                                  )
                                : null,
                            onTap: () => _alternarOrdenacao('descricao', setModalState),
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('Data'),
                            trailing: _ordenacaoCampo == 'data_pgto'
                                ? Icon(
                                    _ordenacaoAscendente
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward,
                                    color: Colors.blue,
                                  )
                                : null,
                            onTap: () => _alternarOrdenacao('data_pgto', setModalState),
                          ),
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
                              _gastosFixos = fetchGastosFixos(widget.orcamentoId);
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        title: const Text('Gastos Fixos', style: TextStyle(color: Colors.white)),
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
        future: _gastosFixos,
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
                  Icon(Icons.money_off, size: 50, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'Nenhum gasto fixo encontrado',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
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
                  child: Container(
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
                                    ? Colors.green[50] 
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPago ? Icons.check_circle : Icons.pending,
                                color: isPago ? Colors.green : Colors.orange,
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
                                    formatarValor(gasto['previsto']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
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
                                        ? Colors.green[50]
                                        : Colors.orange[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    isPago ? 'PAGO' : 'PENDENTE',
                                    style: TextStyle(
                                      color: isPago 
                                          ? Colors.green[800] 
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (isPago && gasto['valor'] != null)
                                  Text(
                                    formatarValor(gasto['valor']),
                                    style: TextStyle(
                                      color: Colors.green[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
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
                    backgroundColor: Colors.blue[700],
                    tooltip: 'Adicionar Gasto Fixo',
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
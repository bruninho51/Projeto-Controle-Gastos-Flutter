import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/components/common/confirmation_dialog.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';
import 'package:orcamentos_app/components/investimento_detalhes_page/investimento_detalhes_fab.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:orcamentos_app/providers/auth_provider.dart';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/investimento_detalhes_page/action_button.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class InvestimentoDetalhesPage extends StatefulWidget {
  final int investimentoId;

  const InvestimentoDetalhesPage({
    super.key,
    required this.investimentoId,
  });

  @override
  _InvestimentoDetalhesPageState createState() => _InvestimentoDetalhesPageState();
}

class _InvestimentoDetalhesPageState extends State<InvestimentoDetalhesPage> {
  late Future<Map<String, dynamic>> _dadosInvestimento;
  late Future<List<Map<String, dynamic>>> _dadosTimeline;
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> _groupedData = [];
  bool _isLoading = false;

  AuthProvider get _auth => Provider.of<AuthProvider>(context, listen: false);

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$ ',
    decimalDigits: 2,
  );

  String _formatarValor(String value) {
    String cleanedValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanedValue.isNotEmpty) {
      double parsedValue = double.tryParse(cleanedValue) ?? 0.0;
      parsedValue = parsedValue / 100;
      return formatador.format(parsedValue);
    }
    return '';
  }

  Future<Map<String, dynamic>> _buscarInvestimento(String apiToken) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'investimentos/${widget.investimentoId}',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar investimento');
    }
  }

  Future<List<Map<String, dynamic>>> _buscarTimeline(String apiToken, Map<String, dynamic> investimento) async {
    final client = await MyHttpClient.create();
    final response = await client.get(
      'investimentos/${widget.investimentoId}/linha-do-tempo',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiToken',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      data.add({ 'data_registro': investimento['data_criacao'], 'valor': investimento['valor_inicial'] });
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Falha ao carregar timeline');
    }
  }

  Map<String, String> _buildHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${_auth.apiToken}',
    };
  }

  Future<void> _updateInvestimento(Map<String, dynamic> data, String successMessage) async {
    final client = await MyHttpClient.create();
    final response = await client.patch(
      'investimentos/${widget.investimentoId}',
      headers: _buildHeaders(),
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: successMessage,
      );
    } else {
      throw Exception('Falha ao atualizar o investimento');
    }
  }

  Future<void> _encerrarInvestimento() async {
    await _updateInvestimento({
      'data_inatividade': DateTime.now().toIso8601String(),
    }, 'Investimento encerrado com sucesso!');
  }

  Future<void> _deleteInvestimento() async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'investimentos/${widget.investimentoId}',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: 'Investimento apagado com sucesso!',
      );
      Navigator.pop(context, true);
    } else {
      throw Exception('Falha ao apagar o investimento');
    }
  }

  Future<void> _deleteItemLinhaDoTempo(int linhaDoTempoId) async {
    final client = await MyHttpClient.create();
    final response = await client.delete(
      'investimentos/${widget.investimentoId}/linha-do-tempo/$linhaDoTempoId',
      headers: _buildHeaders(),
    );

    if (response.statusCode == 200) {
      OrcamentosSnackBar.success(
        context: context,
        message: 'Entrada apagada com sucesso!',
      );
    } else {
      throw Exception('Falha ao apagar a entrada na linha do tempo');
    }
  }

  Future<void> _reativarInvestimento() async {
    await _updateInvestimento({
      'data_inatividade': null,
    }, 'Investimento reativado com sucesso!');
  }

  String _converterParaFormatoNumerico(String valorFormatado) {
    return valorFormatado
        .replaceAll('R\$', '')
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
  }

  Future<void> _createNewItemLinhaDoTempo(DateTime selectedDate, String valor) async {
    final client = await MyHttpClient.create();
    final response = await client.post(
      'investimentos/${widget.investimentoId}/linha-do-tempo',
      headers: _buildHeaders(),
      body: jsonEncode({
        'data_registro': selectedDate.toIso8601String(),
        'valor': valor,
      }),
    );

    if (response.statusCode == 201) {
      OrcamentosSnackBar.success(
        context: context,
        message: 'Investimento atualizado com sucesso!',
      );
    } else {
      print(response.statusCode);
      print(response.body);
      throw Exception('Falha ao atualizar o investimento');
    }
  }

void _showCreateItemLinhaDoTempoDialog() {
  final valorController = TextEditingController();
  final dataController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime? selectedDate;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Adicionar Entrada na Linha do Tempo'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: dataController,
                    decoration: InputDecoration(
                      labelText: 'Data',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    readOnly: true,
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (date != null) {
                        selectedDate = date;
                        dataController.text = 
                          DateFormat('dd/MM/yyyy').format(date);
                      }
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Selecione uma data';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: valorController,
                    decoration: const InputDecoration(
                      labelText: 'Valor',
                      prefixIcon: Icon(Icons.attach_money),
                      border: OutlineInputBorder(),
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      String formattedValue = _formatarValor(value);
                      valorController.value = TextEditingValue(
                        text: formattedValue,
                        selection: TextSelection.collapsed(
                          offset: formattedValue.length,
                        ),
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, insira o valor';
                      }
                      String cleanedValue = value.replaceAll(
                        RegExp(r'[^0-9]'), '');
                      if (double.tryParse(cleanedValue) == null || 
                          cleanedValue.length < 2) {
                        return 'Por favor, insira um valor válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate() && selectedDate != null) {
                
                await _createNewItemLinhaDoTempo(
                  selectedDate!, 
                  _converterParaFormatoNumerico(valorController.text)
                );
                _carregarDados();
                
                Navigator.of(context).pop();
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      );
    },
  );
}

  Future<void> _carregarDados() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    
    try {
      final investimento = await _buscarInvestimento(_auth.apiToken);
      final timeline = await _buscarTimeline(_auth.apiToken, investimento);
      final groupedData = _agruparPorMes(timeline);
      
      setState(() {
        _dadosInvestimento = Future.value(investimento);
        _dadosTimeline = Future.value(timeline);
        _groupedData = groupedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: ${e.toString()}')),
      );
    }
  }

  List<Map<String, dynamic>> _agruparPorMes(List<Map<String, dynamic>> timeline) {
    final Map<String, Map<String, dynamic>> meses = {};
    final formatadorMes = DateFormat('MMMM yyyy', 'pt_BR');

    // Ordena a timeline por data (mais antigo para mais recente)
    timeline.sort((a, b) {
      return DateTime.parse(a['data_registro']).compareTo(DateTime.parse(b['data_registro']));
    });

    for (var entry in timeline) {
      final date = DateTime.parse(entry['data_registro']);
      final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      final monthName = formatadorMes.format(date);

      if (!meses.containsKey(monthKey)) {
        meses[monthKey] = {
          'month': monthName,
          'monthKey': monthKey,
          'startValue': double.parse(entry['valor']),
          'endValue': double.parse(entry['valor']),
          'minValue': double.parse(entry['valor']),
          'maxValue': double.parse(entry['valor']),
          'data': [entry],
        };
      } else {
        final currentValue = double.parse(entry['valor']);
        meses[monthKey]!['endValue'] = currentValue;
        meses[monthKey]!['minValue'] = min(meses[monthKey]!['minValue'] as double, currentValue);
        meses[monthKey]!['maxValue'] = max(meses[monthKey]!['maxValue'] as double, currentValue);
        meses[monthKey]!['data'].add(entry);
      }
    }

    // Ordena os meses do mais antigo para o mais recente
    final sortedKeys = meses.keys.toList()
      ..sort((a, b) => a.compareTo(b));
    
    return sortedKeys.map((key) => meses[key]!).toList();
  }

  DateTime parseChartDate(dynamic value) {
    if (value is DateTime) {
      return value;
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is String) {
      return DateTime.parse(value);
    }
    throw ArgumentError('Tipo de data não suportado: ${value.runtimeType}');
  }

  Widget _buildActionButtons(bool isEncerrado) {
    return Column(
      children: [
        if (!isEncerrado) ...[
          ActionButton(
            text: 'Encerrar Investimento',
            icon: Icons.lock_clock,
            color: Colors.blueGrey,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Encerramento',
              message: 'Você tem certeza que deseja encerrar este investimento?',
              actionText: 'Encerrar',
              action: () async {
                await _encerrarInvestimento();
                _carregarDados();
              },
            ),
          ),
          const SizedBox(height: 12),
          ActionButton(
            text: 'Apagar Investimento',
            icon: Icons.delete,
            color: Colors.red,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Exclusão',
              message: 'Você tem certeza que deseja apagar este investimento?',
              actionText: 'Apagar',
              action: () async {
                await _deleteInvestimento();
                setState(() {});
              },
            ),
          ),
        ] else
          ActionButton(
            text: 'Reativar Investimento',
            icon: Icons.lock_open,
            color: Colors.orange,
            onPressed: () => ConfirmationDialog.confirmAction(
              context: context,
              title: 'Confirmar Reativação',
              message: 'Você tem certeza que deseja reativar este investimento?',
              actionText: 'Reativar',
              action: () async {
                await _reativarInvestimento();
                _carregarDados();
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTimelineDetail(Map<String, dynamic> monthData) {
    // Ordenar os lançamentos por data (mais recente primeiro)
    final lancamentos = (monthData['data'] as List<Map<String, dynamic>>)
      ..sort((a, b) => DateTime.parse(b['data_registro']).compareTo(DateTime.parse(a['data_registro'])));

    return Container(
      height: 150, // Altura fixa para a lista
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Lançamentos do Mês',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: lancamentos.length,
                itemBuilder: (context, index) {
                  final lancamento = lancamentos[index];
                  final data = DateTime.parse(lancamento['data_registro']);
                  final valor = double.parse(lancamento['valor'].toString());
                  final formatadorData = DateFormat('dd/MM/yyyy');
                  final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

                  ListTile buildListTile() {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      title: Text(formatadorData.format(data)),
                      trailing: Text(
                        formatadorMoeda.format(valor),
                        style: TextStyle(
                          color: valor >= 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }

                  return lancamento['id'] != null
                  ? Dismissible(
                      key: Key(lancamento['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        final bool confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirmar Remoção'),
                            content: const Text('Você tem certeza que deseja apagar esta entrada?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Apagar'),
                              ),
                            ],
                          ),
                        );
                        return confirm;
                      },
                      onDismissed: (direction) async {
                        await _deleteItemLinhaDoTempo(lancamento['id']);
                        _carregarDados();
                      },
                      child: buildListTile(),
                    )
                  : buildListTile();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthChart(Map<String, dynamic> monthData) {
    final entries = (monthData['data'] as List<Map<String, dynamic>>)
        .map((e) => TimeSeriesData(
              DateTime.parse(e['data_registro']),
              double.parse(e['valor']),
            ))
        .toList();

    return Column(
      children: [
        Text(
          capitalizeWords(monthData['month']),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 310,
          child: SfCartesianChart(
            margin: EdgeInsets.zero,
            plotAreaBorderWidth: 0,
            primaryXAxis: DateTimeAxis(
              minimum: DateTime(entries.first.date.year, entries.first.date.month, 1),
              maximum: DateTime(entries.first.date.year, entries.first.date.month + 1, 0),
              interval: 1,
              desiredIntervals: 10,
              autoScrollingDelta: 1,
              intervalType: DateTimeIntervalType.days,
              dateFormat: DateFormat('dd/MM'),
              labelRotation: 45,
              edgeLabelPlacement: EdgeLabelPlacement.shift,
              rangePadding: ChartRangePadding.additional,
              //visibleMinimum: DateTime(entries.first.date.year, entries.first.date.month, 1).subtract(const Duration(hours: 6)),
              //visibleMaximum: DateTime(entries.first.date.year, entries.first.date.month + 1, 0).add(const Duration(hours: 6)),
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                try {
                  final date = parseChartDate(details.value);
                  final hasData = entries.any((e) => 
                    e.date.year == date.year &&
                    e.date.month == date.month && 
                    e.date.day == date.day
                  );

                  final dayMonth = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
                  
                  return ChartAxisLabel(
                    dayMonth,
                    TextStyle(
                      fontSize: 8,
                      color: hasData ? Colors.blue : Colors.grey,
                      fontWeight: hasData ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                } catch (e) {
                  return ChartAxisLabel(
                    'Err',
                    const TextStyle(color: Colors.red),
                  );
                }
              },
              majorGridLines: const MajorGridLines(width: 0),
              axisLine: const AxisLine(width: 1, color: Colors.grey),
            ),
            primaryYAxis: NumericAxis(
              numberFormat: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$'),
              axisLine: const AxisLine(width: 0),
              majorTickLines: const MajorTickLines(size: 0),
              rangePadding: ChartRangePadding.additional,
            ),
            series: <CartesianSeries>[
              LineSeries<TimeSeriesData, DateTime>(
                dataSource: entries,
                xValueMapper: (TimeSeriesData data, _) => data.date,
                yValueMapper: (TimeSeriesData data, _) => data.value,        
                markerSettings: const MarkerSettings(
                  isVisible: true,
                  shape: DataMarkerType.circle,
                  width: 5,
                  height: 5,
                  borderWidth: 2,
                  borderColor: Colors.blue,
                  color: Colors.blue,
                ),
                dataLabelSettings: DataLabelSettings(
                  isVisible: false,
                  labelAlignment: ChartDataLabelAlignment.auto,
                  builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                    final timeData = data as TimeSeriesData;
                    return Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(timeData.value),
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
                animationDuration: 0,
              ),
            ],
            tooltipBehavior: TooltipBehavior(
              enable: true,
              builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
                final timeData = data as TimeSeriesData;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(timeData.date),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(timeData.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
 
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: InvestimentoDetalhesFAB(
        onAddItemLinhaDoTempo: () {
          _showCreateItemLinhaDoTempoDialog();
        },
      ),
      appBar: AppBar(
        title: const Text('Detalhes do Investimento'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _carregarDados,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: Future.wait([_dadosInvestimento, _dadosTimeline]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Erro: ${snapshot.error.toString()}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _carregarDados,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final investimento = snapshot.data![0] as Map<String, dynamic>;
                final formatadorMoeda = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
                final formatadorData = DateFormat('dd/MM/yyyy');
                
                final formatadorPercentual = NumberFormat.percentPattern('pt_BR');
                formatadorPercentual.minimumFractionDigits = 2;
                formatadorPercentual.maximumFractionDigits = 2;

                final valorInicial = double.parse(investimento['valor_inicial']);
                final valorAtual = double.parse(investimento['valor_atual']);
                final dataCriacao = DateTime.parse(investimento['data_criacao']);

                // Calcular crescimento
                final crescimentoTotal = ((valorAtual - valorInicial) / valorInicial) * 100;

                // Calcular valorização
                final valorizacao = valorAtual - valorInicial;

                // Obter dados do investimento e timeline
                final timeline = snapshot.data![1] as List<Map<String, dynamic>>;

                // Definir o mês atual
                final agora = DateTime.now();

                // Encontrar o primeiro valor do mês
                double? valorInicialMes;
                final primeiroDiaMes = DateTime(agora.year, agora.month, 1);

                // Procurar o último registro antes do mês atual
                for (var entry in timeline) {
                  final data = DateTime.parse(entry['data_registro']);
                  if (data.isBefore(primeiroDiaMes)) {
                    valorInicialMes = double.parse(entry['valor'].toString());
                  }
                }

                // Se não encontrou, usar o primeiro registro do mês
                if (valorInicialMes == null && timeline.isNotEmpty) {
                  final primeiroRegistroMes = timeline.firstWhere(
                    (entry) => DateTime.parse(entry['data_registro']).month == agora.month,
                    orElse: () => timeline.first,
                  );
                  valorInicialMes = double.parse(primeiroRegistroMes['valor'].toString());
                }

                // Calcular crescimento do mês atual
                double crescimentoMes = 0;
                if (valorInicialMes != null && valorInicialMes != 0) {
                  crescimentoMes = ((valorAtual - valorInicialMes) / valorInicialMes) * 100;
                }

                final isEncerrado = investimento['data_inatividade'] != null;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investimento['nome'],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                investimento['descricao'],
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Valor inicial',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        formatadorMoeda.format(valorInicial),
                                        style: Theme.of(context).textTheme.bodyLarge,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Valor atual',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        formatadorMoeda.format(valorAtual),
                                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                              color: valorAtual >= valorInicial ? Colors.green : Colors.red,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Criado em: ${formatadorData.format(dataCriacao)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Estatísticas
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rentabilidade',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildStatCard(
                                    'Total',
                                    formatadorPercentual.format(crescimentoTotal / 100),
                                    crescimentoTotal >= 0 ? Colors.green : Colors.red,
                                  ),
                                  _buildStatCard(
                                    'Mensal',
                                    formatadorPercentual.format(crescimentoMes / 100),
                                    crescimentoMes >= 0 ? Colors.green : Colors.red,
                                  ),
                                  _buildStatCard(
                                    'Valorização',
                                    formatadorMoeda.format(valorizacao),
                                    valorizacao >= 0 ? Colors.green : Colors.red,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Gráfico por mês
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Evolução Mensal',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                height: 550,
                                child: PageView.builder(
                                  controller: _pageController,
                                  itemCount: _groupedData.length,
                                  onPageChanged: (index) {
                                    setState(() => _currentPage = index);
                                  },
                                  itemBuilder: (context, index) {
                                    return Column(
                                      children: [
                                        _buildMonthChart(_groupedData[index]),
                                        _buildTimelineDetail(_groupedData[index])
                                      ],
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(
                                  _groupedData.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _currentPage == index ? Colors.blue : Colors.grey[300],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      _buildActionButtons(isEncerrado)
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class TimeSeriesData {
  final DateTime date;
  final double value;

  TimeSeriesData(this.date, this.value);
}
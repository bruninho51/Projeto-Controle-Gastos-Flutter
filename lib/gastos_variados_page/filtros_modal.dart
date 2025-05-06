import 'package:flutter/material.dart';
import 'package:orcamentos_app/gastos_variados_page/formatters.dart';

class FiltrosModal extends StatefulWidget {
  final String nome;
  final String? status;
  final DateTime? data;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;
  final Function(String, String?, DateTime?, String, bool) onAplicarFiltros;
  final VoidCallback onLimparFiltros;

  const FiltrosModal({
    super.key,
    required this.nome,
    required this.status,
    required this.data,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.onAplicarFiltros,
    required this.onLimparFiltros,
  });

  @override
  State<FiltrosModal> createState() => _FiltrosModalState();
}

class _FiltrosModalState extends State<FiltrosModal> {
  late String _tempNome;
  late String? _tempStatus;
  late DateTime? _tempData;
  late String _tempOrdenacaoCampo;
  late bool _tempOrdenacaoAscendente;

  @override
  void initState() {
    super.initState();
    _tempNome = widget.nome;
    _tempStatus = widget.status;
    _tempData = widget.data;
    _tempOrdenacaoCampo = widget.ordenacaoCampo;
    _tempOrdenacaoAscendente = widget.ordenacaoAscendente;
  }

  void _alternarOrdenacao(String campo) {
    setState(() {
      _tempOrdenacaoAscendente = _tempOrdenacaoCampo == campo ? !_tempOrdenacaoAscendente : true;
      _tempOrdenacaoCampo = campo;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              onChanged: (value) => _tempNome = value,
              controller: TextEditingController(text: _tempNome),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _tempStatus,
              hint: const Text('Filtrar por status'),
              isExpanded: true,
              items: [
                DropdownMenuItem<String>(
                  value: 'PAGO',
                  child: const Text('Pago'),
                ),
                DropdownMenuItem<String>(
                  value: 'NÃO PAGO',
                  child: const Text('Não pago'),
                ),
              ],
              onChanged: (value) => _tempStatus = value,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tempData == null 
                      ? 'Filtrar por data de pagamento' 
                      : 'Data: ${formatarData(_tempData!)}'
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _tempData ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _tempData = picked;
                      });
                    }
                  },
                  child: const Text('Selecionar Data'),
                ),
                if (_tempData != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _tempData = null),
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
                    trailing: _tempOrdenacaoCampo == 'descricao'
                        ? Icon(
                            _tempOrdenacaoAscendente
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.purple,
                          )
                        : null,
                    onTap: () => _alternarOrdenacao('descricao'),
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: const Text('Data'),
                    trailing: _tempOrdenacaoCampo == 'data_pgto'
                        ? Icon(
                            _tempOrdenacaoAscendente
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: Colors.purple,
                          )
                        : null,
                    onTap: () => _alternarOrdenacao('data_pgto'),
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
                    widget.onLimparFiltros();
                    Navigator.pop(context);
                  },
                  child: const Text('Limpar filtros'),
                ),
                ElevatedButton(
                  onPressed: () {
                    widget.onAplicarFiltros(
                      _tempNome,
                      _tempStatus,
                      _tempData,
                      _tempOrdenacaoCampo,
                      _tempOrdenacaoAscendente,
                    );
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
  }
}
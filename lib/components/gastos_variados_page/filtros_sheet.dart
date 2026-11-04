import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// Modal de filtros — mesmo tema dos gastos fixos
// ═══════════════════════════════════════════════════════════════════════════════
class FiltrosSheet extends StatefulWidget {
  final String filtroNome;
  final DateTime? filtroData;
  final int? filtroCategoriaId;
  final List<CategoriaGastoResponseDto> categorias;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;
  final void Function(
          String nome, DateTime? data, String campo, bool asc, int? categoriaId)
      onAplicar;
  final VoidCallback onLimpar;

  const FiltrosSheet({
    required this.filtroNome,
    required this.filtroData,
    required this.filtroCategoriaId,
    required this.categorias,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  State<FiltrosSheet> createState() => FiltrosSheetState();
}

class FiltrosSheetState extends State<FiltrosSheet> {
  late TextEditingController _nomeCtrl;
  DateTime? _data;
  int? _categoriaId;
  late String _campo;
  late bool _asc;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.filtroNome);
    _data = widget.filtroData;
    _categoriaId = widget.filtroCategoriaId;
    _campo = widget.ordenacaoCampo;
    _asc = widget.ordenacaoAscendente;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF6A1B9A);
    const purpleLight = Color(0xFF7B1FA2);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list_rounded,
                    color: purple, size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Filtros',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36))),
            ]),
            const SizedBox(height: 20),

            // Campo de nome
            TextField(
              controller: _nomeCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por descrição…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: purpleLight, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: purpleLight, width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),

            // Filtro por data
            Text('Data de pagamento',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _data ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                              colorScheme:
                                  const ColorScheme.light(primary: purple)),
                          child: child!,
                        ),
                      );
                      if (picked != null) setState(() => _data = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _data != null ? purple : Colors.grey[200]!,
                            width: _data != null ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_rounded,
                              size: 16,
                              color: _data != null ? purple : Colors.grey[400]),
                          const SizedBox(width: 10),
                          Text(
                            _data != null
                                ? '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}'
                                : 'Selecionar data',
                            style: TextStyle(
                                fontSize: 14,
                                color: _data != null
                                    ? const Color(0xFF1A1F36)
                                    : Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_data != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _data = null),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey[500]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Categoria
            Text('Categoria',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              value: _categoriaId,
              isExpanded: true,
              icon:
                  const Icon(Icons.keyboard_arrow_down_rounded, color: purple),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[200]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: purple, width: 1.5)),
              ),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('Todas as categorias')),
                ...widget.categorias.map((c) => DropdownMenuItem<int?>(
                      value: c.id,
                      child: Text(c.nome, overflow: TextOverflow.ellipsis),
                    )),
              ],
              onChanged: (v) => setState(() => _categoriaId = v),
            ),
            const SizedBox(height: 16),

            // Ordenação
            Text('Ordenação',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Row(
              children: [
                OrdemChip(
                  label: 'Descrição',
                  selected: _campo == 'descricao',
                  asc: _asc,
                  color: purple,
                  onTap: () => setState(() {
                    if (_campo == 'descricao') {
                      _asc = !_asc;
                    } else {
                      _campo = 'descricao';
                      _asc = true;
                    }
                  }),
                ),
                const SizedBox(width: 8),
                OrdemChip(
                  label: 'Data',
                  selected: _campo == 'data_pgto',
                  asc: _asc,
                  color: purple,
                  onTap: () => setState(() {
                    if (_campo == 'data_pgto') {
                      _asc = !_asc;
                    } else {
                      _campo = 'data_pgto';
                      _asc = false;
                    }
                  }),
                ),
              ],
            ),
            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!)),
                  ),
                  onPressed: () {
                    widget.onLimpar();
                    Navigator.of(context).pop();
                  },
                  child: Text('Limpar',
                      style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    widget.onAplicar(
                        _nomeCtrl.text, _data, _campo, _asc, _categoriaId);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Aplicar',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class OrdemChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool asc;
  final Color color;
  final VoidCallback onTap;

  const OrdemChip({
    required this.label,
    required this.selected,
    required this.asc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.grey[200]!,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.grey[500])),
            if (selected) ...[
              const SizedBox(width: 6),
              Icon(
                asc ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 14,
                color: color,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

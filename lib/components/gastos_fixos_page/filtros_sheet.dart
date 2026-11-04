import 'package:flutter/material.dart';
import 'package:orcamentos_app/shared/api_models.dart';


// ═══════════════════════════════════════════════════════════════════════════════
// Modal de filtros
// ═══════════════════════════════════════════════════════════════════════════════
class FiltrosSheet extends StatefulWidget {
  final String filtroNome;
  final String? filtroStatus;
  final DateTime? filtroData;
  final int? filtroCategoriaId;
  final List<CategoriaGastoResponseDto> categorias;
  final void Function(String nome, String? status, DateTime? data, int? categoriaId) onAplicar;
  final VoidCallback onLimpar;

  const FiltrosSheet({
    required this.filtroNome, required this.filtroStatus,
    required this.filtroData, required this.filtroCategoriaId,
    required this.categorias, required this.onAplicar, required this.onLimpar,
  });

  @override
  State<FiltrosSheet> createState() => FiltrosSheetState();
}

class FiltrosSheetState extends State<FiltrosSheet> {
  late TextEditingController _nomeCtrl;
  String? _status;
  DateTime? _data;
  int? _categoriaId;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.filtroNome);
    _status = widget.filtroStatus;
    _data = widget.filtroData;
    _categoriaId = widget.filtroCategoriaId;
  }

  @override
  void dispose() { _nomeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          Row(children: [
            Container(padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1A237E).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.filter_list_rounded, color: Color(0xFF1A237E), size: 18)),
            const SizedBox(width: 12),
            const Text('Filtros', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
          ]),
          const SizedBox(height: 20),
          TextField(controller: _nomeCtrl, style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nome…', hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF3949AB), size: 20),
                filled: true, fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5)),
              )),
          const SizedBox(height: 16),
          Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: ['PAGO', 'PENDENTE', 'VENCIDO'].map((s) {
            final selected = _status == s;
            final color = s == 'PAGO' ? const Color(0xFF43A047) : s == 'VENCIDO' ? const Color(0xFFE53935) : const Color(0xFFF4511E);
            return FilterChip(
              label: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : color)),
              selected: selected, onSelected: (v) => setState(() => _status = v ? s : null),
              backgroundColor: color.withOpacity(0.08), selectedColor: color, checkmarkColor: Colors.white,
              side: BorderSide(color: color.withOpacity(0.3)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            );
          }).toList()),
          const SizedBox(height: 16),
          Text('Categoria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 10),
          DropdownButtonFormField<int?>(
            value: _categoriaId,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF3949AB)),
            decoration: InputDecoration(
              filled: true, fillColor: Colors.grey[50],
              contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3949AB), width: 1.5)),
            ),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Todas as categorias')),
              ...widget.categorias.map((c) => DropdownMenuItem<int?>(
                    value: c.id,
                    child: Text(c.nome, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => setState(() => _categoriaId = v),
          ),
          const SizedBox(height: 16),
          Text('Data', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[500], letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context, initialDate: _data ?? DateTime.now(),
                  firstDate: DateTime(2000), lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: Color(0xFF1A237E))),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _data = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.grey[50], borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _data != null ? const Color(0xFF3949AB) : Colors.grey[200]!, width: _data != null ? 1.5 : 1),
                ),
                child: Row(children: [
                  Icon(Icons.calendar_today_rounded, size: 16, color: _data != null ? const Color(0xFF3949AB) : Colors.grey[400]),
                  const SizedBox(width: 10),
                  Text(
                    _data != null ? '${_data!.day.toString().padLeft(2, '0')}/${_data!.month.toString().padLeft(2, '0')}/${_data!.year}' : 'Selecionar data',
                    style: TextStyle(fontSize: 14, color: _data != null ? const Color(0xFF1A1F36) : Colors.grey[400]),
                  ),
                ]),
              ),
            )),
            if (_data != null) ...[
              const SizedBox(width: 8),
              GestureDetector(onTap: () => setState(() => _data = null),
                  child: Container(width: 40, height: 40,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.grey[500]))),
            ],
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: TextButton(
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[200]!))),
              onPressed: () { widget.onLimpar(); Navigator.of(context).pop(); },
              child: Text('Limpar', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w600)),
            )),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13), elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () { widget.onAplicar(_nomeCtrl.text, _status, _data, _categoriaId); Navigator.of(context).pop(); },
              child: const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

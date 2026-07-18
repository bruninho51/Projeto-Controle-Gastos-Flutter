import 'package:flutter/material.dart';

/// Bottom sheet de filtros da tela de orçamentos, no mesmo estilo visual dos
/// filtros de gastos fixos/variados. Oferece a busca por nome — filtro que a
/// API suporta ([ApiService.getOrcamentos] com `nome`) — e a ordenação da
/// lista (aplicada no cliente, pois a API de orçamentos não expõe ordenação).
class OrcamentosFiltrosSheet extends StatefulWidget {
  final String filtroNome;
  final String ordenacaoCampo;
  final bool ordenacaoAscendente;

  /// Quando `true`, inclui a opção de ordenar por data de encerramento.
  final bool incluirEncerramento;

  final void Function(String nome, String campo, bool ascendente) onAplicar;
  final VoidCallback onLimpar;

  const OrcamentosFiltrosSheet({
    super.key,
    required this.filtroNome,
    required this.ordenacaoCampo,
    required this.ordenacaoAscendente,
    required this.incluirEncerramento,
    required this.onAplicar,
    required this.onLimpar,
  });

  @override
  State<OrcamentosFiltrosSheet> createState() => _OrcamentosFiltrosSheetState();
}

class _OrcamentosFiltrosSheetState extends State<OrcamentosFiltrosSheet> {
  static const _dark = Color(0xFF1A237E);
  static const _light = Color(0xFF3949AB);

  late TextEditingController _nomeCtrl;
  late String _campo;
  late bool _ascendente;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.filtroNome);
    _campo = widget.ordenacaoCampo;
    _ascendente = widget.ordenacaoAscendente;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  List<({String id, String label})> get _campos => [
        (id: 'nome', label: 'Nome'),
        (id: 'valor_atual', label: 'Valor atual'),
        (id: 'data_criacao', label: 'Criação'),
        if (widget.incluirEncerramento)
          (id: 'data_encerramento', label: 'Encerramento'),
      ];

  @override
  Widget build(BuildContext context) {
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
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _dark.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.filter_list_rounded,
                      color: _dark, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Filtros',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1F36),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // ── Busca por nome (API) ──────────────────────────────────────
            TextField(
              controller: _nomeCtrl,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar por nome…',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                prefixIcon:
                    const Icon(Icons.search_rounded, color: _light, size: 20),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _light, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ── Ordenação (cliente) ───────────────────────────────────────
            Text(
              'Ordenar por',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _campos.map((c) {
                final selected = _campo == c.id;
                return ChoiceChip(
                  label: Text(
                    c.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _light,
                    ),
                  ),
                  selected: selected,
                  onSelected: (_) => setState(() => _campo = c.id),
                  backgroundColor: _light.withValues(alpha: 0.08),
                  selectedColor: _light,
                  showCheckmark: false,
                  side: BorderSide(color: _light.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // ── Direção ───────────────────────────────────────────────────
            Row(
              children: [
                _buildDirecao('Crescente', Icons.arrow_upward_rounded, true),
                const SizedBox(width: 8),
                _buildDirecao('Decrescente', Icons.arrow_downward_rounded, false),
              ],
            ),
            const SizedBox(height: 24),
            // ── Ações ─────────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey[200]!),
                      ),
                    ),
                    onPressed: () {
                      widget.onLimpar();
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'Limpar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _dark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      widget.onAplicar(_nomeCtrl.text, _campo, _ascendente);
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Aplicar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDirecao(String label, IconData icon, bool ascendente) {
    final selected = _ascendente == ascendente;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _ascendente = ascendente),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? _light.withValues(alpha: 0.1) : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _light : Colors.grey[200]!,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16, color: selected ? _light : Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? _light : Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

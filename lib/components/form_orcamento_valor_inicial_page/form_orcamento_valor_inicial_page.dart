import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'dart:convert';
import 'package:orcamentos_app/utils/http.dart';
import 'package:orcamentos_app/components/common/orcamentos_snackbar.dart';

class FormOrcamentoValorInicialPage extends StatefulWidget {
  final String apiToken;
  final double valorInicial;
  final int orcamentoId;

  const FormOrcamentoValorInicialPage({
    Key? key,
    required this.apiToken,
    required this.orcamentoId,
    required this.valorInicial,
  }) : super(key: key);

  @override
  _FormOrcamentoValorInicialPageState createState() =>
      _FormOrcamentoValorInicialPageState();
}

class _FormOrcamentoValorInicialPageState
    extends State<FormOrcamentoValorInicialPage> {
  final _valorController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late double _valorInicial;
  bool _isSubmitting = false;

  final _formatador = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _valorInicial = widget.valorInicial;
  }

  @override
  void dispose() {
    _valorController.dispose();
    super.dispose();
  }

  String _formatarValor(String value) {
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isNotEmpty) {
      final parsed = (double.tryParse(cleaned) ?? 0.0) / 100;
      return _formatador.format(parsed);
    }
    return '';
  }

  String _converterParaNumerico(String valorFormatado) {
    return valorFormatado
        .replaceAll('R\$', '')
        .trim()
        .replaceAll('.', '')
        .replaceAll(',', '.');
  }

  Future<void> _updateValorInicial(int orcamentoId, double valor) async {
    setState(() => _isSubmitting = true);
    try {
      final client = await MyHttpClient.create();
      final response = await client.patch(
        'orcamentos/$orcamentoId',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.apiToken}',
        },
        body: jsonEncode({'valor_inicial': valor.toString()}),
      );

      if (response.statusCode >= 200 && response.statusCode <= 299) {
        OrcamentosSnackBar.success(
          context: context,
          message: 'Valor inicial atualizado com sucesso!',
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Falha ao atualizar: ${response.statusCode}');
      }
    } catch (e) {
      OrcamentosSnackBar.error(context: context, message: 'Erro: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  // ─── Dialog estilizado ───────────────────────────────────────────────────────
  void _openValueDialog(_ActionDef action) {
    _valorController.clear();
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        action.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  action.description,
                  style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                ),
                const SizedBox(height: 20),

                // Input
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _valorController,
                    autofocus: true,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 15),
                    onChanged: (value) {
                      final formatted = _formatarValor(value);
                      _valorController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(offset: formatted.length),
                      );
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Insira um valor';
                      final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (double.tryParse(cleaned) == null) return 'Valor inválido';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'R\$ 0,00',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.attach_money_rounded,
                          color: action.color, size: 20),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                        borderSide: BorderSide(color: action.color, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        const BorderSide(color: Colors.redAccent, width: 1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Botões
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
                          Navigator.of(context).pop();
                          _valorController.clear();
                        },
                        child: Text('Cancelar',
                            style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: action.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting
                            ? null
                            : () {
                          if (_formKey.currentState!.validate()) {
                            final valor = double.tryParse(
                                _converterParaNumerico(
                                    _valorController.text)) ??
                                0.0;
                            double novoValor = _valorInicial;
                            switch (action.id) {
                              case 'set':
                                novoValor = valor;
                                break;
                              case 'add':
                                novoValor = _valorInicial + valor;
                                break;
                              case 'sub':
                                novoValor = _valorInicial - valor;
                                break;
                            }
                            setState(() => _valorInicial = novoValor);
                            Navigator.of(context).pop();
                            _updateValorInicial(widget.orcamentoId, novoValor);
                            _valorController.clear();
                          }
                        },
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                            : const Text('Confirmar',
                            style: TextStyle(fontWeight: FontWeight.w700)),
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
  }

  // ─── Card de ação ────────────────────────────────────────────────────────────
  Widget _buildActionCard(_ActionDef action) {
    return _HoverCard(
      onTap: () => _openValueDialog(action),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(action.icon, color: action.color, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              action.label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.description,
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }


  // ─── Tile compacto para mobile (altura fixa e uniforme) ─────────────────────
  Widget _buildActionTile(_ActionDef action) {
    return _HoverCard(
      onTap: () => _openValueDialog(action),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: action.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(action.icon, color: action.color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    action.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionDef(
        id: 'set',
        label: 'Novo valor',
        description: 'Substitui o valor atual',
        color: const Color(0xFF3949AB),
        icon: Icons.edit_rounded,
      ),
      _ActionDef(
        id: 'add',
        label: 'Adicionar',
        description: 'Soma ao valor atual',
        color: const Color(0xFF43A047),
        icon: Icons.add_rounded,
      ),
      _ActionDef(
        id: 'sub',
        label: 'Subtrair',
        description: 'Desconta do valor atual',
        color: const Color(0xFFE53935),
        icon: Icons.remove_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F9),
      appBar: AppBar(
        title: const Text(
          'Valor Inicial',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.indigo[700],
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.indigo[800]!.withOpacity(0.4)),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Card de valor atual ──────────────────────────────────────
                _buildValorCard(),
                const SizedBox(height: 28),

                // ── Label seção ──────────────────────────────────────────────
                Text(
                  'AÇÕES DISPONÍVEIS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Grid responsivo ──────────────────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  return isWide
                      ? SizedBox(
                    height: 160,
                    child: Row(
                      children: actions
                          .asMap()
                          .entries
                          .map((e) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: e.key == 0 ? 0 : 12),
                          child: _buildActionCard(e.value),
                        ),
                      ))
                          .toList(),
                    ),
                  )
                      : Column(
                    children: actions
                        .map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildActionTile(a),
                    ))
                        .toList(),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Card do valor atual ─────────────────────────────────────────────────────
  Widget _buildValorCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.account_balance_wallet_rounded,
                size: 28, color: Colors.indigo[700]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VALOR INICIAL ATUAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[400],
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formatarValorDynamic(_valorInicial),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1F36),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.indigo[700], strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Modelo de dados da ação
// ═══════════════════════════════════════════════════════════════════════════════
class _ActionDef {
  final String id;
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const _ActionDef({
    required this.id,
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// Card com hover state para web
// ═══════════════════════════════════════════════════════════════════════════════
class _HoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _HoverCard({required this.child, required this.onTap});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? Colors.indigo.withOpacity(0.12)
                  : Colors.black.withOpacity(0.05),
              blurRadius: _hovered ? 20 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.indigo.withOpacity(0.06),
            highlightColor: Colors.indigo.withOpacity(0.03),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
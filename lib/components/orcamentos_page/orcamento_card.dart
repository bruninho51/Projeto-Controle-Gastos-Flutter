import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/utils/http.dart';
import '../orcamento_detalhes_page/orcamento_detalhes_page.dart';

class OrcamentoCard extends StatefulWidget {
  final OrcamentoResponseDto orcamento;
  final String apiToken;
  final VoidCallback onRefresh;
  final int index;

  const OrcamentoCard({
    super.key,
    required this.orcamento,
    required this.apiToken,
    required this.onRefresh,
    this.index = 0,
  });

  @override
  State<OrcamentoCard> createState() => _OrcamentoCardState();
}

class _OrcamentoCardState extends State<OrcamentoCard>
    with SingleTickerProviderStateMixin {
  int _qtdGastosFixos = 0;
  int _qtdGastosVariados = 0;
  bool _isLoading = true;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300 + (widget.index * 60).clamp(0, 500)),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadGastosCount();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadGastosCount() async {
    try {
      final fixos = await _fetchCount('orcamentos/${widget.orcamento.id}/gastos-fixos');
      final variados = await _fetchCount('orcamentos/${widget.orcamento.id}/gastos-variados');
      if (mounted) {
        setState(() {
          _qtdGastosFixos = fixos;
          _qtdGastosVariados = variados;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<int> _fetchCount(String path) async {
    final client = await MyHttpClient.create();
    final response = await client.get(path, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${widget.apiToken}',
    });
    if (response.statusCode == 200) return jsonDecode(response.body).length as int;
    return 0;
  }

  Color _progressColor(double value) {
    if (value < 0.5) return const Color(0xFF43A047);
    if (value < 0.8) return const Color(0xFFF4511E);
    return const Color(0xFFE53935);
  }

  // ─── Card mobile ────────────────────────────────────────────────────────────
  Widget _buildMobileCard(BuildContext context) {
    final valorAtual = double.tryParse(widget.orcamento.valorAtual.toString()) ?? 0;
    final valorLivre = double.tryParse(widget.orcamento.valorLivre.toString()) ?? 0;
    final valorInicial = double.tryParse(widget.orcamento.valorInicial.toString()) ?? 0;
    final progresso = valorInicial > 0
        ? ((valorInicial - valorAtual) / valorInicial).clamp(0.0, 1.0)
        : 0.0;
    final progressColor = _progressColor(progresso);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          splashColor: Colors.indigo.withOpacity(0.06),
          highlightColor: Colors.indigo.withOpacity(0.03),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrcamentoDetalhesPage(orcamentoId: widget.orcamento.id),
              ),
            );
            widget.onRefresh();
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ────────────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.indigo[700], size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.orcamento.nome ?? 'Sem nome',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1F36),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Criado em ${formatarData(widget.orcamento.dataCriacao)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          formatarValorDouble(valorAtual),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: progressColor,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'de ${formatarValorDouble(valorInicial)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Barra de progresso ────────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso,
                    backgroundColor: progressColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progresso * 100).toStringAsFixed(1)}% utilizado',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF43A047).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${formatarValorDouble(valorLivre)} livre',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF43A047),
                        ),
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

  // ─── Card web ────────────────────────────────────────────────────────────────
  Widget _buildWebCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            // ── Info principal ──────────────────────────────────────────
            Expanded(child: _buildMobileCard(context)),

            // ── Divisor ─────────────────────────────────────────────────
            SizedBox(
              width: 24,
              height: 140,
              child: VerticalDivider(
                  thickness: 1, color: Colors.grey[100], indent: 12, endIndent: 12),
            ),

            // ── Gastos Fixos ─────────────────────────────────────────────
            SizedBox(
              width: 190,
              child: _isLoading
                  ? Center(
                  child: CircularProgressIndicator(
                      color: Colors.indigo[700], strokeWidth: 2))
                  : _ActionTile(
                title: 'Gastos Fixos',
                count: _qtdGastosFixos,
                color: const Color(0xFF3949AB),
                icon: Icons.receipt_long_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GastosFixosPage(
                        apiToken: widget.apiToken,
                        orcamentoId: widget.orcamento.id,
                      ),
                    ),
                  );
                  _loadGastosCount();
                },
              ),
            ),

            SizedBox(
              width: 24,
              height: 140,
              child: VerticalDivider(
                  thickness: 1, color: Colors.grey[100], indent: 12, endIndent: 12),
            ),

            // ── Gastos Variados ──────────────────────────────────────────
            SizedBox(
              width: 190,
              child: _isLoading
                  ? Center(
                  child: CircularProgressIndicator(
                      color: Colors.indigo[700], strokeWidth: 2))
                  : _ActionTile(
                title: 'Gastos Variados',
                count: _qtdGastosVariados,
                color: const Color(0xFF5E35B1),
                icon: Icons.trending_up_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GastosVariadosPage(
                        apiToken: widget.apiToken,
                        orcamentoId: widget.orcamento.id,
                      ),
                    ),
                  );
                  _loadGastosCount();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 1024;
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: (kIsWeb && !isSmallScreen) ? _buildWebCard(context) : _buildMobileCard(context),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Tile de ação (substitui OrcamentoAcaoCard) — alinhado ao design system indigo
// ═══════════════════════════════════════════════════════════════════════════════
class _ActionTile extends StatefulWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionTile({
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: _hovered ? widget.color.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: widget.color.withOpacity(0.08),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.count}',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1A1F36),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios_rounded,
                              size: 12, color: Colors.grey[400]),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
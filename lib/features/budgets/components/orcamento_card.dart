import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:orcamentos_app/components/gastos_fixos_page/gastos_fixos_page.dart';
import 'package:orcamentos_app/components/gastos_variados_page/gastos_variados_page.dart';
import 'package:orcamentos_app/shared/api_models.dart';
import 'package:orcamentos_app/shared/api_service.dart';
import 'package:orcamentos_app/utils/formatters.dart';
import 'package:orcamentos_app/features/shared/utils/card_entrance_animation.dart';
import '../pages/orcamento_detalhes_page.dart';
import '../utils/budget_progress.dart';
import 'orcamento_card_action_tile.dart';

class OrcamentoCard extends StatefulWidget {
  final OrcamentoResponseDto orcamento;
  final VoidCallback onRefresh;
  final int index;

  const OrcamentoCard({
    super.key,
    required this.orcamento,
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
    _animController = CardEntranceAnimation.createController(
      vsync: this,
      index: widget.index,
    );
    _fadeAnim = CardEntranceAnimation.fade(_animController);
    _slideAnim = CardEntranceAnimation.slide(_animController);
    _animController.forward();
    _loadGastosCount();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  ApiService get _api => Provider.of<ApiService>(context, listen: false);

  Future<void> _loadGastosCount() async {
    try {
      final fixos = await _api.getGastosFixos(orcamentoId: widget.orcamento.id);
      final variados = await _api.getGastosVariados(orcamentoId: widget.orcamento.id);
      if (mounted) {
        setState(() {
          _qtdGastosFixos = fixos.length;
          _qtdGastosVariados = variados.length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Card mobile ────────────────────────────────────────────────────────────
  Widget _buildMobileCard(BuildContext context) {
    final valorAtual = double.tryParse(widget.orcamento.valorAtual.toString()) ?? 0;
    final valorLivre = double.tryParse(widget.orcamento.valorLivre.toString()) ?? 0;
    final valorInicial = double.tryParse(widget.orcamento.valorInicial.toString()) ?? 0;
    final progresso = calculateBudgetProgress(
      valorInicial: valorInicial,
      valorAtual: valorAtual,
    );
    final progressColor = getBudgetProgressColor(progresso);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
          splashColor: Colors.indigo.withValues(alpha: 0.06),
          highlightColor: Colors.indigo.withValues(alpha: 0.03),
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
                    backgroundColor: progressColor.withValues(alpha: 0.1),
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
                        color: const Color(0xFF43A047).withValues(alpha: 0.08),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                  : OrcamentoCardActionTile(
                title: 'Gastos Fixos',
                count: _qtdGastosFixos,
                color: const Color(0xFF3949AB),
                icon: Icons.receipt_long_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GastosFixosPage(
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
                  : OrcamentoCardActionTile(
                title: 'Gastos Variados',
                count: _qtdGastosVariados,
                color: const Color(0xFF5E35B1),
                icon: Icons.trending_up_rounded,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GastosVariadosPage(
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
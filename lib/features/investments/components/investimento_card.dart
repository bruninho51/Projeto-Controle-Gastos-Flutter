import 'package:flutter/material.dart';

import 'package:orcamentos_app/features/investments/pages/investimento_detalhes_page.dart';
import 'package:orcamentos_app/features/shared/utils/card_entrance_animation.dart';
import 'package:orcamentos_app/utils/formatters.dart';

class InvestimentoCard extends StatefulWidget {
  final Map<String, dynamic> investimento;
  final String apiToken;
  final VoidCallback onRefresh;
  final int index;

  const InvestimentoCard({
    super.key,
    required this.investimento,
    required this.apiToken,
    required this.onRefresh,
    this.index = 0,
  });

  @override
  State<InvestimentoCard> createState() => _InvestimentoCardState();
}

class _InvestimentoCardState extends State<InvestimentoCard>
    with SingleTickerProviderStateMixin {
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
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investimento = widget.investimento;
    final valorAtual = double.tryParse(investimento['valor_atual']?.toString() ?? '0') ?? 0;
    final valorInicial = double.tryParse(investimento['valor_inicial']?.toString() ?? '0') ?? 0;
    final valorizacao = valorAtual - valorInicial;
    final progresso = valorInicial != 0 ? (valorAtual - valorInicial) / valorInicial : 0.0;
    final color = progresso >= 0 ? const Color(0xFF43A047) : const Color(0xFFE53935);

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Container(
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
                    builder: (_) => InvestimentoDetalhesPage(investimentoId: investimento['id']),
                  ),
                );
                widget.onRefresh();
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.indigo[50],
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(Icons.savings_rounded, color: Colors.indigo[700], size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investimento['nome'] ?? 'Sem nome',
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
                                'Criado em ${formatarData(DateTime.parse(investimento['data_criacao']))}',
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
                                color: color,
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
                    const SizedBox(height: 14),
                    // ── Rodapé: crescimento + valorização ──────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              progresso >= 0 ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                              color: color,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${(progresso * 100).toStringAsFixed(2)}%',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${formatarValorDouble(valorizacao)} valorizado',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: color,
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
        ),
      ),
    );
  }
}

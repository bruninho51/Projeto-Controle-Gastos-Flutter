import 'package:flutter/material.dart';

/// Tile de ação genérico (título + contador + ícone), usado nos cards de
/// orçamento para navegar até gastos fixos/variados. Não depende de nada
/// relacionado a orçamento — recebe apenas o necessário para se desenhar.
class OrcamentoCardActionTile extends StatefulWidget {
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const OrcamentoCardActionTile({
    super.key,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  State<OrcamentoCardActionTile> createState() => _OrcamentoCardActionTileState();
}

class _OrcamentoCardActionTileState extends State<OrcamentoCardActionTile> {
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

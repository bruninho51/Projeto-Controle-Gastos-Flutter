import 'package:flutter/material.dart';

import 'metric_card.dart';

class MetricCardAction {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final Color color;

  const MetricCardAction({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class MenuMetricCard extends StatefulWidget {
  final MetricCardDef def;
  final List<MetricCardAction> menuActions;
  final ValueChanged<String>? onActionSelected;

  MenuMetricCard({
    super.key,
    required this.def,
    this.menuActions = const [],
    this.onActionSelected,
  }) : assert(
         menuActions.isEmpty || onActionSelected != null,
         'onActionSelected é obrigatório quando menuActions não está vazio',
       );

  @override
  State<MenuMetricCard> createState() => _MenuMetricCardState();
}

class _MenuMetricCardState extends State<MenuMetricCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.def.color;
    final hasAction = widget.def.onTap != null;
    final hasMenu = widget.menuActions.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _hovered ? color.withValues(alpha: 0.18) : Colors.black.withValues(alpha: 0.05),
              blurRadius: _hovered ? 18 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: widget.def.onTap,
            borderRadius: BorderRadius.circular(16),
            splashColor: color.withValues(alpha: 0.08),
            highlightColor: color.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(widget.def.icon, color: color, size: 18),
                      ),
                      if (hasMenu)
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400], size: 18),
                          offset: const Offset(0, 30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: Colors.white,
                          elevation: 8,
                          onSelected: widget.onActionSelected,
                          itemBuilder: (context) => [
                            for (final action in widget.menuActions) _buildMenuItem(action),
                          ],
                        )
                      else if (hasAction)
                        Icon(Icons.arrow_forward_ios_rounded, size: 11, color: Colors.grey[400]),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.def.value,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1F36), letterSpacing: -0.3),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.def.title,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  PopupMenuItem<String> _buildMenuItem(MetricCardAction action) {
    return PopupMenuItem<String>(
      value: action.id,
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: action.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(action.icon, color: action.color, size: 16),
            ),
            const SizedBox(width: 12),
            Text(
              action.label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1A1F36)),
            ),
          ],
        ),
      ),
    );
  }
}

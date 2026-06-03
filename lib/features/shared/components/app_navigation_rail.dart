import 'package:flutter/material.dart';

import 'package:orcamentos_app/features/shared/navigation/app_navigation_items.dart';
import 'package:orcamentos_app/features/shared/navigation/navigation_item.dart';

class AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final bool extended;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExtended;
  final VoidCallback onLogout;

  const AppNavigationRail({
    super.key,
    required this.currentIndex,
    required this.extended,
    required this.onItemSelected,
    required this.onToggleExtended,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      width: extended ? 220 : 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A237E), Color(0xFF283593), Color(0xFF3949AB)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo
          Padding(
            padding: EdgeInsets.fromLTRB(
              extended ? 20 : 16,
              MediaQuery.of(context).padding.top + 20,
              extended ? 20 : 16,
              24,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset('assets/icon.png', fit: BoxFit.cover),
                  ),
                ),
                if (extended) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orçamentos',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          'App',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Itens de navegação
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Column(
                children: kNavigationItems.asMap().entries.map((e) {
                  return _RailItem(
                    item: e.value,
                    selected: e.key == currentIndex,
                    extended: extended,
                    onTap: () => onItemSelected(e.key),
                  );
                }).toList(),
              ),
            ),
          ),

          // Rodapé: colapsar + sair
          Padding(
            padding: EdgeInsets.fromLTRB(
              10,
              0,
              10,
              MediaQuery.of(context).padding.bottom + 20,
            ),
            child: Column(
              children: [
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                _RailFooterButton(
                  extended: extended,
                  icon: extended
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  label: 'Recolher',
                  onTap: onToggleExtended,
                ),
                const SizedBox(height: 6),
                _RailFooterButton(
                  extended: extended,
                  icon: Icons.logout_rounded,
                  label: 'Sair',
                  onTap: onLogout,
                  isDanger: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Item do Navigation Rail ─────────────────────────────────────────────────

class _RailItem extends StatefulWidget {
  final NavigationItem item;
  final bool selected;
  final bool extended;
  final VoidCallback onTap;

  const _RailItem({
    required this.item,
    required this.selected,
    required this.extended,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 14 : 0,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.white.withValues(alpha: 0.18)
                : _hovered
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                height: widget.selected ? 20 : 0,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(
                width: widget.selected ? 10 : (widget.extended ? 13 : 0),
              ),
              Icon(
                widget.selected ? widget.item.activeIcon : widget.item.icon,
                color: widget.selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.55),
                size: 22,
              ),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 14,
                      fontWeight: widget.selected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Botão de rodapé do rail ──────────────────────────────────────────────────

class _RailFooterButton extends StatefulWidget {
  final bool extended;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _RailFooterButton({
    required this.extended,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  State<_RailFooterButton> createState() => _RailFooterButtonState();
}

class _RailFooterButtonState extends State<_RailFooterButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isDanger ? Colors.red[300]! : Colors.white.withValues(alpha: 0.65);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: EdgeInsets.symmetric(
            horizontal: widget.extended ? 14 : 0,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: _hovered
                ? (widget.isDanger
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.08))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.extended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: color, size: 20),
              if (widget.extended) ...[
                const SizedBox(width: 12),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
